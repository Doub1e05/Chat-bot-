import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../history/view/history_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../kubits/theme_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../database_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key, this.chatId}) : super(key: key);
  final int? chatId;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = [];
  late Database _database;
  bool _isLoading = false;
  bool _isDatabaseOpen = false; // Проверка состояния базы данных
  int? _currentChatId;
  int _messageOrder = 0;

  @override
  void initState() {
    super.initState();
    _initializeDatabaseAndChat();
  }

  Future<void> _initializeDatabaseAndChat() async {
    try {
      _database = await _databaseService.getDatabase();

    if (widget.chatId == null) {
      _currentChatId = await _createNewChat();
    } else {
      _currentChatId = widget.chatId!;
      await _loadChatHistory();
    }
  } catch (e) {
    print('Error initializing chat: $e');
  }
}

  Future<int> _createNewChat() async {
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('loggedInUser');

  if (username == null) {
    print('No logged-in user found');
    return -1;
  }

  final user = await _database.query(
    'users',
    where: 'username = ?',
    whereArgs: [username],
  );

  if (user.isEmpty) {
    print('User not found in database');
    return -1;
  }

  final userId = user.first['id'];

  final chatId = await _database.insert(
    'chats',
    {
      'header': 'Chat ${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  return chatId;
}


  Future<void> _loadChatHistory() async {
    try {
      final result = await _database.query(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [_currentChatId],
        orderBy: 'order_number ASC',
      );

      if (!mounted) return;

      setState(() {
        _messages = result
            .map((row) => {'role': row['role'] as String, 'text': row['text'] as String})
            .toList();
        _messageOrder = _messages.length;
      });
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    if (!_isDatabaseOpen) {
      print('Database is not open. Cannot send message.');
      return;
    }

    setState(() {
      _isLoading = true;
      _messages.add({'role': 'user', 'text': message});
      _messageOrder++;
    });

    try {
      final apiKey = dotenv.env['API_KEY'];
      final indFolder = dotenv.env['IND_FOLDER'];

      final response = await http.post(
        Uri.parse('https://llm.api.cloud.yandex.net/foundationModels/v1/completion'),
        headers: {
          'Authorization': 'Api-Key $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'modelUri': 'gpt://$indFolder/yandexgpt/latest',
          'completionOptions': {
            'stream': false,
            'temperature': 0.7,
            'maxTokens': 1000,
          },
          'messages': _messages.map((m) => {'role': m['role'], 'text': m['text']}).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);
        final botResponse = responseData['result']['alternatives'][0]['message']['text'].trim();

        setState(() {
          _messages.add({'role': 'assistant', 'text': botResponse});
          _messageOrder++;
        });

        await _saveMessage(message, botResponse);
      } else {
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadChat() async {
    if (_currentChatId != null) {
      await _loadChatHistory();
    }
  }
 Future<void> _saveMessage(String userMessage, String botResponse) async {
    try {
      if (_currentChatId == null) {
        // Если идентификатор чата отсутствует, создаём новый
        _currentChatId = await _createNewChat();
      }

      // Сохраняем оба сообщения в одной транзакции
      final batch = _database.batch();
      batch.insert('messages', {
        'chat_id': _currentChatId,
        'role': 'user',
        'order_number': _messageOrder - 2,
        'text': userMessage,
      });
      batch.insert('messages', {
        'chat_id': _currentChatId,
        'role': 'assistant',
        'order_number': _messageOrder - 1,
        'text': botResponse,
      });
      await batch.commit(noResult: true);

      print('Messages saved to chatId $_currentChatId');
    } catch (e) {
      print('Error saving messages: $e');
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      await _reloadChat(); // Перезагружаем переписку
      return true; // Позволяем вернуть назад
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('ChatBot'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: widget.chatId == null ? null : Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              ).then((_) => _reloadChat()); // Перезагрузка после возврата
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    color: isUser ? Theme.of(context).cardColor : Colors.pink[100],
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(message['text']!),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Введите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      _sendMessage(_controller.text.trim());
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

}
