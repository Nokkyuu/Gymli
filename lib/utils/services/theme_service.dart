///handles the logic to manage the app's theme, including light and dark modes.
///It uses the `SharedPreferences` package to persist the user's theme choice.
///The service notifies listeners when the theme changes, allowing the UI to update accordingly.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/themes.dart';

class ThemeService extends ChangeNotifier {
  /// Handles the app's theme management, including light and dark modes.
  /// It uses `SharedPreferences` to persist the user's theme choice.
  /// Notifies listeners when the theme changes, allowing the UI to update accordingly.
  /// getters:
  /// - `mode`: The current brightness mode (light or dark).
  /// - `primaryColor`: The primary color used in the theme.
  /// - `isDarkMode`: A boolean indicating if the current mode is dark.
  /// methods:
  /// - `loadThemePreference`: Loads the theme preference from shared preferences.
  /// - `setMode`: Sets the theme mode to either light or dark.
  /// - `setPrimaryColor`: Sets the primary color for the theme.
  Brightness _mode = Brightness.light;
  Color _primaryColor = ThemeColors.themeOrange;

  Brightness get mode => _mode;
  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _mode == Brightness.dark;

  Future<void> loadThemePreference() async {
    /// Loads the theme preference from shared preferences.
    /// If no preference is found, defaults to light mode.
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _mode = isDark ? Brightness.dark : Brightness.light;
    notifyListeners();
  }

  Future<void> setMode(Brightness newMode) async {
    /// Sets the theme mode to either light or dark.
    _mode = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _mode == Brightness.dark);
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    /// Sets the primary color for the theme.
    _primaryColor = color;
    notifyListeners();
  }
}
