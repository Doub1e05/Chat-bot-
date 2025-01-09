import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './auth_service.dart';
import './MyApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final authService = AuthService();
  await authService.initializeDatabase();
  final isAuthenticated = await authService.checkAuthentication();
  runApp(MyApp(isAuthenticated: isAuthenticated));
}
