import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
class AuthService {
  Database? _database;

  Future<void> initializeDatabase() async {
    // Убедимся, что WidgetsBinding инициализирована
    WidgetsFlutterBinding.ensureInitialized();

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'chatbot.db');
    _database = await openDatabase(path, version: 1);
  }

  Future<bool> register(String username, String password) async {
    try {
      await _ensureDatabaseInitialized();

      // Проверяем, существует ли пользователь
      final existingUser = await _database!.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (existingUser.isNotEmpty) {
        print('Username already exists');
        return false; // Имя пользователя уже занято
      }

      // Хэшируем пароль и добавляем пользователя
      final hashedPassword = _hashPassword(password);
      await _database!.insert(
        'users',
        {
          'username': username,
          'password': hashedPassword,
          'created_at': DateTime.now().millisecondsSinceEpoch
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      await _saveUserToCache(username); // Сохраняем пользователя в кэше
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }


  Future<bool> login(String username, String password) async {
    try {
      await _ensureDatabaseInitialized();
      final hashedPassword = _hashPassword(password);
      final result = await _database!.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, hashedPassword],
      );
      if (result.isNotEmpty) {
        await _saveUserToCache(username); // Сохраняем пользователя в кэше
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> checkAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('loggedInUser');
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUser'); // Удаляем данные пользователя
  }

  Future<void> _saveUserToCache(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUser', username);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> _ensureDatabaseInitialized() async {
    if (_database == null) {
      await initializeDatabase();
    }
  }
}
