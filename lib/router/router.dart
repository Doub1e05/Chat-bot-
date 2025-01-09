import '../features/chat/view/chat_screen.dart';
import '../features/history/view/history_screen.dart';
import '../login_screen.dart';
import '../settings_screen.dart';

final routes = {
  '/login': (context) => LoginScreen(),
  '/chat': (context) => ChatScreen(),
  '/history': (context) => HistoryScreen(),
  '/settings': (context) => const SettingsScreen(),
};