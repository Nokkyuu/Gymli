// theme_service.dart
// Riverpod-Theme-Controller + Provider für Gymli

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===============================
/// State
/// ===============================
@immutable
class ThemeState {
  final ThemeMode themeMode;     // light | dark | system
  final Color seedColor;         // Primärfarbe/Seed für ColorScheme

  const ThemeState({
    required this.themeMode,
    required this.seedColor,
  });

  bool get isDarkEffective {
    switch (themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        final platform = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return platform == Brightness.dark;
    }
  }

  Brightness get effectiveBrightness => isDarkEffective ? Brightness.dark : Brightness.light;

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
  }) =>
      ThemeState(
        themeMode: themeMode ?? this.themeMode,
        seedColor: seedColor ?? this.seedColor,
      );
}

/// ===============================
/// Keys & Defaults
/// ===============================
const _kPrefsThemeMode = 'themeMode'; // 'light' | 'dark' | 'system'
const _kPrefsSeedColor = 'seedColor'; // int value (ARGB)

const _kDefaultThemeMode = ThemeMode.system;
const _kDefaultSeedColor = Color(0xFFFF6A00); // Gymli Orange (volle Deckkraft!)

ThemeMode _parseThemeMode(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

String _encodeThemeMode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

/// ===============================
/// AsyncNotifier (lädt Persistenz beim Start)
/// ===============================
class ThemeController extends AsyncNotifier<ThemeState> {
  SharedPreferences? _prefs;

  @override
  Future<ThemeState> build() async {
    _prefs = await SharedPreferences.getInstance();
    final mode = _parseThemeMode(_prefs!.getString(_kPrefsThemeMode));
    final seed = Color(_prefs!.getInt(_kPrefsSeedColor) ?? _kDefaultSeedColor.value);
    return ThemeState(themeMode: mode, seedColor: seed);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.value ?? ThemeState(themeMode: _kDefaultThemeMode, seedColor: _kDefaultSeedColor);
    final next = current.copyWith(themeMode: mode);
    state = AsyncData(next);
    await _prefs?.setString(_kPrefsThemeMode, _encodeThemeMode(mode));
  }

  Future<void> toggleDark() async {
    final s = state.value ?? ThemeState(themeMode: _kDefaultThemeMode, seedColor: _kDefaultSeedColor);
    final nextMode = s.isDarkEffective ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setSeedColor(Color color) async {
    final current = state.value ?? ThemeState(themeMode: _kDefaultThemeMode, seedColor: _kDefaultSeedColor);
    final next = current.copyWith(seedColor: color.withOpacity(1.0)); // volle Deckkraft erzwingen
    state = AsyncData(next);
    await _prefs?.setInt(_kPrefsSeedColor, next.seedColor.value);
  }
}

/// ===============================
/// Provider API (bequem & robust)
/// ===============================

/// Haupt-Provider: steuert Laden + Mutationen
final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeState>(() => ThemeController());

/// Abgeleitete, „bequeme“ Provider mit Fallbacks,
/// damit dein UI nicht überall Async-Handling braucht.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final async = ref.watch(themeControllerProvider);
  return async.value?.themeMode ?? _kDefaultThemeMode;
});

final seedColorProvider = Provider<Color>((ref) {
  final async = ref.watch(themeControllerProvider);
  return async.value?.seedColor ?? _kDefaultSeedColor;
});

final brightnessProvider = Provider<Brightness>((ref) {
  final async = ref.watch(themeControllerProvider);
  final effective = async.value?.effectiveBrightness ??
      // Fallback: orientiere dich an der Plattform, wenn noch lädt
      (SchedulerBinding.instance.platformDispatcher.platformBrightness);
  return effective;
});

final isDarkModeProvider = Provider<bool>((ref) {
  final b = ref.watch(brightnessProvider);
  return b == Brightness.dark;
});

/// Falls du deine ThemeData zentral aus `themes.dart` bauen willst,
/// kannst du dort `buildAppTheme(Brightness, Color)` definieren
/// und hier nur konsumieren.
/// Beispiel: 
///   theme:     ref.watch(lightThemeDataProvider),
///   darkTheme: ref.watch(darkThemeDataProvider),
typedef ThemeBuilder = ThemeData Function(Brightness, Color);

ThemeData _defaultBuildTheme(Brightness b, Color seed) {
  // Minimaler Fallback, falls du (noch) keine eigene Theme-Fabrik nutzt.
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: b),
  );
}

// Ersetze `_defaultBuildTheme` durch dein `buildAppTheme`,
// indem du hier einfach die Funktion referenzierst.
// Beispiel:
// import '../utils/themes/themes.dart' show buildAppTheme;
// const ThemeBuilder _builder = buildAppTheme;
const ThemeBuilder _builder = _defaultBuildTheme;

final lightThemeDataProvider = Provider<ThemeData>((ref) {
  final seed = ref.watch(seedColorProvider);
  return _builder(Brightness.light, seed);
});

final darkThemeDataProvider = Provider<ThemeData>((ref) {
  final seed = ref.watch(seedColorProvider);
  return _builder(Brightness.dark, seed);
});

/// Notifier-Zugriff bequem kapseln (z. B. für Buttons/Callbacks)
extension ThemeActions on WidgetRef {
  ThemeController get themeCtrl => read(themeControllerProvider.notifier);
}