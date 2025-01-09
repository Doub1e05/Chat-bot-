import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> getDatabase() async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'chatbot.db');
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            created_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE chats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            header TEXT,
            user_id INTEGER,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
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
      onUpgrade: (db, oldVersion, newVersion) async {
        final result = await db.rawQuery("PRAGMA table_info(chats);");
        if (!result.any((column) => column['name'] == 'user_id')) {
          await db.execute('ALTER TABLE chats ADD COLUMN user_id INTEGER;');
        }
      },
    );
    return _database!;
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
