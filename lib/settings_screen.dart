import 'package:flutter/material.dart';
import 'auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await authService.logout(); // Выход из аккаунта
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          },
          child: const Text('Выйти из аккаунта'),
        ),
      ),
    );
  }
}
