/// Main entry point for the Gymli app
/// glues the app together and initializes services
/// handles critical initialization errors
/// and sets up the main app widgets
library;

import 'package:Gymli/config/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'utils/services/app_initializer.dart';
import 'utils/services/theme_service.dart';
import 'utils/themes/themes.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding
      .ensureInitialized(); //required for async initialization, ensures that the Flutter engine is ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  final initResult = await AppInitializer.initialize();

  if (!initResult.success) {
    print('Critical initialization failure: ${initResult.error}');
    if (!kDebugMode) {
      // In production, show error screen or exit
      runApp(_buildErrorApp(initResult.error!));
      return;
    }
  }

  if (initResult.partial) {
    print('Partial initialization failure: ${initResult.error}');
    // Continue with limited functionality
  }

  runApp(const MainApp());
}

/// Builds a widget that is shown when initialization fails
/// argument [error] contains the error message
Widget _buildErrorApp(String error) {
  FlutterNativeSplash.remove();

  return MaterialApp(
    title: 'Gymli - Error',
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('App initialization failed'),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late ThemeService _themeService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
    FlutterNativeSplash.remove();
  }

  Future<void> _initializeTheme() async {
    _themeService = ThemeService();
    await _themeService.loadThemePreference();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          final ThemeData themeData =
              buildAppTheme(themeService.mode, themeService.primaryColor);

          return MaterialApp.router(
            theme: themeData,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('en', 'GB'),
              Locale('de', 'DE'),
            ],
            title: 'Gymli Gainson',
            routerConfig: AppRouter.createRouter(),
          );
        },
      ),
    );
  }
}
