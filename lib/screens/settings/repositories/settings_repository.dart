/// Settings Repository - Data access layer for settings operations
library;
import 'package:get_it/get_it.dart';

import 'package:flutter/foundation.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import '../../../utils/api/api.dart';

class SettingsRepository {
  final TempService container = GetIt.I<TempService>();
  final ExerciseService exerciseService = GetIt.I<ExerciseService>();

  /// Get training sets data
  Future<List<dynamic>> getTrainingSets() async {
    try {
      return await container.trainingSetService.getTrainingSets();
    } catch (e) {
      if (kDebugMode) print('Error getting training sets: $e');
      rethrow;
    }
  }

  /// Get exercises data
  Future<List<dynamic>> getExercises() async {
    try {
      return await exerciseService.getExercises();
    } catch (e) {
      if (kDebugMode) print('Error getting exercises: $e');
      rethrow;
    }
  }

  /// Get workouts data
  Future<List<dynamic>> getWorkouts() async {
    try {
      return await container.workoutService.getWorkouts();
    } catch (e) {
      if (kDebugMode) print('Error getting workouts: $e');
      rethrow;
    }
  }

  /// Get foods data
  Future<List<dynamic>> getFoods() async {
    try {
      return await container.foodService.getFoods();
    } catch (e) {
      if (kDebugMode) print('Error getting foods: $e');
      rethrow;
    }
  }

  /// Clear training sets
  Future<void> clearTrainingSets() async {
    try {
      await container.trainingSetService.clearTrainingSets();
      container.notifyDataChanged();
    } catch (e) {
      if (kDebugMode) print('Error clearing training sets: $e');
      rethrow;
    }
  }

  /// Clear exercises (also clears dependent data)
  Future<void> clearExercises() async {
    try {
      await container.clearWorkouts();
      await container.trainingSetService.clearTrainingSets();
      await container.clearExercises();
      container.notifyDataChanged();
    } catch (e) {
      if (kDebugMode) print('Error clearing exercises: $e');
      rethrow;
    }
  }

  /// Clear workouts
  Future<void> clearWorkouts() async {
    try {
      await container.clearWorkouts();
      container.notifyDataChanged();
    } catch (e) {
      if (kDebugMode) print('Error clearing workouts: $e');
      rethrow;
    }
  }

  /// Clear foods
  Future<void> clearFoods() async {
    try {
      await container.foodService.clearFoods();
      container.notifyDataChanged();
    } catch (e) {
      if (kDebugMode) print('Error clearing foods: $e');
      rethrow;
    }
  }

  /// Create training sets in bulk
  Future<void> createTrainingSetsBulk(
      List<Map<String, dynamic>> trainingSets) async {
    try {
      await container.trainingSetService
          .createTrainingSetsBulk(trainingSets: trainingSets);
    } catch (e) {
      if (kDebugMode) print('Error creating training sets bulk: $e');
      rethrow;
    }
  }

  /// Create exercise
  Future<void> createExercise(Map<String, dynamic> exerciseData) async {
    try {
      await exerciseService.createExercise(
        name: exerciseData['name'],
        type: exerciseData['type'],
        defaultRepBase: exerciseData['defaultRepBase'],
        defaultRepMax: exerciseData['defaultRepMax'],
        defaultIncrement: exerciseData['defaultIncrement'],
        pectoralisMajor: exerciseData['pectoralisMajor'],
        trapezius: exerciseData['trapezius'],
        biceps: exerciseData['biceps'],
        abdominals: exerciseData['abdominals'],
        frontDelts: exerciseData['frontDelts'],
        deltoids: exerciseData['deltoids'],
        backDelts: exerciseData['backDelts'],
        latissimusDorsi: exerciseData['latissimusDorsi'],
        triceps: exerciseData['triceps'],
        gluteusMaximus: exerciseData['gluteusMaximus'],
        hamstrings: exerciseData['hamstrings'],
        quadriceps: exerciseData['quadriceps'],
        forearms: exerciseData['forearms'],
        calves: exerciseData['calves'],
      );
    } catch (e) {
      if (kDebugMode) print('Error creating exercise: $e');
      rethrow;
    }
  }

  /// Create workout
  Future<Map<String, dynamic>> createWorkout({
    required String name,
    required List<Map<String, dynamic>> units,
  }) async {
    try {
      return await container.createWorkout(
        name: name,
        units: units,
      );
    } catch (e) {
      if (kDebugMode) print('Error creating workout: $e');
      rethrow;
    }
  }

  /// Create foods in bulk
  Future<void> createFoodsBulk(List<Map<String, dynamic>> foods) async {
    try {
      await container.foodService.createFoodsBulk(foods: foods);
    } catch (e) {
      if (kDebugMode) print('Error creating foods bulk: $e');
      rethrow;
    }
  }

  /// Get exercise ID by name
  Future<int?> getExerciseIdByName(String name) async {
    try {
      return await container.getExerciseIdByName(name);
    } catch (e) {
      if (kDebugMode) print('Error getting exercise ID by name: $e');
      rethrow;
    }
  }

  /// Notify data changed
  void notifyDataChanged() {
    container.notifyDataChanged();
  }

  /// Get current user name
  String? get userName => container.authService.userName;
}
