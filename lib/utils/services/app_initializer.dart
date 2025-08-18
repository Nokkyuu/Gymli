//import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:Gymli/utils/services/service_container.dart';
import '../../config/api_config.dart';
import '../globals.dart' as globals;
import '../api/api.dart';
//import 'user_service.dart';

class AppInitializer {
  static const String _auth0Domain = 'dev-aqz5a2g54oer01tk.us.auth0.com';
  static const String _auth0ClientId = 'MAxJUti2T7TkLagzT7SdeEzCTZsHyuOa';

  static late Auth0Web auth0;
  static bool _isInitialized = false;

  /// Initialize the entire app with all required services
  ///
  /// Returns an [AppInitializationResult] indicating success or failure.
  /// If initialization fails, it will return an error message.
  /// things to be initialized are:
  /// 1. Load user preferences from SharedPreferences
  /// 2. Initialize API configuration
  /// 3. Initialize Auth0 service
  /// 4. Initialize UserService and load stored auth state
  /// 5. Load initial data like exercise lists
  static Future<AppInitializationResult> initialize() async {
    if (_isInitialized) {
      return AppInitializationResult.success();
    }

    try {
      print('Starting app initialization...');

      // // 1. Load preferences
      // await _loadPreferences(); TODO: delete or implement ?
      // if (kDebugMode) print('✓ Preferences loaded');
      clearApiCache();
      if (kDebugMode) print('✓ API cache cleared');

      // 2. Initialize API configuration
      ApiConfig.initialize();
      if (kDebugMode) print('✓ API configuration initialized');

      // 3. Initialize Auth0
      _initializeAuth0();
      if (kDebugMode) print('✓ Auth0 initialized');

      // 4. Initialize UserService
      await ServiceContainer().initialize();
      if (kDebugMode) print('✓ UserService Container initialized');

      await _initializeUserService();
      if (kDebugMode) print('✓ UserService initialized');

      // 5. Load exercise list
      await _loadInitialData();
      if (kDebugMode) print('✓ Initial data loaded');

      _isInitialized = true;
      if (kDebugMode) print('App initialization completed successfully');

      return AppInitializationResult.success();
    } catch (e) {
      if (kDebugMode) print('App initialization failed: $e');

      if (kDebugMode) {
        // In debug mode, continue with limited functionality
        return AppInitializationResult.partialFailure(e.toString());
      } else {
        return AppInitializationResult.failure(e.toString());
      }
    }
  }

  /// Load user preferences from SharedPreferences
  // static Future<void> _loadPreferences() async {
  //   final prefs = await SharedPreferences.getInstance();

  //   globals.idleTimerWakeup =
  //       prefs.getInt('idleWakeTime') ?? globals.idleTimerWakeup;
  //   globals.graphNumberOfDays =
  //       prefs.getInt('graphNumberOfDays') ?? globals.graphNumberOfDays;
  //   globals.detailedGraph =
  //       prefs.getBool('detailedGraph') ?? globals.detailedGraph;
  // }

  /// Initialize Auth0 service
  static void _initializeAuth0() {
    auth0 = Auth0Web(_auth0Domain, _auth0ClientId);
  }

  /// Initialize UserService and load stored auth state
  /// This will also set the credentials if available.
  ///
  /// UserService is a singleton that manages user authentication and data handling depending on login state.
  static Future<void> _initializeUserService() async {
    //final userService = UserService();

    try {
      // Try to load stored authentication state
      final credentials =
          await ServiceContainer().authService.loadStoredAuthState();
      if (credentials != null) {
        ServiceContainer().authService.setCredentials(credentials);
      }
    } catch (e) {
      print('No stored authentication state found: $e');
      // Continue without stored auth state
    }
  }

  /// Load initial exercise data
  /// This will fetch the list of exercises from the API and store it in globals.exerciseList
  static Future<void> _loadInitialData() async {
    try {
      // Ensure API is configured before loading data, this should normaly be done in the AppInitializer
      // but we check here to avoid unnecessary API calls if not configured
      if (!ApiConfig.isConfigured) {
        print('API not configured, skipping exercise list load');
        globals.exerciseList = [];
        return;
      }

      //await Future.delayed(const Duration(milliseconds: 100)); TODO: probably not needed anymore, recheck later

      final exercises = await ServiceContainer().exerciseService.getExercises();

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
    try {
      return auth0;
    } catch (e) {
      throw StateError(
          'Auth0 not initialized. Call AppInitializer.initialize() first.');
    }
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
