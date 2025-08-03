/// Theme File for Gymli, defines colors and icons used thorugh the app
///
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// All colors used in the app, change here
const Color _colorOrange = Color(0xE6FF6A00); // Main brand orange color
const Color _colorWhite = Colors.white; // Standard white
const Color _colorDark = Color.fromRGBO(18, 25, 36, 1); // Dark theme background
const Color _colorBlue = Color(0xD90095FF);
const Color _colorCut = Color.fromARGB(16, 255, 86, 34);
const Color _colorBulk = Color.fromARGB(26, 76, 175, 79);
const Color _colorOther = Color.fromARGB(72, 255, 153, 0);
const Color _colorNormal = Color(
    0xE6FF6A00); //duplicate of standard theme for possible later implementation of themes
const Color _colorDeload = Color(0xD90095FF);
const Color _colorPower = Color.fromARGB(255, 166, 0, 255);

const setIcons = [
  FontAwesomeIcons.fire, // Icon for Warmup Sets (settype 1)
  FontAwesomeIcons.handFist, // Icon for Worksets (settype 2)
  FontAwesomeIcons.arrowDown // Icons for Dropsets, deprecated (settype 3)
];

class ThemeColors {
  final Map<String, Color> periodColors = {
    'cut': _colorCut,
    'bulk': _colorBulk,
    'other': _colorOther
  };

  final Map<String, Color> phaseColor = {
    'normal': _colorOrange,
    'deload': _colorBlue,
    'power': _colorPower,
  };

  static final Color themeOrange = _colorOrange; // Main brand orange color
  static final Color themeWhite = _colorWhite;
  static final Color themeBlack = _colorDark;
  static final Color themeBlue = _colorBlue;
}

ThemeData buildAppTheme(Brightness mode, Color primaryColor) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: mode,
      primary: primaryColor,
      primaryContainer: primaryColor,
      onPrimary: mode == Brightness.dark ? _colorDark : _colorWhite,
      onPrimaryContainer: mode == Brightness.dark ? _colorDark : _colorWhite,
      secondary: primaryColor,
      secondaryContainer: primaryColor,
      onSecondary: mode == Brightness.dark ? _colorDark : _colorWhite,
      onSecondaryContainer: mode == Brightness.dark ? _colorDark : _colorWhite,
      tertiary: primaryColor,
      tertiaryContainer: primaryColor,
      onTertiary: mode == Brightness.dark ? _colorDark : _colorWhite,
      onTertiaryContainer: mode == Brightness.dark ? _colorDark : _colorWhite,
      error: Colors.red,
      errorContainer: mode == Brightness.dark ? _colorDark : _colorWhite,
      onError: mode == Brightness.dark ? _colorDark : _colorWhite,
      onErrorContainer: mode == Brightness.dark ? _colorDark : _colorWhite,
      surface: mode == Brightness.dark ? _colorDark : _colorWhite,
      onSurface: mode == Brightness.dark ? _colorWhite : _colorDark,
      surfaceContainerHighest:
          mode == Brightness.dark ? _colorDark : _colorWhite,
      onSurfaceVariant: mode == Brightness.dark ? _colorWhite : _colorDark,
      outline: mode == Brightness.dark ? _colorWhite : _colorDark,
      shadow: mode == Brightness.dark ? _colorWhite : _colorDark,
      inverseSurface: mode == Brightness.dark ? _colorWhite : _colorDark,
      onInverseSurface: mode == Brightness.dark ? _colorDark : _colorWhite,
      inversePrimary: mode == Brightness.dark ? _colorDark : _colorWhite,
      surfaceContainer: mode == Brightness.dark ? _colorDark : _colorWhite,
      surfaceContainerHigh: mode == Brightness.dark ? _colorDark : _colorWhite,
      surfaceContainerLow: mode == Brightness.dark ? _colorDark : _colorWhite,
      surfaceContainerLowest:
          mode == Brightness.dark ? _colorDark : _colorWhite,
      surfaceTint: mode == Brightness.dark ? _colorDark : _colorWhite,
      surfaceBright: mode == Brightness.dark ? _colorDark : _colorWhite,
      surfaceDim: mode == Brightness.dark ? _colorDark : _colorWhite,
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.oswald(
        fontSize: 45,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: GoogleFonts.pacifico(),
      headlineLarge: GoogleFonts.oswald(
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.oswald(
        fontSize: 28,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: GoogleFonts.oswald(
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: GoogleFonts.oswald(
        fontSize: 30,
        fontStyle: FontStyle.italic,
      ),
      titleMedium: GoogleFonts.oswald(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.oswald(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.merriweather(
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.merriweather(),
      bodySmall: GoogleFonts.merriweather(
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.merriweather(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.merriweather(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.merriweather(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
