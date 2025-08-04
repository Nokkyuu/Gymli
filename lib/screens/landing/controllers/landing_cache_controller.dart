/// Landing Cache Controller - Manages data caching with timestamps
library;

import 'package:flutter/foundation.dart';
import '../../../utils/api/api_models.dart';

class LandingCacheController extends ChangeNotifier {
  // Cache data
  List<ApiExercise> _cachedExercises = [];
  List<ApiWorkout> _cachedWorkouts = [];
  DateTime? _exerciseCacheTimestamp;
  DateTime? _workoutCacheTimestamp;

  // Cache configuration
  static const int _cacheValiditySeconds = 30;

  // Getters
  List<ApiExercise> get cachedExercises => List.from(_cachedExercises);
  List<ApiWorkout> get cachedWorkouts => List.from(_cachedWorkouts);

  /// Check if exercise cache is valid
  bool get isExerciseCacheValid {
    if (_exerciseCacheTimestamp == null || _cachedExercises.isEmpty) {
      return false;
    }
    final now = DateTime.now();
    return now.difference(_exerciseCacheTimestamp!).inSeconds <
        _cacheValiditySeconds;
  }

  /// Check if workout cache is valid
  bool get isWorkoutCacheValid {
    if (_workoutCacheTimestamp == null || _cachedWorkouts.isEmpty) {
      return false;
    }
    final now = DateTime.now();
    return now.difference(_workoutCacheTimestamp!).inSeconds <
        _cacheValiditySeconds;
  }

  /// Update exercise cache
  void updateExerciseCache(List<ApiExercise> exercises) {
    _cachedExercises = List.from(exercises);
    _cachedExercises.sort((a, b) => a.name.compareTo(b.name));
    _exerciseCacheTimestamp = DateTime.now();
    notifyListeners();
  }

  /// Update workout cache
  void updateWorkoutCache(List<ApiWorkout> workouts) {
    _cachedWorkouts = List.from(workouts);
    _cachedWorkouts.sort((a, b) => a.name.compareTo(b.name));
    _workoutCacheTimestamp = DateTime.now();
    notifyListeners();
  }

  /// Clear all caches
  void clearCache() {
    _cachedExercises.clear();
    _cachedWorkouts.clear();
    _exerciseCacheTimestamp = null;
    _workoutCacheTimestamp = null;
    notifyListeners();
  }

  /// Force cache expiration
  void expireCache() {
    _exerciseCacheTimestamp = null;
    _workoutCacheTimestamp = null;
    notifyListeners();
  }

  /// Get cache info for debugging
  String get cacheInfo {
    final exerciseAge = _exerciseCacheTimestamp != null
        ? DateTime.now().difference(_exerciseCacheTimestamp!).inSeconds
        : -1;
    final workoutAge = _workoutCacheTimestamp != null
        ? DateTime.now().difference(_workoutCacheTimestamp!).inSeconds
        : -1;

    return 'Exercise cache: ${_cachedExercises.length} items, ${exerciseAge}s old\n'
        'Workout cache: ${_cachedWorkouts.length} items, ${workoutAge}s old';
  }
}
