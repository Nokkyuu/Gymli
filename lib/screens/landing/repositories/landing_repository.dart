/// Landing Repository - Data access layer for landing screen
library;

import 'package:flutter/foundation.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import '../../../utils/api/api_models.dart';
import 'package:get_it/get_it.dart';
import '../../../utils/api/api.dart';

class LandingRepository {
  final TempService container = GetIt.I<TempService>();

  /// Get all exercises from the service
  Future<List<ApiExercise>> getExercises() async {
    try {
      final exercises = await GetIt.I<ExerciseService>().getExercises();
      return exercises.map((e) => ApiExercise.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting exercises: $e');
      rethrow;
    }
  }

  /// Get all workouts from the service
  Future<List<ApiWorkout>> getWorkouts() async {
    try {
      final workouts = await container.getWorkouts();
      return workouts.map((w) => ApiWorkout.fromJson(w)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting workouts: $e');
      rethrow;
    }
  }

  /// Get last training days for multiple exercises in batch
  Future<Map<String, Map<String, dynamic>>> getLastTrainingDaysForExercises(
      List<String> exerciseNames) async {
    try {
      return await container.getLastTrainingDatesPerExercise(exerciseNames);
    } catch (e) {
      if (kDebugMode) print('Error getting last training days: $e');
      rethrow;
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => container.authService.isLoggedIn;

  /// Get current user name
  String? get userName => container.authService.userName;

  /// Get auth state notifier for listening to changes
  ValueNotifier<bool> get authStateNotifier =>
      container.authService.authStateNotifier;
}
