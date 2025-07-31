///handles the logic to manage the app's theme, including light and dark modes.
///It uses the `SharedPreferences` package to persist the user's theme choice.
///The service notifies listeners when the theme changes, allowing the UI to update accordingly.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/themes.dart';

class ThemeService extends ChangeNotifier {
  Brightness _mode = Brightness.light;
  Color _primaryColor = ThemeColors.themeOrange;

  Brightness get mode => _mode;
  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _mode == Brightness.dark;

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _mode = isDark ? Brightness.dark : Brightness.light;
    notifyListeners();
  }

  Future<void> setMode(Brightness newMode) async {
    _mode = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _mode == Brightness.dark);
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }
}
