/// Main entry point for the Gymli app
/// glues the app together and initializes services
/// handles critical initialization errors
/// and sets up the main app widgets
library;

import 'package:Gymli/utils/workout_data_cache.dart';
import 'package:Gymli/widgets/app_router.dart';
import 'package:Gymli/utils/services/authentication_service.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import 'package:Gymli/utils/workout_session_state.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/api/api_export.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'utils/services/app_initializer.dart';
import 'utils/services/theme_service.dart';
import 'utils/themes/themes.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  GetIt.I.registerSingleton<TempService>(TempService());
  GetIt.I.registerSingleton<ExerciseService>(ExerciseService());
  GetIt.I.registerSingleton<WorkoutService>(WorkoutService());
  GetIt.I.registerSingleton<WorkoutUnitService>(WorkoutUnitService());
  GetIt.I.registerSingleton<TrainingSetService>(TrainingSetService());
  GetIt.I.registerSingleton<FoodService>(FoodService());
  GetIt.I.registerSingleton<ActivityService>(ActivityService());
  GetIt.I.registerSingleton<CalendarService>(CalendarService());
  GetIt.I.registerSingleton<AuthenticationService>(AuthenticationService());

  // managers are either ttl-singletons with state, or riverpods
  // GetIt.I.registerSingleton<AuthManager>(AuthManager());
  GetIt.I.registerSingleton<WorkoutSessionManager>(WorkoutSessionManager());
  GetIt.I.registerSingleton<WorkoutDataCache>(WorkoutDataCache());

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

  runApp(const ProviderScope(child: MainApp()));
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

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  // late ThemeService _themeService;
  late final GoRouter _router;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter();
    _initializeTheme();
    FlutterNativeSplash.remove();
  }

  Future<void> _initializeTheme() async {
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
    final mode = ref.watch(themeModeProvider);
    final seed = ref.watch(seedColorProvider);
    final themeData = buildAppTheme(
      mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      seed,
    );
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
      routerConfig: _router,
    );
  }
}
