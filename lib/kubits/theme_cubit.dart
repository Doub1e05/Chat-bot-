import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(_lightTheme);

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.teal,
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orangeAccent),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.teal[50],
    appBarTheme: AppBarTheme(
      color: Colors.teal,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.teal,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.teal,
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orangeAccent, brightness: Brightness.dark),
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[800],
    appBarTheme: AppBarTheme(
      color: Colors.teal[700],
      iconTheme: IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.teal,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );

  void toggleTheme() {
    emit(state.brightness == Brightness.dark ? _lightTheme : _darkTheme);
  }
}