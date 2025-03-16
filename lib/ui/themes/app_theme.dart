import 'package:flutter/material.dart';

class AppTheme {
  // Define color palette
  static const Color primaryColor = Color(0xFF006C45); // Saudi green
  static const Color secondaryColor = Color(0xFFFFFFFF); // White
  static const Color accentColor = Color(0xFFF4A261); // Warm orange for highlights
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light gray background
  static const Color textColor = Color(0xFF333333); // Dark gray for text
  static const Color errorColor = Color(0xFFD32F2F); // Red for errors

  // Define the light theme
  static ThemeData get lightTheme {
    return ThemeData(
      // Core colors
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: secondaryColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: secondaryColor, // Text/icon color on primary
        onSecondary: textColor, // Text/icon color on secondary
        onSurface: textColor, // Text/icon color on surface
        onBackground: textColor, // Text/icon color on background
        onError: secondaryColor, // Text/icon color on error
      ),

      // AppBar styling
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor, // Text/icons in AppBar
        elevation: 2.0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: secondaryColor,
        ),
      ),

      // Text styling
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
        bodyLarge: TextStyle(fontSize: 16, color: textColor),
        bodyMedium: TextStyle(fontSize: 14, color: textColor),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      ),

      // Button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Button background
          foregroundColor: secondaryColor, // Text/icon color
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // TextField styling
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: textColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: textColor),
        hintStyle: const TextStyle(color: Colors.grey),
      ),

      // Card styling
      cardTheme: CardTheme(
        color: secondaryColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Font family (optional, uncomment if you add a custom font)
      // fontFamily: 'Roboto',

      // Visual density for better spacing
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // Define a dark theme (optional, for future use)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212), // Dark background
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        error: errorColor,
        onPrimary: secondaryColor,
        onSecondary: textColor,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        elevation: 2.0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}