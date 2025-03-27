import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFFB94A2F),
    scaffoldBackgroundColor: Color(0xFFF7EFE4),
    colorScheme: ColorScheme.light(
      primary: Color(0xFFB94A2F),
      secondary: Color(0xFF3C896D),
      surface: Color(0xFFF7EFE4),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.brown.shade800),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFB94A2F)),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFFB94A2F),
    scaffoldBackgroundColor: Colors.grey.shade900,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFFB94A2F),
      secondary: Color(0xFF3C896D),
      surface: Colors.grey.shade800,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      color: Colors.grey.shade800,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFB94A2F)),
    ),
  );
}