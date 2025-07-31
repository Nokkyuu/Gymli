/// Main entry point for the Gymli app
/// glues the app together and initializes services
/// handles critical initialization errors
/// and sets up the main app widgets
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/services/app_initializer.dart';
import 'widgets/main_app_widget.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); //required for async initialization, ensures that the Flutter engine is ready

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

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('en', 'GB'),
        Locale('de', 'DE'),
      ],
      title: 'Gymli Gainson',
      home: MainAppWidget(),
    );
  }
}
