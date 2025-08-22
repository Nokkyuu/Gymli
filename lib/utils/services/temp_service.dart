library;

import 'package:Gymli/utils/api/api_export.dart';
import 'package:get_it/get_it.dart';

// Class is for temporary convenience and non-existent endpoint compensation

class TempService {
  TempService();

  Future<Map<String, Map<String, dynamic>>> getLastTrainingDatesPerExercise(
      List<String> exerciseNames) async {
    //TODO:Integrate into TrainingSetService
    final lastDates =
        await GetIt.I<TrainingSetService>().getLastTrainingDatesPerExercise();

    Map<String, Map<String, dynamic>> result = {};

    for (String exerciseName in exerciseNames) {
      final dateString = lastDates[exerciseName];
      DateTime lastTrainingDate;

      if (dateString != null) {
        try {
          lastTrainingDate = DateTime.parse(dateString);
        } catch (e) {
          lastTrainingDate = DateTime.now();
        }
      } else {
        lastTrainingDate = DateTime.now();
      }

      result[exerciseName] = {
        'lastTrainingDate': lastTrainingDate,
      };
    }
    return result;
  }

  //TODO: replace the getTrainingSetsByID calls with direct calls to getTrainingSetsForExercise
  Future<List<dynamic>> getTrainingSetsByExerciseID(int exerciseId) async {
    return await GetIt.I<TrainingSetService>()
        .getTrainingSetsByExerciseID(exerciseId: exerciseId);
  }

  Future<int?> getExerciseIdByName(String exerciseName) async {
    try {
      final exerciseService = GetIt.I<ExerciseService>();
      final exercises = await exerciseService.getExercises();
      final exerciseData =
          exercises.firstWhere((item) => item.name == exerciseName);
      return exerciseData?.id;
    } catch (e) {
      print('Error resolving exercise name to ID: $e');
      return null;
    }
  }

  // Calendar convenience methods
  Future<Map<String, dynamic>> getCalendarDataForDate(DateTime date) async {
    //TODO: create specialized endpoints or use cache?
    final dateString =
        date.toIso8601String().split('T')[0]; // Get YYYY-MM-DD format

    final notes = await GetIt.I<CalendarService>().getCalendarNotes();
    final workouts = await GetIt.I<CalendarService>().getCalendarWorkouts();
    final periods = await GetIt.I<CalendarService>().getCalendarPeriods();

    // Filter by date
    final notesForDate = notes.where((note) {
      final noteDate =
          DateTime.parse(note['date']).toIso8601String().split('T')[0];
      return noteDate == dateString;
    }).toList();

    final workoutsForDate = workouts.where((workout) {
      final workoutDate =
          DateTime.parse(workout['date']).toIso8601String().split('T')[0];
      return workoutDate == dateString;
    }).toList();

    final periodsForDate = periods.where((period) {
      final startDate = DateTime.parse(period['start_date']);
      final endDate = DateTime.parse(period['end_date']);
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    return {
      'notes': notesForDate,
      'workouts': workoutsForDate,
      'periods': periodsForDate,
    };
  }

  Future<Map<String, dynamic>> getCalendarDataForRange({
    //TODO: create specialized endpoints or use cache?
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final notes = await GetIt.I<CalendarService>().getCalendarNotes();
    final workouts = await GetIt.I<CalendarService>().getCalendarWorkouts();
    final periods = await GetIt.I<CalendarService>().getCalendarPeriods();

    // Filter by date range
    final notesInRange = notes.where((note) {
      final noteDate = DateTime.parse(note['date']);
      return noteDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          noteDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final workoutsInRange = workouts.where((workout) {
      final workoutDate = DateTime.parse(workout['date']);
      return workoutDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          workoutDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final periodsInRange = periods.where((period) {
      final periodStartDate = DateTime.parse(period['start_date']);
      final periodEndDate = DateTime.parse(period['end_date']);
      // Include periods that overlap with the range
      return periodStartDate.isBefore(endDate.add(const Duration(days: 1))) &&
          periodEndDate.isAfter(startDate.subtract(const Duration(days: 1)));
    }).toList();

    return {
      'notes': notesInRange,
      'workouts': workoutsInRange,
      'periods': periodsInRange,
    };
  }

  // Nutrition stats helper methods
  Future<Map<String, double>> getFoodLogStats({
    //TODO: keep the calculation here or integrate somewhere into the food screen controller/services
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await GetIt.I<FoodService>().getFoodLogs(
      startDate: startDate,
      endDate: endDate,
    );

    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;

    for (var log in logs) {
      final grams = (log['grams'] as num).toDouble();
      final kcalPer100g = (log['kcal_per_100g'] as num).toDouble();
      final proteinPer100g = (log['protein_per_100g'] as num).toDouble();
      final carbsPer100g = (log['carbs_per_100g'] as num).toDouble();
      final fatPer100g = (log['fat_per_100g'] as num).toDouble();

      final multiplier = grams / 100.0;
      totalCalories += kcalPer100g * multiplier;
      totalProtein += proteinPer100g * multiplier;
      totalCarbs += carbsPer100g * multiplier;
      totalFat += fatPer100g * multiplier;
    }

    return {
      'total_calories': double.parse(totalCalories.toStringAsFixed(1)),
      'total_protein': double.parse(totalProtein.toStringAsFixed(1)),
      'total_carbs': double.parse(totalCarbs.toStringAsFixed(1)),
      'total_fat': double.parse(totalFat.toStringAsFixed(1)),
    };
  }

  Future<List<Map<String, dynamic>>> getDailyFoodLogStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await GetIt.I<FoodService>().getFoodLogs(
      startDate: startDate,
      endDate: endDate,
    );

    // Group logs by date
    Map<String, Map<String, double>> dailyStats = {};

    for (var log in logs) {
      final dateString = log['date'] as String;
      final date = DateTime.parse(dateString);
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final grams = (log['grams'] as num).toDouble();
      final kcalPer100g = (log['kcal_per_100g'] as num).toDouble();
      final proteinPer100g = (log['protein_per_100g'] as num).toDouble();
      final carbsPer100g = (log['carbs_per_100g'] as num).toDouble();
      final fatPer100g = (log['fat_per_100g'] as num).toDouble();

      final multiplier = grams / 100.0;
      final calories = kcalPer100g * multiplier;
      final protein = proteinPer100g * multiplier;
      final carbs = carbsPer100g * multiplier;
      final fat = fatPer100g * multiplier;

      if (!dailyStats.containsKey(dateKey)) {
        dailyStats[dateKey] = {
          'calories': 0.0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
        };
      }

      dailyStats[dateKey]!['calories'] =
          dailyStats[dateKey]!['calories']! + calories;
      dailyStats[dateKey]!['protein'] =
          dailyStats[dateKey]!['protein']! + protein;
      dailyStats[dateKey]!['carbs'] = dailyStats[dateKey]!['carbs']! + carbs;
      dailyStats[dateKey]!['fat'] = dailyStats[dateKey]!['fat']! + fat;
    }

    // Convert to list format and fill in missing dates
    List<Map<String, dynamic>> result = [];

    if (startDate != null && endDate != null) {
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final dateKey =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

        result.add({
          'date': dateKey,
          'calories': dailyStats[dateKey]?['calories'] ?? 0.0,
          'protein': dailyStats[dateKey]?['protein'] ?? 0.0,
          'carbs': dailyStats[dateKey]?['carbs'] ?? 0.0,
          'fat': dailyStats[dateKey]?['fat'] ?? 0.0,
        });

        currentDate = currentDate.add(const Duration(days: 1));
      }
    } else {
      // If no date range specified, just return the days we have data for
      for (var entry in dailyStats.entries) {
        result.add({
          'date': entry.key,
          'calories': entry.value['calories'],
          'protein': entry.value['protein'],
          'carbs': entry.value['carbs'],
          'fat': entry.value['fat'],
        });
      }
      // Sort by date
      result.sort((a, b) => a['date'].compareTo(b['date']));
    }

    return result;
  }

  Future<void> clearWorkouts() async {
    // Get all workouts for this user and delete them
    final workouts = await GetIt.I<WorkoutService>()
        .getWorkouts(); // Get raw workouts without enrichment for efficiency
    int deletedCount = 0;
    int errorCount = 0;

    for (var workout in workouts) {
      if (workout.id != null) {
        try {
          await GetIt.I<WorkoutService>().deleteWorkout(workout.id!);
          deletedCount++;
        } catch (e) {
          errorCount++;
          print('Warning: Failed to delete workout ${workout.id}: $e');
          // Continue with other workouts instead of stopping
        }
      }
    }
    print('Cleared workouts: $deletedCount deleted, $errorCount errors');
  }

  Future<void> clearExercises() async {
    // Get all exercises for this user and delete them
    final exerciseService = GetIt.I<ExerciseService>();
    final exercises = await exerciseService.getExercises();
    int deletedCount = 0;
    int errorCount = 0;

    for (var exercise in exercises) {
      if (exercise.id != null) {
        try {
          await exerciseService.deleteExercise(exercise.id!);
          deletedCount++;
        } catch (e) {
          errorCount++;
          print('Warning: Failed to delete exercise ${exercise!.id}: $e');
          // Continue with other exercises instead of stopping
        }
      }
    }
    print('Cleared exercises: $deletedCount deleted, $errorCount errors');
  }
}
