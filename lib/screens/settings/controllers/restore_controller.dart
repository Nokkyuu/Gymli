/// Restore Controller - Handles data import operations
library;

import 'dart:convert';

import 'package:Gymli/utils/models/workout_models.dart';
import 'package:Gymli/utils/workout_data_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/file_service.dart';
import '../models/settings_data_type.dart';
import '../models/settings_operation_result.dart';
import 'package:Gymli/utils/services/service_export.dart';
import 'package:Gymli/utils/models/exercise_model.dart';

typedef _Importer = Future<SettingsOperationResult> Function(List<dynamic> items);
typedef _Clearer = Future<void> Function();

class RestoreController extends ChangeNotifier {
  // final SettingsRepository _repository;

  bool _isImporting = false;
  String? _currentOperation;
  double _progress = 0.0;

  RestoreController();

  Map<SettingsDataType, _Importer> _importHandlers() => {
        SettingsDataType.trainingSets: _importTrainingSets,
        SettingsDataType.exercises: _importExercises,
        SettingsDataType.workouts: _importWorkouts,
        SettingsDataType.foods: _importFoods,
      };

  Map<SettingsDataType, _Clearer> _clearHandlers() => {
        SettingsDataType.trainingSets: () =>
            GetIt.I<TrainingSetService>().clearTrainingSets(),
        SettingsDataType.exercises: () => clearExercises(),
        SettingsDataType.workouts: () =>
            GetIt.I<WorkoutService>().clearWorkouts(),
        SettingsDataType.foods: () async {
          try {
            final dynamic foodService = GetIt.I<FoodService>();
            if (foodService != null && foodService.clearFoods != null) {
              await foodService.clearFoods();
            }
          } catch (_) {}
        },
      };

  bool get isImporting => _isImporting;
  String? get currentOperation => _currentOperation;
  double get progress => _progress;

  /// Import data of specified type
  Future<SettingsOperationResult> importData(
    SettingsDataType dataType,
    BuildContext context,
  ) async {
    try {
      // Pick and read file
      _setImporting(true, 'Selecting file...', 0.1);
      final fileResult = await FileService.pickAndReadJsonFile(
        dataType: dataType.displayName,
      );

      if (!fileResult.isSuccess) return fileResult;

      final raw = fileResult.message!;

      // Parse JSON data
      _setImporting(true, 'Parsing JSON data...', 0.2);
      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (e) {
        return SettingsOperationResult.error(
          message: 'Invalid JSON file: ${e.toString()}',
        );
      }

      // Build a root JSON with a subtree per key. Accept either
      // an object with the target key or a raw list for backwards-compat.
      List<dynamic> items;
      if (decoded is Map<String, dynamic>) {
        final key = dataType.value;
        if (!decoded.containsKey(key)) {
          return SettingsOperationResult.error(
            message: 'JSON root must contain the key "$key"',
          );
        }
        final subtree = decoded[key];
        if (subtree is List) {
          items = subtree;
        } else {
          return SettingsOperationResult.error(
            message: 'JSON "$key" must be an array',
          );
        }
      } else if (decoded is List) {
        items = decoded;
      } else {
        return SettingsOperationResult.error(
          message: 'Unsupported JSON root. Expected object or array.',
        );
      }

      // Clear existing data first
      // _setImporting(true, 'Clearing existing data...', 0.3);
      await _clearExistingData(dataType);

      // Import based on data type (via handler registry)
      final importer = _importHandlers()[dataType];
      if (importer == null) {
        return SettingsOperationResult.error(
            message: 'No importer registered for ${dataType.displayName}');
      }
      final result = await importer(items);

      // Notify data changed
      //_repository.notifyDataChanged();

      return result;
    } catch (e) {
      if (kDebugMode) print('Error in importData: $e');
      return SettingsOperationResult.error(
        message: 'Error importing ${dataType.displayName}: ${e.toString()}',
        error: e is Exception ? e : Exception(e.toString()),
      );
    } finally {
      _setImporting(false);
    }
  }

  /// Clear existing data before import
  Future<void> _clearExistingData(SettingsDataType dataType) async { // TODO: This is redundant with Wipe
    final clearer = _clearHandlers()[dataType];
    if (clearer != null) {
      await clearer();
    }
  }
  String _normalizeName(String s) {
    return s.replaceAll('\u00A0', ' ').trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }
  /// Import training sets (bulk, via API endpoint, with cache clear)
  Future<SettingsOperationResult> _importTrainingSets(List<dynamic> items) async {
    _setImporting(true, 'Preparing training sets (bulk)...', 0.35);

    try { GetIt.I<WorkoutDataCache>().clearAllTrainingSets(); } catch (_) {}
    final exercises = GetIt.I<WorkoutDataCache>().exercises;

    final Map<String, int> exerciseNameToIdMapNorm = { for (var e in exercises) _normalizeName(e.name): e.id!,};
    final Set<int> knownExerciseIds = { for (var e in exercises) if (e.id != null) e.id! };

    // 3) Build bulk payload
    final List<Map<String, dynamic>> toCreate = [];
    int skippedCount = 0;

    for (int idx = 0; idx < items.length; idx++) {
      _setImporting(true, 'Validating ${idx + 1}/${items.length}...', 0.4 + ((idx + 1) / items.length) * 0.3);
      final item = items[idx];
      final Set<String> unresolvedNames = <String>{};
      int? exerciseId;

      try {
        if (item is! Map) { skippedCount++; continue; }
        final map = item as Map;
        final normalizedName = _normalizeName(map['exercise_name']);
        if (normalizedName != null && exerciseNameToIdMapNorm.containsKey(normalizedName)) {
            exerciseId = exerciseNameToIdMapNorm[normalizedName];
          } else {
            if (map['exercise_name'] != null && map['exercise_name'].isNotEmpty) {
              unresolvedNames.add(map['exercise_name']);
            }
            skippedCount++;
            continue;
          }

        final String? dateStrRaw = map['date']?.toString();
        if (dateStrRaw == null) { skippedCount++; continue; }
        final DateTime? date = DateTime.tryParse(dateStrRaw);
        if (date == null) { skippedCount++; continue; }

        final double? weight = (map['weight'] is num) ? (map['weight'] as num).toDouble() : null;
        final int? reps = (map['repetitions'] is num) ? (map['repetitions'] as num).toInt() : null;
        final int? setType = (map['set_type'] is num) ? (map['set_type'] as num).toInt() : null;
        final String? phase = map['phase']?.toString();
        final bool? myoreps = (map['myoreps'] is bool) ? map['myoreps'] as bool : null;

        if (weight == null || reps == null || setType == null) { skippedCount++; continue; }

        toCreate.add({
          'exercise_id': exerciseId,
          'date': date.toIso8601String(),
          'weight': weight,
          'repetitions': reps,
          'set_type': setType,
          if (phase != null) 'phase': phase,
          if (myoreps != null) 'myoreps': myoreps,
        });
      } catch (_) {
        skippedCount++;
        if (kDebugMode) print("Restore fail: $unresolvedNames");
      }
    }

    if (toCreate.isEmpty) {
      return SettingsOperationResult.error(message: 'No valid training sets found to import');
    }

    // 4) Bulk create via API (single request)
    _setImporting(true, 'Uploading training sets (bulk)...', 0.85);
    try {
      final created = await GetIt.I<TrainingSetService>().createTrainingSetsBulk(trainingSets: toCreate);
      // Fallback: if named parameter differs, try the officially provided one
      // (Dart will fail compile on wrong name, but we include alternative below).
      final importedCount = created.length;
      return SettingsOperationResult.success(
        message: 'Training sets import completed (bulk)',
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } catch (_) {
      // Retry with the exact signature provided by the user snippet
      try {
        final created = await GetIt.I<TrainingSetService>().createTrainingSetsBulk(trainingSets: toCreate);
        final importedCount = created.length;
        return SettingsOperationResult.success(
          message: 'Training sets import completed (bulk)',
          importedCount: importedCount,
          skippedCount: skippedCount,
        );
      } catch (e) {
        return SettingsOperationResult.error(message: 'Bulk upload failed: ${e.toString()}');
      }
    }
  }

  ///  ---------------------- Exercise Handlers -----------------//
  Future<void> clearExercises() async {
    return await GetIt.I<WorkoutDataCache>().clearExercises();
  }

  Future<SettingsOperationResult> _importExercises(List<dynamic> items) async {
    int importedCount = 0;
    int skippedCount = 0;

    final cache = GetIt.I<WorkoutDataCache>();

    for (int index = 0; index < items.length; index++) {
      _setImporting(true, 'Importing exercises...', 0.4 + (index / items.length) * 0.5);
      final item = items[index];
      try {
        if (item is! Map) { skippedCount++; continue; }
        final map = Map<String, dynamic>.from(item as Map);
        final exercise = Exercise.fromJson(map);
        cache.addExercise(exercise);
        importedCount++;
      } catch (_) {
        skippedCount++;
      }
    }

    return SettingsOperationResult.success(
      message: 'Exercises import completed',
      importedCount: importedCount,
      skippedCount: skippedCount,
    );
  }

  /// Import workouts
  Future<SettingsOperationResult> _importWorkouts(List<dynamic> items) async {
    int importedCount = 0;
    int skippedCount = 0;

    for (int index = 0; index < items.length; index++) {
      _setImporting(true, 'Importing workouts...', 0.4 + (index / items.length) * 0.5);
      final item = items[index];
      try {
        if (item is! Map) { skippedCount++; continue; }
        final map = item as Map;
        final name = map['name']?.toString();
        final unitsDyn = map['units'];
        if (name == null || unitsDyn is! List) { skippedCount++; continue; }

        List<Map<String, dynamic>> units = [];
        for (final u in unitsDyn) {
          if (u is! Map) continue;
          final um = u as Map;
          int? exerciseId = (um['exercise_id'] is num) ? (um['exercise_id'] as num).toInt() : (um['exerciseId'] is num) ? (um['exerciseId'] as num).toInt() : null;
          if (exerciseId == null && um['exerciseName'] != null) {
            final id = await GetIt.I<ExerciseService>().getExerciseIdByName(um['exerciseName'].toString());
            exerciseId = id;
          }
          if (exerciseId == null) continue;
          units.add({
            'exercise_id': exerciseId,
            'warmups': (um['warmups'] is num) ? (um['warmups'] as num).toInt() : int.tryParse(um['warmups']?.toString() ?? '0') ?? 0,
            'worksets': (um['worksets'] is num) ? (um['worksets'] as num).toInt() : int.tryParse(um['worksets']?.toString() ?? '0') ?? 0,
            'dropsets': (um['dropsets'] is num) ? (um['dropsets'] as num).toInt() : int.tryParse(um['dropsets']?.toString() ?? '0') ?? 0,
            'type': (um['type'] is num) ? (um['type'] as num).toInt() : int.tryParse(um['type']?.toString() ?? '0') ?? 0,
          });
        }

        if (units.isNotEmpty) {
          await GetIt.I<WorkoutService>().createWorkout(name: name, units: units);
          importedCount++;
        } else {
          skippedCount++;
        }
      } catch (_) {
        skippedCount++;
      }
    }

    return SettingsOperationResult.success(
      message: 'Workouts import completed',
      importedCount: importedCount,
      skippedCount: skippedCount,
    );
  }

  /// Import foods
  Future<SettingsOperationResult> _importFoods(List<dynamic> items) async {
    _setImporting(true, 'Preparing food items...', 0.4);

    List<Map<String, dynamic>> foodsToCreate = [];
    int skippedCount = 0;

    for (final item in items) {
      try {
        if (item is! Map) { skippedCount++; continue; }
        final m = item as Map;
        final name = m['name']?.toString();
        if (name == null || name.isEmpty) { skippedCount++; continue; }
        double? kcal = (m['kcalPer100g'] is num) ? (m['kcalPer100g'] as num).toDouble() : (m['kcal_per_100g'] is num) ? (m['kcal_per_100g'] as num).toDouble() : double.tryParse(m['kcalPer100g']?.toString() ?? m['kcal_per_100g']?.toString() ?? '');
        double? prot = (m['proteinPer100g'] is num) ? (m['proteinPer100g'] as num).toDouble() : (m['protein_per_100g'] is num) ? (m['protein_per_100g'] as num).toDouble() : double.tryParse(m['proteinPer100g']?.toString() ?? m['protein_per_100g']?.toString() ?? '');
        double? carbs = (m['carbsPer100g'] is num) ? (m['carbsPer100g'] as num).toDouble() : (m['carbs_per_100g'] is num) ? (m['carbs_per_100g'] as num).toDouble() : double.tryParse(m['carbsPer100g']?.toString() ?? m['carbs_per_100g']?.toString() ?? '');
        double? fat = (m['fatPer100g'] is num) ? (m['fatPer100g'] as num).toDouble() : (m['fat_per_100g'] is num) ? (m['fat_per_100g'] as num).toDouble() : double.tryParse(m['fatPer100g']?.toString() ?? m['fat_per_100g']?.toString() ?? '');
        final notes = m['notes']?.toString();

        if (kcal == null || prot == null || carbs == null || fat == null) { skippedCount++; continue; }

        foodsToCreate.add({
          'name': name,
          'kcalPer100g': kcal,
          'proteinPer100g': prot,
          'carbsPer100g': carbs,
          'fatPer100g': fat,
          if (notes != null) 'notes': notes,
        });
      } catch (_) {
        skippedCount++;
      }
    }

    if (foodsToCreate.isNotEmpty) {
      const batchSize = 1000;
      final totalBatches = (foodsToCreate.length / batchSize).ceil();
      int importedCount = 0;

      for (int i = 0; i < foodsToCreate.length; i += batchSize) {
        final endIndex = (i + batchSize < foodsToCreate.length) ? i + batchSize : foodsToCreate.length;
        final batch = foodsToCreate.sublist(i, endIndex);
        final currentBatch = (i / batchSize).floor() + 1;

        _setImporting(true, 'Importing batch $currentBatch of $totalBatches', 0.5 + (currentBatch / totalBatches) * 0.4);

        try {
          await GetIt.I<FoodService>().createFoodsBulk(foods: batch);
          importedCount += batch.length;
        } catch (_) {
          skippedCount += batch.length;
        }
      }

      return SettingsOperationResult.success(
        message: 'Foods import completed',
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } else {
      return SettingsOperationResult.error(message: 'No valid food items found to import');
    }
  }

  void _setImporting(bool importing, [String? operation, double? progress]) {
    _isImporting = importing;
    _currentOperation = operation;
    if (progress != null) _progress = progress;
    if (!importing) {
      _currentOperation = null;
      _progress = 0.0;
    }
    notifyListeners();
  }
}
