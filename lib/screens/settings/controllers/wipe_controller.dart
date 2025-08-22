/// Wipe Controller - Handles data clearing operations
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import '../models/settings_data_type.dart';
import '../models/settings_operation_result.dart';

class WipeController extends ChangeNotifier {
  final SettingsRepository _repository;

  bool _isClearing = false;
  String? _currentOperation;
  double _progress = 0.0;

  WipeController({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

  bool get isClearing => _isClearing;
  String? get currentOperation => _currentOperation;
  double get progress => _progress;

  /// Clear specific data type
  Future<SettingsOperationResult> clearData(SettingsDataType dataType) async {
    try {
      _setClearing(true, 'Preparing to clear ${dataType.displayName}...', 0.1);

      late SettingsOperationResult result;
      switch (dataType) {
        case SettingsDataType.trainingSets:
          result = await _clearTrainingSets();
          break;
        case SettingsDataType.exercises:
          result = await _clearExercises();
          break;
        case SettingsDataType.workouts:
          result = await _clearWorkouts();
          break;
        case SettingsDataType.foods:
          result = await _clearFoods();
          break;
      }

      if (result.isSuccess) {
        // _repository.notifyDataChanged();
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('Error in clearData: $e');
      return SettingsOperationResult.error(
        message: 'Error clearing ${dataType.displayName}: ${e.toString()}',
        error: e is Exception ? e : Exception(e.toString()),
      );
    } finally {
      _setClearing(false);
    }
  }

  /// Clear all application data
  Future<SettingsOperationResult> clearAllData() async {
    try {
      _setClearing(true, 'Preparing to clear all data...', 0.1);

      final clearOperations = [
        () => _clearTrainingSets(),
        () => _clearExercises(),
        () => _clearWorkouts(),
        () => _clearFoods(),
      ];

      final List<String> errors = [];
      int successCount = 0;

      for (int i = 0; i < clearOperations.length; i++) {
        final operation = clearOperations[i];

        try {
          final result = await operation();
          if (result.isSuccess) {
            successCount++;
          } else {
            errors.add(result.message ?? 'Unknown error');
          }
        } catch (e) {
          errors.add('Operation ${i + 1} failed: $e');
        }
      }

      _setClearing(true, 'Finalizing...', 0.9);
      //_repository.notifyDataChanged();

      if (errors.isEmpty) {
        return SettingsOperationResult.success(
          message: 'All data cleared successfully',
        );
      } else if (successCount > 0) {
        return SettingsOperationResult.success(
          message: 'Partial success: $successCount operations completed',
        );
      } else {
        return SettingsOperationResult.error(
          message: 'Failed to clear data: ${errors.join(', ')}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error in clearAllData: $e');
      return SettingsOperationResult.error(
        message: 'Error clearing all data: ${e.toString()}',
        error: e is Exception ? e : Exception(e.toString()),
      );
    } finally {
      _setClearing(false);
    }
  }

  /// Clear training sets
  Future<SettingsOperationResult> _clearTrainingSets() async {
    try {
      _setClearing(true, 'Clearing training sets...', 0.3);

      // Get count before clearing
      final trainingSets = await _repository.getTrainingSets();
      final count = trainingSets.length;

      await _repository.clearTrainingSets();

      if (kDebugMode) print('Cleared $count training sets');
      return SettingsOperationResult.success(
        message: 'Training sets cleared',
        deletedCount: count,
      );
    } catch (e) {
      if (kDebugMode) print('Error clearing training sets: $e');
      return SettingsOperationResult.error(
        message: 'Failed to clear training sets: $e',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Clear exercises
  Future<SettingsOperationResult> _clearExercises() async {
    try {
      _setClearing(true, 'Clearing exercises...', 0.5);

      // Get count before clearing
      final exercises = await _repository.getExercises();
      final count = exercises.length;

      await _repository.clearExercises();

      if (kDebugMode) print('Cleared $count exercises');
      return SettingsOperationResult.success(
        message: 'Exercises cleared',
        deletedCount: count,
      );
    } catch (e) {
      if (kDebugMode) print('Error clearing exercises: $e');
      return SettingsOperationResult.error(
        message: 'Failed to clear exercises: $e',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Clear workouts
  Future<SettingsOperationResult> _clearWorkouts() async {
    try {
      _setClearing(true, 'Clearing workouts...', 0.7);

      // Get count before clearing
      final workouts = await _repository.getWorkouts();
      final count = workouts.length;

      await _repository.clearWorkouts();

      if (kDebugMode) print('Cleared $count workouts');
      return SettingsOperationResult.success(
        message: 'Workouts cleared',
        deletedCount: count,
      );
    } catch (e) {
      if (kDebugMode) print('Error clearing workouts: $e');
      return SettingsOperationResult.error(
        message: 'Failed to clear workouts: $e',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Clear foods
  Future<SettingsOperationResult> _clearFoods() async {
    try {
      _setClearing(true, 'Clearing foods...', 0.9);

      // Get count before clearing
      final foods = await _repository.getFoods();
      final count = foods.length;

      await _repository.clearFoods();

      if (kDebugMode) print('Cleared $count foods');
      return SettingsOperationResult.success(
        message: 'Foods cleared',
        deletedCount: count,
      );
    } catch (e) {
      if (kDebugMode) print('Error clearing foods: $e');
      return SettingsOperationResult.error(
        message: 'Failed to clear foods: $e',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  void _setClearing(bool clearing, [String? operation, double? progress]) {
    _isClearing = clearing;
    _currentOperation = operation;
    if (progress != null) _progress = progress;
    if (!clearing) {
      _currentOperation = null;
      _progress = 0.0;
    }
    notifyListeners();
  }
}
