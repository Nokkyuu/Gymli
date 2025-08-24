/// Backup Controller - Handles data export operations
library;

import 'package:Gymli/utils/workout_data_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/file_service.dart';
import '../models/settings_data_type.dart';
import '../models/settings_operation_result.dart';
import 'package:Gymli/utils/services/service_export.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';

class BackupController extends ChangeNotifier {
  final TrainingSetService _trainingSetService = GetIt.I<TrainingSetService>();
  final FoodService _foodService = GetIt.I<FoodService>();
  bool _isExporting = false;
  String? _currentOperation;

  bool get isExporting => _isExporting;
  String? get currentOperation => _currentOperation;

  // Convert a list of domain objects or maps to a JSON-friendly List
  List<dynamic> _encodeList(List<dynamic> data) {
    return data.map((item) {
      // Already a primitive or Map/List
      if (item == null ||
          item is num ||
          item is String ||
          item is bool ||
          item is Map ||
          item is List) {
        return item;
      }
      // Try common toJson()/oJson() conventions
      try {
        final dyn = item as dynamic;
        if (dyn.toJson is Function) {
          return dyn.toJson();
        }
      } catch (_) {}
      try {
        final dyn = item as dynamic;
        if (dyn.oJson is Function) {
          return dyn.oJson();
        }
      } catch (_) {}
      // Fallback: best-effort string
      return item.toString();
    }).toList();
  }

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

      // Build root JSON object with one subtree per data type key
      _setExporting(true, 'Converting ${data.length} items to JSON...');
      final Map<String, dynamic> root = {
        // always use a stable key naming; we keep SettingsDataType.value as key
        dataType.value: _encodeList(data),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(root);

      if (jsonString.isEmpty) {
        return SettingsOperationResult.error(
          message: 'Failed to generate JSON data for ${dataType.displayName}',
        );
      }

      // Generate filename
      final fileName =
          "${dataType.value}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.json";

      if (kDebugMode) print('Starting file save process...');
      _setExporting(true, 'Saving file...');

      // Save file (reuse CSV saver to write JSON payload)
      final result = await FileService.saveCSVFile(
        csvData: jsonString,
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
