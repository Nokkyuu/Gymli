/// CSV Service - Handles CSV parsing and generation
library;

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../../../utils/models/data_models.dart';

class CsvService {
  static const ListToCsvConverter _csvConverter = ListToCsvConverter(
    eol: '\n',
    fieldDelimiter: ';',
    textDelimiter: '"',
    textEndDelimiter: '"',
  );

  static const CsvToListConverter _csvParser = CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
    fieldDelimiter: ';',
    textDelimiter: '"',
    textEndDelimiter: '"',
  );

  /// Generate CSV data for training sets
  static String generateTrainingSetsCSV(List<dynamic> trainingSets) {
    List<List<String>> datalist = [];

    for (var ts in trainingSets) {
      try {
        final apiTrainingSet = TrainingSet.fromJson(ts);
        datalist.add(apiTrainingSet.toCSVString());
      } catch (e) {
        if (kDebugMode) print('Error converting training set to CSV: $e');
      }
    }

    return _convertToCSV(datalist);
  }

  /// Generate CSV data for exercises
  static String generateExercisesCSV(List<dynamic> exercises) {
    List<List<String>> datalist = [];

    for (var ex in exercises) {
      try {
        final apiExercise = Exercise.fromJson(ex);
        datalist.add(apiExercise.toCSVString());
      } catch (e) {
        if (kDebugMode) print('Error converting exercise to CSV: $e');
      }
    }

    return _convertToCSV(datalist);
  }

  /// Generate CSV data for workouts
  static String generateWorkoutsCSV(List<dynamic> workouts) {
    List<List<String>> datalist = [];

    for (var wo in workouts) {
      try {
        final apiWorkout = Workout.fromJson(wo);
        datalist.add(apiWorkout.toCSVString());
      } catch (e) {
        if (kDebugMode) print('Error converting workout to CSV: $e');
      }
    }

    return _convertToCSV(datalist);
  }

  /// Generate CSV data for foods
  static String generateFoodsCSV(List<dynamic> foods) {
    List<List<String>> datalist = [];

    for (var food in foods) {
      try {
        final apiFood = FoodItem.fromJson(food);
        datalist.add(apiFood.toCSVString());
      } catch (e) {
        if (kDebugMode) print('Error converting food to CSV: $e');
      }
    }

    return _convertToCSV(datalist);
  }

  /// Parse CSV data into list of rows
  static List<List<String>> parseCSV(String csvData) {
    try {
      return _csvParser.convert(csvData);
    } catch (e) {
      if (kDebugMode) print('Error parsing CSV: $e');
      rethrow;
    }
  }

  /// Convert data list to CSV string
  static String _convertToCSV(List<List<String>> datalist) {
    if (datalist.isEmpty) return '';

    String csvData = _csvConverter.convert(datalist);

    // Ensure the CSV ends with a newline
    if (!csvData.endsWith('\n')) {
      csvData += '\n';
    }

    return csvData;
  }

  /// Parse muscle groups from CSV format
  static List<String> parseCSVMuscleGroups(String input) {
    if (input.isEmpty || input.trim().isEmpty) {
      return <String>[];
    }

    String cleaned = input.replaceAll('[', '').replaceAll(']', '').trim();
    if (cleaned.isEmpty) {
      return <String>[];
    }

    return cleaned
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Parse muscle intensities from CSV format
  static List<double> parseCSVMuscleIntensities(String input) {
    if (input.isEmpty || input.trim().isEmpty) {
      return <double>[];
    }

    String cleaned = input.replaceAll('[', '').replaceAll(']', '').trim();
    if (cleaned.isEmpty) {
      return <double>[];
    }

    return cleaned
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => double.tryParse(e) ?? 0.0)
        .toList();
  }
}
