import 'package:flutter/material.dart';

final darkTheme = ThemeData(
    scaffoldBackgroundColor: const Color.fromARGB(240, 255, 207, 177),
    appBarTheme: const AppBarTheme(
        backgroundColor: Colors.brown
    ),
    dividerColor: Colors.black,
    textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: 20,
        )
    )
);