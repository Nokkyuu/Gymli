/// Settings Repository - Data access layer for settings operations
library;

import 'package:get_it/get_it.dart';

import 'package:flutter/foundation.dart';
import '../../../utils/services/service_export.dart';
//import 'package:Gymli/utils/services/auth_service.dart';
import 'package:Gymli/utils/services/authentication_service.dart';

class SettingsRepository {
  final TempService container = GetIt.I<TempService>();
  final ExerciseService exerciseService = GetIt.I<ExerciseService>();

  /// Get training sets data
  Future<List<dynamic>> getTrainingSets() async {
    try {
      return await GetIt.I<TrainingSetService>().getTrainingSets();
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
      return await GetIt.I<WorkoutService>().getWorkouts();
    } catch (e) {
      if (kDebugMode) print('Error getting workouts: $e');
      rethrow;
    }
  }

  /// Get foods data
  Future<List<dynamic>> getFoods() async {
    try {
      return await GetIt.I<FoodService>().getFoods();
    } catch (e) {
      if (kDebugMode) print('Error getting foods: $e');
      rethrow;
    }
  }

  /// Clear training sets
  Future<void> clearTrainingSets() async {
    try {
      await GetIt.I<TrainingSetService>().clearTrainingSets();
      // GetIt.I<AuthService>().notifyAuthStateChanged();
    } catch (e) {
      if (kDebugMode) print('Error clearing training sets: $e');
      rethrow;
    }
  }

  /// Clear exercises (also clears dependent data)
  Future<void> clearExercises() async {
    try {
      // await GetIt.I<WorkoutService>().clearWorkouts();
      // await GetIt.I<TrainingSetService>().clearTrainingSets();
      // await GetIt.I<ExerciseService>().clearExercises();
      // GetIt.I<AuthService>().notifyAuthStateChanged();
    } catch (e) {
      if (kDebugMode) print('Error clearing exercises: $e');
      rethrow;
    }
  }

  /// Clear workouts
  Future<void> clearWorkouts() async {
    try {
      await GetIt.I<WorkoutService>().clearWorkouts();
      //GetIt.I<AuthService>().notifyAuthStateChanged();
    } catch (e) {
      if (kDebugMode) print('Error clearing workouts: $e');
      rethrow;
    }
  }

  /// Clear foods
  Future<void> clearFoods() async {
    try {
      await GetIt.I<FoodService>().clearFoods();
      //GetIt.I<AuthService>().notifyAuthStateChanged();
    } catch (e) {
      if (kDebugMode) print('Error clearing foods: $e');
      rethrow;
    }
  }

  /// Create training sets in bulk
  Future<void> createTrainingSetsBulk(
      List<Map<String, dynamic>> trainingSets) async {
    try {
      await GetIt.I<TrainingSetService>()
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
          calves: exerciseData['calves']);
    } catch (e) {
      if (kDebugMode) print('Error creating exercise: $e');
      rethrow;
    }
  }

  /// Create workout

  /// Create foods in bulk
  Future<void> createFoodsBulk(List<Map<String, dynamic>> foods) async {
    try {
      await GetIt.I<FoodService>().createFoodsBulk(foods: foods);
    } catch (e) {
      if (kDebugMode) print('Error creating foods bulk: $e');
      rethrow;
    }
  }

  /// Get exercise ID by name
  Future<int?> getExerciseIdByName(String name) async {
    try {
      return await GetIt.I<ExerciseService>().getExerciseIdByName(name);
    } catch (e) {
      if (kDebugMode) print('Error getting exercise ID by name: $e');
      rethrow;
    }
  }

  /// Notify data changed
  // void notifyDataChanged() {
  //   ((GetIt.I<AuthService>().notifyAuthStateChanged();
  // }

  /// Get current user name
  String? get userName => GetIt.I<AuthenticationService>().userName;
}
