/// Restore Controller - Handles data import operations
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import '../services/csv_service.dart';
import '../services/file_service.dart';
import '../models/settings_data_type.dart';
import '../models/settings_operation_result.dart';

class RestoreController extends ChangeNotifier {
  final SettingsRepository _repository;

  bool _isImporting = false;
  String? _currentOperation;
  double _progress = 0.0;

  RestoreController({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

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
      final fileResult = await FileService.pickAndReadCSVFile(
        dataType: dataType.displayName,
      );

      if (!fileResult.isSuccess) {
        return fileResult;
      }

      final csvData = fileResult.message!;

      // Parse CSV data
      _setImporting(true, 'Parsing CSV data...', 0.2);
      final csvTable = CsvService.parseCSV(csvData);

      if (csvTable.isEmpty) {
        return SettingsOperationResult.error(
          message: 'No data found in CSV file',
        );
      }

      // Clear existing data first
      _setImporting(true, 'Clearing existing data...', 0.3);
      await _clearExistingData(dataType);

      // Import based on data type
      late SettingsOperationResult result;
      switch (dataType) {
        case SettingsDataType.trainingSets:
          result = await _importTrainingSets(csvTable);
          break;
        case SettingsDataType.exercises:
          result = await _importExercises(csvTable);
          break;
        case SettingsDataType.workouts:
          result = await _importWorkouts(csvTable);
          break;
        case SettingsDataType.foods:
          result = await _importFoods(csvTable);
          break;
      }

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
  Future<void> _clearExistingData(SettingsDataType dataType) async {
    switch (dataType) {
      case SettingsDataType.trainingSets:
        await _repository.clearTrainingSets();
        break;
      case SettingsDataType.exercises:
        await _repository.clearExercises();
        break;
      case SettingsDataType.workouts:
        await _repository.clearWorkouts();
        break;
      case SettingsDataType.foods:
        await _repository.clearFoods();
        break;
    }
  }

  /// Import training sets
  Future<SettingsOperationResult> _importTrainingSets(
      List<List<String>> csvTable) async {
    _setImporting(true, 'Fetching exercises for ID resolution...', 0.4);

    // Get exercise lookup map
    final exercises = await _repository.getExercises();
    final Map<String, int> exerciseNameToIdMap = {};
    for (var exercise in exercises) {
      exerciseNameToIdMap[exercise.name] = exercise.id;
    }

    if (kDebugMode)
      print(
          'Created exercise lookup map with ${exerciseNameToIdMap.length} exercises');

    // Prepare training sets
    _setImporting(true, 'Preparing training sets...', 0.5);
    List<Map<String, dynamic>> trainingSetsToCreate = [];
    int skippedCount = 0;

    for (List<String> row in csvTable) {
      // Remove trailing empty columns
      while (row.isNotEmpty && row.last.trim().isEmpty) {
        row.removeLast();
      }

      // Handle both old (5 columns) and new (7 columns) CSV formats
      if (row.length >= 5) {
        try {
          final exerciseId = exerciseNameToIdMap[row[0].trim()];
          if (exerciseId != null) {
            final trainingSetData = {
              'exerciseId': exerciseId,
              'date': DateTime.parse(row[1]).toIso8601String(),
              'weight': double.parse(row[2]),
              'repetitions': int.parse(row[3]),
              'setType': int.parse(row[4]),
            };

            // Handle new format with phase and myoreps columns
            if (row.length >= 7) {
              // Add phase if present and not empty
              if (row.length > 5 && row[5].trim().isNotEmpty) {
                trainingSetData['phase'] = row[5].trim();
              }
              // Add myoreps if present and not empty
              if (row.length > 6 && row[6].trim().isNotEmpty) {
                trainingSetData['myoreps'] =
                    row[6].trim().toLowerCase() == 'true';
              }
            }

            trainingSetsToCreate.add(trainingSetData);
          } else {
            if (kDebugMode)
              print(
                  'Warning: Exercise "${row[0]}" not found, skipping training set');
            skippedCount++;
          }
        } catch (e) {
          if (kDebugMode)
            print('Error preparing training set for exercise "${row[0]}": $e');
          skippedCount++;
        }
      } else {
        if (kDebugMode) print('Skipping row with wrong data: $row');
        skippedCount++;
      }
    }

    // Import in batches
    if (trainingSetsToCreate.isNotEmpty) {
      final batchSize = 1000;
      final totalBatches = (trainingSetsToCreate.length / batchSize).ceil();
      int importedCount = 0;

      for (int i = 0; i < trainingSetsToCreate.length; i += batchSize) {
        final endIndex = (i + batchSize < trainingSetsToCreate.length)
            ? i + batchSize
            : trainingSetsToCreate.length;
        final batch = trainingSetsToCreate.sublist(i, endIndex);
        final currentBatch = (i / batchSize).floor() + 1;

        _setImporting(
          true,
          'Importing batch $currentBatch of $totalBatches',
          0.5 + (currentBatch / totalBatches) * 0.4,
        );

        try {
          await _repository.createTrainingSetsBulk(batch);
          importedCount += batch.length;
          if (kDebugMode)
            print(
                'Successfully imported batch of ${batch.length} training sets');
        } catch (e) {
          if (kDebugMode) print('Error importing batch: $e');
          skippedCount += batch.length;
        }
      }

      return SettingsOperationResult.success(
        message: 'Training sets import completed',
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } else {
      return SettingsOperationResult.error(
        message: 'No valid training sets found to import',
      );
    }
  }

  /// Import exercises
  Future<SettingsOperationResult> _importExercises(
      List<List<String>> csvTable) async {
    int importedCount = 0;
    int skippedCount = 0;

    for (int index = 0; index < csvTable.length; index++) {
      final row = csvTable[index].map((e) => e.trim()).toList();

      _setImporting(
        true,
        'Importing exercises...',
        0.4 + (index / csvTable.length) * 0.5,
      );

      if (row.length >= 6) {
        try {
          final muscleIntensities =
              CsvService.parseCSVMuscleIntensities(row[2]);

          // Ensure we have exactly 14 values
          while (muscleIntensities.length < 14) {
            muscleIntensities.add(0.0);
          }

          final exerciseData = {
            'name': row[0],
            'type': int.parse(row[1]),
            'defaultRepBase': int.parse(row[3]),
            'defaultRepMax': int.parse(row[4]),
            'defaultIncrement': double.parse(row[5]),
            'pectoralisMajor': muscleIntensities[0],
            'trapezius': muscleIntensities[1],
            'biceps': muscleIntensities[2],
            'abdominals': muscleIntensities[3],
            'frontDelts': muscleIntensities[4],
            'deltoids': muscleIntensities[5],
            'backDelts': muscleIntensities[6],
            'latissimusDorsi': muscleIntensities[7],
            'triceps': muscleIntensities[8],
            'gluteusMaximus': muscleIntensities[9],
            'hamstrings': muscleIntensities[10],
            'quadriceps': muscleIntensities[11],
            'forearms': muscleIntensities[12],
            'calves': muscleIntensities[13],
          };

          await _repository.createExercise(exerciseData);
          importedCount++;
          if (kDebugMode) print('Successfully imported exercise: ${row[0]}');
        } catch (e) {
          if (kDebugMode) print('Error importing exercise "${row[0]}": $e');
          skippedCount++;
        }
      }
    }

    return SettingsOperationResult.success(
      message: 'Exercises import completed',
      importedCount: importedCount,
      skippedCount: skippedCount,
    );
  }

  /// Import workouts
  Future<SettingsOperationResult> _importWorkouts(
      List<List<String>> csvTable) async {
    int importedCount = 0;
    int skippedCount = 0;

    for (int index = 0; index < csvTable.length; index++) {
      final row = csvTable[index].map((e) => e.trim()).toList();

      _setImporting(
        true,
        'Importing workouts...',
        0.4 + (index / csvTable.length) * 0.5,
      );

      if (row.isNotEmpty) {
        try {
          final workoutName = row[0];
          List<Map<String, dynamic>> units = [];

          for (int i = 1; i < row.length; i++) {
            final unitStr = row[i].split(", ");
            if (unitStr.length >= 5) {
              final exerciseId =
                  await _repository.getExerciseIdByName(unitStr[0]);
              if (exerciseId != null) {
                units.add({
                  'exercise_id': exerciseId,
                  'warmups': int.parse(unitStr[1]),
                  'worksets': int.parse(unitStr[2]),
                  'dropsets': int.parse(unitStr[3]),
                  'type': int.parse(unitStr[4]),
                });
              } else {
                if (kDebugMode)
                  print('Warning: Exercise "${unitStr[0]}" not found');
                skippedCount++;
              }
            }
          }

          if (units.isNotEmpty) {
            await _repository.createWorkout(name: workoutName, units: units);
            importedCount++;
            if (kDebugMode)
              print('Successfully imported workout: $workoutName');
          } else {
            if (kDebugMode)
              print('Warning: No valid units found for workout: $workoutName');
            skippedCount++;
          }
        } catch (e) {
          if (kDebugMode) print('Error importing workout "${row[0]}": $e');
          skippedCount++;
        }
      }
    }

    return SettingsOperationResult.success(
      message: 'Workouts import completed',
      importedCount: importedCount,
      skippedCount: skippedCount,
    );
  }

  /// Import foods
  Future<SettingsOperationResult> _importFoods(
      List<List<String>> csvTable) async {
    _setImporting(true, 'Preparing food items...', 0.4);

    List<Map<String, dynamic>> foodsToCreate = [];
    int skippedCount = 0;

    for (final row in csvTable) {
      final cleanRow = row.map((e) => e.trim()).toList();

      if (cleanRow.length >= 5) {
        try {
          foodsToCreate.add({
            'name': cleanRow[0],
            'kcalPer100g': double.parse(cleanRow[1]),
            'proteinPer100g': double.parse(cleanRow[2]),
            'carbsPer100g': double.parse(cleanRow[3]),
            'fatPer100g': double.parse(cleanRow[4]),
            'notes': cleanRow.length > 5 ? cleanRow[5] : null,
          });
          if (kDebugMode) print('Prepared food item: ${cleanRow[0]}');
        } catch (e) {
          if (kDebugMode)
            print('Error preparing food item "${cleanRow[0]}": $e');
          skippedCount++;
        }
      } else {
        if (kDebugMode) print('Skipping row with insufficient data: $cleanRow');
        skippedCount++;
      }
    }

    // Import in batches
    if (foodsToCreate.isNotEmpty) {
      final batchSize = 1000;
      final totalBatches = (foodsToCreate.length / batchSize).ceil();
      int importedCount = 0;

      for (int i = 0; i < foodsToCreate.length; i += batchSize) {
        final endIndex = (i + batchSize < foodsToCreate.length)
            ? i + batchSize
            : foodsToCreate.length;
        final batch = foodsToCreate.sublist(i, endIndex);
        final currentBatch = (i / batchSize).floor() + 1;

        _setImporting(
          true,
          'Importing batch $currentBatch of $totalBatches',
          0.5 + (currentBatch / totalBatches) * 0.4,
        );

        try {
          await _repository.createFoodsBulk(batch);
          importedCount += batch.length;
          if (kDebugMode)
            print('Successfully imported batch of ${batch.length} food items');
        } catch (e) {
          if (kDebugMode) print('Error importing batch: $e');
          skippedCount += batch.length;
        }
      }

      return SettingsOperationResult.success(
        message: 'Foods import completed',
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } else {
      return SettingsOperationResult.error(
        message: 'No valid food items found to import',
      );
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
