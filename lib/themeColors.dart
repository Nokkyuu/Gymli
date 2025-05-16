import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

const Color colorOrange = Color(0xE6FF6A00);
const Color colorWhite = Colors.white;
const Color colorBlack = Color.fromARGB(255, 18, 25, 36);

ThemeData buildAppTheme(Brightness mode) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colorOrange,
      brightness: mode,
      primary: colorOrange,
      primaryContainer: colorOrange,
      onPrimary: mode == Brightness.dark ? colorBlack : colorWhite,
      onPrimaryContainer: mode == Brightness.dark ? colorBlack : colorWhite,
      secondary: colorOrange,
      secondaryContainer: colorOrange,
      onSecondary: mode == Brightness.dark ? colorBlack : colorWhite,
      onSecondaryContainer: mode == Brightness.dark ? colorBlack : colorWhite,
      tertiary: colorOrange,
      tertiaryContainer: colorOrange,
      onTertiary: mode == Brightness.dark ? colorBlack : colorWhite,
      onTertiaryContainer: mode == Brightness.dark ? colorBlack : colorWhite,
      error: Colors.red,
      errorContainer: mode == Brightness.dark ? colorBlack : colorWhite,
      onError: mode == Brightness.dark ? colorBlack : colorWhite,
      onErrorContainer: mode == Brightness.dark ? colorBlack : colorWhite,
      surface: mode == Brightness.dark ? colorBlack : colorWhite,
      onSurface: mode == Brightness.dark ? colorWhite : colorBlack,
      surfaceContainerHighest:
          mode == Brightness.dark ? colorBlack : colorWhite,
      onSurfaceVariant: mode == Brightness.dark ? colorWhite : colorBlack,
      outline: mode == Brightness.dark ? colorWhite : colorBlack,
      shadow: mode == Brightness.dark ? colorWhite : colorBlack,
      inverseSurface: mode == Brightness.dark ? colorWhite : colorBlack,
      onInverseSurface: mode == Brightness.dark ? colorBlack : colorWhite,
      inversePrimary: mode == Brightness.dark ? colorBlack : colorWhite,
      surfaceContainer: mode == Brightness.dark ? colorBlack : colorWhite,
      surfaceContainerHigh: mode == Brightness.dark ? colorBlack : colorWhite,
      surfaceContainerLow: mode == Brightness.dark ? colorBlack : colorWhite,
      surfaceContainerLowest: mode == Brightness.dark ? colorBlack : colorWhite,
      surfaceTint: mode == Brightness.dark ? colorBlack : colorWhite,
      surfaceBright: mode == Brightness.dark ? colorBlack : colorWhite,
      surfaceDim: mode == Brightness.dark ? colorBlack : colorWhite,
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.oswald(
        fontSize: 30,
        fontStyle: FontStyle.italic,
      ),
      bodyMedium: GoogleFonts.merriweather(),
      displaySmall: GoogleFonts.pacifico(),
    ),
  );
}
