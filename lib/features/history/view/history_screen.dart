import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../database_service.dart';
import '../../chat/view/chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Database _database;
  List<Map<String, dynamic>> chatHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabaseAndFetchHistory();
  }

  Future<void> _initializeDatabaseAndFetchHistory() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'chatbot.db');
      _database = await openDatabase(
        path,
        version: 1, // Используем актуальную схему
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE chats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              header TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              chat_id INTEGER,
              role TEXT,
              order_number INTEGER,
              text TEXT,
              FOREIGN KEY(chat_id) REFERENCES chats(id) ON DELETE CASCADE
            )
          ''');
        },
        );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error initializing database or fetching history: $e');
    }
  }

  Future<void> _fetchChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('loggedInUser');

      if (username == null) {
        print('No logged-in user found');
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Получаем ID текущего пользователя
      final user = await _database.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (user.isEmpty) {
        print('User not found in database');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final userId = user.first['id'];

      // Получаем чаты текущего пользователя
      final chats = await _database.query(
        'chats',

        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );

      List<Map<String, dynamic>> history = [];
      for (var chat in chats) {
        final chatId = chat['id'] as int;
        final header = chat['header'] as String;

        final messages = await _database.query(
          'messages',
          where: 'chat_id = ?',
          whereArgs: [chatId],
          orderBy: 'order_number ASC',

        );

        if (messages.isNotEmpty) {
          history.add({
            'id': chatId,
            'header': header,
            'messages': messages,
          });
        }
      }

      setState(() {
        chatHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching chat history: $e');
    }
  }

  void _openChat(int chatId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId),
      ),
    );
  }

  void _createNewChat() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUser');

    if (username == null) {
      print('No logged-in user found');
      return;
    }

    final user = await _database.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (user.isEmpty) {
      print('User not found in database');
      return;
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

    Navigator.push(
      context,
      MaterialPageRoute(

        builder: (context) => ChatScreen(chatId: chatId),

      ),
    );
  } catch (e) {
    print('Error creating new chat: $e');
  }
}


  @override

Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('История переписки'),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _createNewChat,
        ),
      ],
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : chatHistory.isEmpty
            ? const Center(
                child: Text('История пуста', style: TextStyle(fontSize: 18.0)),
              )
            : ListView.builder(
                itemCount: chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = chatHistory[index];
                  final header = chat['header'];
                  final chatId = chat['id'];

                  return ListTile(
                    title: Text(header),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(chatId: chatId),
                        ),
                      );
                    },
                  );
                },
              ),
  );
}


}
