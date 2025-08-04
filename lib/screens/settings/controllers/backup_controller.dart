/// Backup Controller - Handles data export operations
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/settings_repository.dart';
import '../services/csv_service.dart';
import '../services/file_service.dart';
import '../models/settings_data_type.dart';
import '../models/settings_operation_result.dart';

class BackupController extends ChangeNotifier {
  final SettingsRepository _repository;

  bool _isExporting = false;
  String? _currentOperation;

  BackupController({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

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
        case SettingsDataType.trainingSets:
          data = await _repository.getTrainingSets();
          break;
        case SettingsDataType.exercises:
          data = await _repository.getExercises();
          break;
        case SettingsDataType.workouts:
          data = await _repository.getWorkouts();
          break;
        case SettingsDataType.foods:
          data = await _repository.getFoods();
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
