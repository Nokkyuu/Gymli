/**
 * Database Service for Workout Data Operations
 * 
 * This service provides database-like operations for managing workout data
 * including exercises, training sets, and workout statistics. It acts as
 * an abstraction layer between the UI and the underlying data storage.
 * 
 * Key functions:
 * - Exercise data retrieval and management
 * - Training set queries and filtering
 * - Statistical calculations (1RM, volume analysis)
 * - Date-based data filtering for progress tracking
 * - Data aggregation for workout insights
 * 
 * The service integrates with UserService for data persistence and
 * provides specialized query functions for the fitness tracking features.
 */

// ignore_for_file: non_constant_identifier_names
library my_prj.database;

import 'package:tuple/tuple.dart';
import 'package:intl/intl.dart';
import 'user_service.dart';
import 'api_models.dart';

Future<ApiExercise?> get_exercise(String exerciseName) async {
  try {
    final userService = UserService();
    final exercises = await userService.getExercises();
    final exerciseData = exercises.firstWhere(
      (item) => item['name'] == exerciseName,
      orElse: () => null,
    );

    if (exerciseData != null) {
      return ApiExercise.fromJson(exerciseData);
    }
    return null;
  } catch (e) {
    print('Error getting exercise: $e');
    return null;
  }
}

Future<List<ApiTrainingSet>> getExerciseTrainings(String exercise) async {
  try {
    final userService = UserService();
    final trainingSets = await userService.getTrainingSets();

    return trainingSets
        .where((item) =>
            item['exercise_name'] == exercise ||
            (item['exercise_name'] == null &&
                _getExerciseNameFromId(item['exercise_id']) == exercise))
        .map((item) => ApiTrainingSet.fromJson({
              ...item,
              'exercise_name': item['exercise_name'] ?? exercise,
            }))
        .toList();
  } catch (e) {
    print('Error getting exercise trainings: $e');
    return [];
  }
}

Future<List<ApiTrainingSet>> getTrainings(DateTime day) async {
  try {
    final userService = UserService();
    final trainingSets = await userService.getTrainingSets();

    return trainingSets
        .where((item) {
          final itemDate = DateTime.parse(item['date']);
          return itemDate.day == day.day &&
              itemDate.month == day.month &&
              itemDate.year == day.year;
        })
        .map((item) => ApiTrainingSet.fromJson({
              ...item,
              'exercise_name': item['exercise_name'] ?? '',
            }))
        .toList();
  } catch (e) {
    print('Error getting trainings for day: $e');
    return [];
  }
}

Future<List<DateTime>> getTrainingDates(String exercise) async {
  try {
    final userService = UserService();
    final trainingSets = await userService.getTrainingSets();

    var filteredSets = trainingSets;
    if (exercise.isNotEmpty) {
      filteredSets = trainingSets
          .where((item) =>
              (item['exercise_name'] == exercise ||
                  _getExerciseNameFromId(item['exercise_id']) == exercise) &&
              item['set_type'] > 0)
          .toList();
    }

    final dates = filteredSets
        .map((e) => DateFormat('yyyy-MM-dd').format(DateTime.parse(e['date'])))
        .toSet()
        .toList();

    dates.sort((a, b) => a.compareTo(b));

    return dates.map((d) => DateFormat('yyyy-MM-dd').parse(d)).toList();
  } catch (e) {
    print('Error getting training dates: $e');
    return [];
  }
}

Future<DateTime> getLastTrainingDay(String exercise) async {
  final trainingDates = await getTrainingDates(exercise);
  if (trainingDates.isEmpty) {
    return DateTime.now();
  }

  // Find the most recent training date (closest to today but in the past)
  trainingDates
      .sort((a, b) => b.compareTo(a)); // Sort descending (most recent first)
  return trainingDates.first;
}

// Optimized batch function to get last training days for multiple exercises
// Now uses dedicated API endpoint for better performance
Future<Map<String, DateTime>> getLastTrainingDaysForExercises(
    List<String> exerciseNames) async {
  try {
    final userService = UserService();

    // Use the new optimized endpoint that gets all last training dates at once
    final allLastDates = await userService.getLastTrainingDatesPerExercise();

    Map<String, DateTime> result = {};
    final now = DateTime.now();

    for (String exerciseName in exerciseNames) {
      // Check if we have a last training date for this exercise
      if (allLastDates.containsKey(exerciseName)) {
        result[exerciseName] = allLastDates[exerciseName]!;
      } else {
        // Fallback to current date if no training data exists
        result[exerciseName] = now;
      }
    }

    return result;
  } catch (e) {
    print('Error getting last training days for exercises: $e');
    // Return fallback dates for all exercises
    Map<String, DateTime> fallback = {};
    for (String exerciseName in exerciseNames) {
      fallback[exerciseName] = DateTime.now();
    }
    return fallback;
  }
}

Future<Tuple2<double, int>> getLastTrainingInfo(String exercise) async {
  try {
    final trainings = await getExerciseTrainings(exercise);
    final trainingDates = await getTrainingDates(exercise);

    if (trainingDates.isEmpty) {
      return const Tuple2<double, int>(20.0, 10);
    }

    final d = await getLastTrainingDay(exercise);
    final latestTrainings = trainings.where((item) =>
        item.date.day == d.day &&
        item.date.month == d.month &&
        item.date.year == d.year);

    var bestWeight = -100.0;
    var bestReps = 1;
    for (var s in latestTrainings) {
      if (s.weight > bestWeight) {
        bestWeight = s.weight;
        bestReps = s.repetitions;
      }
    }
    return Tuple2<double, int>(bestWeight, bestReps);
  } catch (e) {
    print('Error getting last training info: $e');
    return const Tuple2<double, int>(20.0, 10);
  }
}

// Helper function to get exercise name from ID
// This would need to be implemented based on your exercise data structure
String _getExerciseNameFromId(int exerciseId) {
  // TODO: Implement this by looking up exercise name from ID
  // For now, return empty string as fallback
  return '';
}
