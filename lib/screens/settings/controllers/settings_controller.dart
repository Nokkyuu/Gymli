/// Settings Controller - Main orchestrator for settings operations
library;

import 'package:Gymli/utils/models/data_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/settings_data_type.dart';
import '../models/settings_operation_result.dart';
import 'backup_controller.dart';
import 'restore_controller.dart';
import 'wipe_controller.dart';
import 'package:Gymli/utils/services/service_export.dart';
import 'package:get_it/get_it.dart';

class SettingsController extends ChangeNotifier {
  final BackupController _backupController;
  final RestoreController _restoreController;
  final WipeController _wipeController;
  final ExerciseService _exerciseService = GetIt.I<ExerciseService>();
  final WorkoutService _workoutService = GetIt.I<WorkoutService>();
  final TrainingSetService _trainingSetService = GetIt.I<TrainingSetService>();
  final FoodService _foodService = GetIt.I<FoodService>();

  bool _isAnyOperationInProgress = false;

  SettingsController({
    BackupController? backupController,
    RestoreController? restoreController,
    WipeController? wipeController,
  })  : _backupController = backupController ?? BackupController(),
        _restoreController = restoreController ?? RestoreController(),
        _wipeController = wipeController ?? WipeController() {
    // Listen to child controllers
    _backupController.addListener(_onChildControllerChange);
    _restoreController.addListener(_onChildControllerChange);
    _wipeController.addListener(_onChildControllerChange);
  }

  // Getters for accessing child controllers
  BackupController get backupController => _backupController;
  RestoreController get restoreController => _restoreController;
  WipeController get wipeController => _wipeController;

  // Operation status
  bool get isAnyOperationInProgress => _isAnyOperationInProgress;
  bool get isExporting => _backupController.isExporting;
  bool get isImporting => _restoreController.isImporting;
  bool get isClearing => _wipeController.isClearing;

  // Progress information
  String? get currentOperation {
    if (_backupController.isExporting) {
      return _backupController.currentOperation;
    }
    if (_restoreController.isImporting) {
      return _restoreController.currentOperation;
    }
    if (_wipeController.isClearing) return _wipeController.currentOperation;
    return null;
  }

  double get progress {
    if (_restoreController.isImporting) return _restoreController.progress;
    if (_wipeController.isClearing) return _wipeController.progress;
    return 0.0;
  }

  /// High-level data operations
  Future<SettingsOperationResult> exportData(
    SettingsDataType dataType,
    BuildContext context,
  ) async {
    return await _backupController.exportData(dataType, context);
  }

  Future<SettingsOperationResult> exportAllData(BuildContext context) async {
    // Since BackupController doesn't have exportAllData, we'll implement it here
    final results = <SettingsOperationResult>[];
    const dataTypes = SettingsDataType.values;

    for (final dataType in dataTypes) {
      final result = await _backupController.exportData(dataType, context);
      results.add(result);
      if (!result.isSuccess) break; // Stop on first failure
    }

    final successful = results.where((r) => r.isSuccess).length;
    if (successful == results.length) {
      return SettingsOperationResult.success(
        message: 'All data exported successfully',
      );
    } else {
      return SettingsOperationResult.error(
        message:
            'Export completed partially: $successful/${results.length} successful',
      );
    }
  }

  Future<SettingsOperationResult> importData(
    SettingsDataType dataType,
    BuildContext context,
  ) async {
    return await _restoreController.importData(dataType, context);
  }

  Future<SettingsOperationResult> clearData(SettingsDataType dataType) async {
    return await _wipeController.clearData(dataType);
  }

  Future<SettingsOperationResult> clearAllData() async {
    return await _wipeController.clearAllData();
  }

  /// Data count methods for UI display
  Future<Map<SettingsDataType, int>> getDataCounts() async {
    try {
      final results = await Future.wait([
        _exerciseService.getExercises(),
        _workoutService.getWorkouts(),
        _foodService.getFoods(),
      ]);
      final numTrainings = await GetIt.I<TrainingSetService>().getTrainingSetsCount();
      return {
        SettingsDataType.trainingSets: numTrainings,
        SettingsDataType.exercises: results[0].length,
        SettingsDataType.workouts: results[1].length,
        SettingsDataType.foods: results[2].length,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting data counts: $e');
      return {
        SettingsDataType.trainingSets: 0,
        SettingsDataType.exercises: 0,
        SettingsDataType.workouts: 0,
        SettingsDataType.foods: 0,
      };
    }
  }

  /// Check if specific data type has data
  Future<bool> hasData(SettingsDataType dataType) async {
    try {
      late List<dynamic> data;
      switch (dataType) {
        case SettingsDataType.trainingSets:
          data = await _trainingSetService.getTrainingSets();
          break;
        case SettingsDataType.exercises:
          data = await _exerciseService.getExercises();
          break;
        case SettingsDataType.workouts:
          data = await _workoutService.getWorkouts();
          break;
        case SettingsDataType.foods:
          data = await _foodService.getFoods();
          break;
      }
      return data.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking data for ${dataType.displayName}: $e');
      }
      return false;
    }
  }

  /// Check if any data exists
  Future<bool> hasAnyData() async {
    try {
      final counts = await getDataCounts();
      return counts.values.any((count) => count > 0);
    } catch (e) {
      if (kDebugMode) print('Error checking for any data: $e');
      return false;
    }
  }

  /// Batch operations helper
  Future<List<SettingsOperationResult>> performBatchOperation(
    List<SettingsDataType> dataTypes,
    Future<SettingsOperationResult> Function(SettingsDataType) operation,
  ) async {
    final results = <SettingsOperationResult>[];

    for (final dataType in dataTypes) {
      try {
        final result = await operation(dataType);
        results.add(result);
      } catch (e) {
        results.add(SettingsOperationResult.error(
          message: 'Failed ${dataType.displayName}: $e',
        ));
      }
    }

    return results;
  }

  /// Get operation summary for batch operations
  String getBatchOperationSummary(List<SettingsOperationResult> results) {
    final successful = results.where((r) => r.isSuccess).length;
    final failed = results.length - successful;

    if (failed == 0) {
      return 'All $successful operations completed successfully';
    } else if (successful == 0) {
      return 'All $failed operations failed';
    } else {
      return '$successful successful, $failed failed';
    }
  }

  void _onChildControllerChange() {
    final wasInProgress = _isAnyOperationInProgress;
    _isAnyOperationInProgress = isExporting || isImporting || isClearing;

    if (wasInProgress != _isAnyOperationInProgress) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _backupController.removeListener(_onChildControllerChange);
    _restoreController.removeListener(_onChildControllerChange);
    _wipeController.removeListener(_onChildControllerChange);

    _backupController.dispose();
    _restoreController.dispose();
    _wipeController.dispose();

    super.dispose();
  }
}
