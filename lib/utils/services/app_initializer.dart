import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../config/api_config.dart';
import '../globals.dart' as globals;
import '../user/user_service.dart';

class AppInitializer {
  static const String _auth0Domain = 'dev-aqz5a2g54oer01tk.us.auth0.com';
  static const String _auth0ClientId = 'MAxJUti2T7TkLagzT7SdeEzCTZsHyuOa';

  static late Auth0Web auth0;
  static bool _isInitialized = false;

  /// Initialize the entire app with all required services
  static Future<AppInitializationResult> initialize() async {
    if (_isInitialized) {
      return AppInitializationResult.success();
    }

    try {
      print('Starting app initialization...');

      // 1. Load preferences
      await _loadPreferences();
      print('✓ Preferences loaded');

      // 2. Initialize API configuration
      ApiConfig.initialize();
      print('✓ API configuration initialized');

      // 3. Initialize Auth0
      _initializeAuth0();
      print('✓ Auth0 initialized');

      // 4. Initialize UserService
      await _initializeUserService();
      print('✓ UserService initialized');

      // 5. Load exercise list (if API is configured)
      await _loadInitialData();
      print('✓ Initial data loaded');

      _isInitialized = true;
      print('App initialization completed successfully');

      return AppInitializationResult.success();
    } catch (e) {
      print('App initialization failed: $e');

      if (kDebugMode) {
        // In debug mode, continue with limited functionality
        return AppInitializationResult.partialFailure(e.toString());
      } else {
        return AppInitializationResult.failure(e.toString());
      }
    }
  }

  /// Load user preferences from SharedPreferences
  static Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    globals.idleTimerWakeup =
        prefs.getInt('idleWakeTime') ?? globals.idleTimerWakeup;
    globals.graphNumberOfDays =
        prefs.getInt('graphNumberOfDays') ?? globals.graphNumberOfDays;
    globals.detailedGraph =
        prefs.getBool('detailedGraph') ?? globals.detailedGraph;
  }

  /// Initialize Auth0 service
  static void _initializeAuth0() {
    auth0 = Auth0Web(_auth0Domain, _auth0ClientId);
  }

  /// Initialize UserService and load stored auth state
  static Future<void> _initializeUserService() async {
    final userService = UserService();

    try {
      // Try to load stored authentication state
      final credentials = await userService.loadStoredAuthState();
      if (credentials != null) {
        userService.setCredentials(credentials);
        print('Stored authentication state loaded successfully');
      }
    } catch (e) {
      print('No stored authentication state found: $e');
      // Continue without stored auth state
    }
  }

  /// Load initial data like exercise lists
  static Future<void> _loadInitialData() async {
    try {
      if (!ApiConfig.isConfigured) {
        print('API not configured, skipping exercise list load');
        globals.exerciseList = [];
        return;
      }

      // Small delay to ensure UserService is ready
      await Future.delayed(const Duration(milliseconds: 100));

      final userService = UserService();
      final exercises = await userService.getExercises();

      globals.exerciseList =
          exercises.map<String>((e) => e['name'] as String).toList();
      print('Exercise list loaded: ${globals.exerciseList.length} exercises');
    } catch (e) {
      print('Error loading initial data: $e');
      globals.exerciseList = [];
    }
  }

  /// Get the initialized Auth0 instance
  static Auth0Web getAuth0() {
    if (!_isInitialized) {
      throw StateError(
          'App not initialized. Call AppInitializer.initialize() first.');
    }
    return auth0;
  }

  /// Check if app is fully initialized
  static bool get isInitialized => _isInitialized;
}

/// Result of app initialization
class AppInitializationResult {
  final bool success;
  final bool partial;
  final String? error;

  const AppInitializationResult._({
    required this.success,
    required this.partial,
    this.error,
  });

  factory AppInitializationResult.success() {
    return const AppInitializationResult._(success: true, partial: false);
  }

  factory AppInitializationResult.partialFailure(String error) {
    return AppInitializationResult._(
        success: true, partial: true, error: error);
  }

  factory AppInitializationResult.failure(String error) {
    return AppInitializationResult._(
        success: false, partial: false, error: error);
  }
}
