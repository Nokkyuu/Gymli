/// Backup Controller - Handles data export operations
library;

import 'package:Gymli/utils/workout_data_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/csv_service.dart';
import '../services/file_service.dart';
import '../models/settings_data_type.dart';
import '../models/settings_operation_result.dart';
import 'package:Gymli/utils/services/service_export.dart';
import 'package:get_it/get_it.dart';

class BackupController extends ChangeNotifier {
  final ExerciseService _exerciseService = GetIt.I<ExerciseService>();
  final WorkoutService _workoutService = GetIt.I<WorkoutService>();
  final TrainingSetService _trainingSetService = GetIt.I<TrainingSetService>();
  final FoodService _foodService = GetIt.I<FoodService>();
  bool _isExporting = false;
  String? _currentOperation;

  bool get isExporting => _isExporting;
  String? get currentOperation => _currentOperation;

  /// Export data of specified type
  Future<SettingsOperationResult> exportData(
    SettingsDataType dataType,
    BuildContext context,
  ) async {
    _setExporting(true, 'Exporting ${dataType.displayName}...');

    try {
      // Get data from repository
      List<dynamic> data;
      switch (dataType) {
        //TODO: CACHE
        case SettingsDataType.trainingSets:
          data = await _trainingSetService.getTrainingSets();
          break;
        case SettingsDataType.exercises:
          data = GetIt.I<WorkoutDataCache>().exercises;
          break;
        case SettingsDataType.workouts:
          data = GetIt.I<WorkoutDataCache>().workouts;
          break;
        case SettingsDataType.foods:
          data = await _foodService.getFoods();
          break;
      }

      if (kDebugMode) print('Retrieved ${data.length} ${dataType.displayName}');

      if (data.isEmpty) {
        return SettingsOperationResult.error(
          message: 'No ${dataType.displayName} data to export',
        );
      }

      // Generate CSV data
      _setExporting(true, 'Converting ${data.length} items to CSV...');
      String csvData;
      switch (dataType) {
        case SettingsDataType.trainingSets:
          csvData = CsvService.generateTrainingSetsCSV(data);
          break;
        case SettingsDataType.exercises:
          csvData = CsvService.generateExercisesCSV(data);
          break;
        case SettingsDataType.workouts:
          csvData = CsvService.generateWorkoutsCSV(data);
          break;
        case SettingsDataType.foods:
          csvData = CsvService.generateFoodsCSV(data);
          break;
      }

      if (csvData.isEmpty) {
        return SettingsOperationResult.error(
          message: 'Failed to generate CSV data for ${dataType.displayName}',
        );
      }

      // Generate filename
      final fileName =
          "${dataType.value}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv";

      if (kDebugMode) print('Starting file save process...');
      _setExporting(true, 'Saving file...');

      // Save file
      final result = await FileService.saveCSVFile(
        csvData: csvData,
        fileName: fileName,
        dataType: dataType.displayName,
      );

      return result;
    } catch (e) {
      if (kDebugMode) print('Error during backup: $e');
      return SettingsOperationResult.error(
        message: 'Error exporting ${dataType.displayName}: ${e.toString()}',
        error: e is Exception ? e : Exception(e.toString()),
      );
    } finally {
      _setExporting(false);
    }
  }

  void _setExporting(bool exporting, [String? operation]) {
    _isExporting = exporting;
    _currentOperation = operation;
    notifyListeners();
  }
}
