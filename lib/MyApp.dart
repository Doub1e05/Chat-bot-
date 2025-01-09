import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_project/router/router.dart';
import 'package:flutter_project/kubits/theme_cubit.dart';

class MyApp extends StatelessWidget {
  final bool isAuthenticated;
  const MyApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, theme) {
          return MaterialApp(
            title: 'Motovilov Ilya',
            theme: theme,
            routes: routes,
            initialRoute: isAuthenticated ? '/chat' : '/login', // Проверка авторизации
          );
        },
      ),
    );
  }
}
