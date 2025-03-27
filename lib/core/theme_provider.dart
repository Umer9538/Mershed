import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mershed/ui/themes/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  ThemeData _themeData;

  ThemeProvider() : _themeData = AppTheme.lightTheme {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;
  ThemeData get themeData => _themeData;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = value;
    _themeData = value ? AppTheme.darkTheme : AppTheme.lightTheme;
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }
}