/// App Router Configuration for go_router
/// Defines all routes and navigation structure for the Gymli app
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'package:get_it/get_it.dart';

// Import screens
import 'landing_choice_screen.dart';
import '../screens/exercise_setup_screen.dart';
import '../screens/workout_setup_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/food_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/exercise_screen.dart';
import '../screens/exercise_history_screen.dart';
import '../screens/landing_screen.dart';
import 'navigation_drawer.dart';

// Import services

//import '../utils/services/auth0_service.dart';
import '../utils/services/theme_service.dart';
import '../utils/info_dialogues.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Gymli/utils/services/authentication_service.dart';

class AppRouter {
  static const String landing = '/';
  static const String main = '/main';
  static const String exerciseSetup = '/exercise-setup';
  static const String workoutSetup = '/workout-setup';
  static const String activity = '/activity';
  static const String food = '/food';
  static const String statistics = '/statistics';
  static const String calendar = '/calendar';
  static const String settings = '/settings';
  static const String exercise = '/exercise';
  static const String exerciseHistory = '/exercise-history';

  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: landing,
      debugLogDiagnostics: true,
      routes: [
        // Landing/Login Route
        GoRoute(
          path: landing,
          name: 'landing',
          builder: (context, state) => const LandingChoiceScreen(),
        ),

        // Main App Shell Route
        ShellRoute(
          builder: (context, state, child) => MainAppShell(child: child),
          routes: [
            // Main dashboard route
            GoRoute(
              path: main,
              name: 'main',
              builder: (context, state) => const MainAppContent(),
            ),

            // Activity Tracker Route
            GoRoute(
              path: activity,
              name: 'activity',
              builder: (context, state) => const ActivityScreen(),
            ),

            // Food Tracker Route
            GoRoute(
              path: food,
              name: 'food',
              builder: (context, state) => const FoodScreen(),
            ),

            // Statistics Route
            GoRoute(
              path: statistics,
              name: 'statistics',
              builder: (context, state) => const StatisticsScreen(),
            ),

            // Calendar Route
            GoRoute(
              path: calendar,
              name: 'calendar',
              builder: (context, state) => const CalendarScreen(),
            ),

            // Settings Route
            GoRoute(
              path: settings,
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),

        // Exercise Setup Route (standalone - outside shell to have its own AppBar)
        GoRoute(
          path: exerciseSetup,
          name: 'exercise-setup',
          builder: (context, state) {
            final exerciseId =
                int.tryParse(state.uri.queryParameters['id'] ?? '0') ?? 0;
            return ExerciseSetupScreen(exerciseId);
          },
        ),

        // Workout Setup Route (standalone - outside shell to have its own AppBar)
        GoRoute(
          path: workoutSetup,
          name: 'workout-setup',
          builder: (context, state) {
            final workoutType = state.uri.queryParameters['type'] ?? '';
            return WorkoutSetupScreen(workoutType);
          },
        ),

        // Exercise Route (standalone - outside shell to avoid double AppBar)
        GoRoute(
          path: exercise,
          name: 'exercise',
          builder: (context, state) {
            final exerciseId =
                int.tryParse(state.uri.queryParameters['id'] ?? '0') ?? 0;
            final exerciseName = state.uri.queryParameters['name'] ?? '';
            final workoutDescription =
                state.uri.queryParameters['description'] ?? '';

            return Consumer(
              builder: (context, ref, _) {
                return ExerciseScreen(
                  exerciseId,
                  exerciseName,
                  workoutDescription,
                  onPhaseColorChanged: (c) => ref
                      .read(themeControllerProvider.notifier)
                      .setSeedColor(c),
                );
              },
            );
          },
        ),

        // Exercise History Route (standalone - outside shell to avoid double AppBar)
        GoRoute(
          path: exerciseHistory,
          name: 'exercise-history',
          builder: (context, state) {
            final exerciseId =
                int.tryParse(state.uri.queryParameters['id'] ?? '0') ?? 0;
            final exerciseName = state.uri.queryParameters['name'] ?? '';
            return ExerciseListScreen(exerciseId, exerciseName);
          },
        ),
      ],

      // Redirect logic for authentication
      redirect: (context, state) {
        // Check if we're on the landing page
        final isOnLanding = state.matchedLocation == landing;
        final auth = GetIt.I<AuthenticationService>();
        final isLoggedIn = auth.isLoggedIn;

        if (isLoggedIn && isOnLanding) return main;
        if (!isLoggedIn && !isOnLanding) return landing;

        // No redirect needed
        return null;
      },

      // Error handling
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page not found: ${state.matchedLocation}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(landing),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main App Shell that provides the common structure (AppBar, Drawer)
/// for all authenticated routes
class MainAppShell extends StatelessWidget {
  final Widget child;

  const MainAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Import the MainAppWidget here to wrap the child
    return MainAppWrapper(child: child);
  }
}

/// Wrapper that provides the MainAppWidget functionality but takes a child
class MainAppWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const MainAppWrapper({super.key, required this.child});

  @override
  ConsumerState<MainAppWrapper> createState() => _MainAppWrapperState();
}

class _MainAppWrapperState extends ConsumerState<MainAppWrapper> {
  String? _drawerImage;
  late AuthenticationService _authService;
  bool _isInitialized = false;

  //drawer images to circle through, without file extensions because they will be added dynamically and switch for dark mode
  final List<String> drawerImages = [
    'images/drawerlogo/gymli-biceps',
    'images/drawerlogo/gymli-curl1',
    'images/drawerlogo/gymli-curl2',
    'images/drawerlogo/gymli-squat',
    'images/drawerlogo/gymli-face',
    'images/drawerlogo/gymli-row',
    'images/drawerlogo/gymli-row2',
    'images/drawerlogo/gymli-pullup',
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _authService = GetIt.I<AuthenticationService>();

    await _authService.initialize();

    // Listen to auth changes for reloading user data
    _authService.addListener(_onAuthChanged);

    // Set initialization flag and trigger rebuild
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onAuthChanged() {
    if (_authService.credentials != null) {
      _reloadUserData();
    }
  }

  Future<void> _reloadUserData() async {
    //_getExerciseList();
    setState(() {}); // Trigger rebuild
    await Future.delayed(const Duration(milliseconds: 100));
    //_authService.notifyAuthStateChanged();
  }

  // void _getExerciseList() async {
  //   // ... existing exercise loading logic
  // }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final isDarkMode = ref.watch(isDarkModeProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: _buildAppBar(context, isDarkMode),
      body: widget.child,
      drawer: AppDrawer(
        credentials: _authService.credentials,
        auth0: _authService.auth0,
        drawerImage: _drawerImage,
        drawerImages: drawerImages,
        isDarkMode: isDarkMode,
        mode: mode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light, // <!!!!!
        onModeChanged: (b) =>
            ref.read(themeControllerProvider.notifier).setThemeMode(
                  b == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
                ),
        //onCredentialsChanged: _authService.updateCredentials,
        // onReloadUserData: _reloadUserData,
        // getExerciseList: _getExerciseList,
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          setState(() {
            _drawerImage = drawerImages[Random().nextInt(drawerImages.length)];
          });
        }
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDarkMode) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final title = _getTitleForRoute(currentRoute);

    return AppBar(
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 50.0),
            child: Image.asset(
              isDarkMode
                  ? 'images/Icon-App_3_Darkmode.png'
                  : 'images/Icon-App_3.png',
              fit: BoxFit.contain,
              height: 50,
            ),
          ),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
      actions: _buildAppBarActions(context, currentRoute),
      centerTitle: true,
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, String currentRoute) {
    switch (currentRoute) {
      case '/activity':
        return [
          buildInfoButton('Activity Tracker Info', context,
              () => showInfoDialogActivitySetup(context)),
        ];
      case '/food':
        return [
          buildInfoButton('Food Tracker Info', context,
              () => showInfoDialogFoodSetup(context)),
        ];
      case '/statistics':
        return [
          buildInfoButton('Statistics Info', context,
              () => showInfoDialogStatistics(context)),
        ];
      case '/settings':
        return [
          buildInfoButton('Settings Info', context,
              () => showInfoDialogSettingsSetup(context)),
        ];
      default:
        return [
          buildInfoButton(
              'About Gymli', context, () => showInfoDialogMain(context)),
        ];
    }
  }

  String _getTitleForRoute(String route) {
    switch (route) {
      case '/main':
        return 'Gymli';
      case '/exercise-setup':
        return 'Exercise Setup';
      case '/workout-setup':
        return 'Workout Setup';
      case '/activity':
        return 'Activity Tracker';
      case '/food':
        return 'Food Tracker';
      case '/statistics':
        return 'Statistics';
      case '/calendar':
        return 'Calendar';
      case '/settings':
        return 'Settings';
      default:
        return 'Gymli';
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _authService.removeListener(_onAuthChanged);
    }
    super.dispose();
  }
}

/// Content widget for the main dashboard
class MainAppContent extends ConsumerWidget {
  const MainAppContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LandingScreen(
      onPhaseColorChanged: (c) =>
          ref.read(themeControllerProvider.notifier).setSeedColor(c),
    );
  }
}
