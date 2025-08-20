/// TempService is a singleton that manages all services in the application.
/// Replacement for the deprecated UserService.
/// please see the seperate service files for more details on each service.
library;

import 'auth_service.dart';
import 'package:Gymli/utils/api/api.dart';
import 'package:Gymli/utils/api/api_models.dart';

String userName = 'DefaultUser';

class TempService {
  /// Singleton instance for TempService
  // Core services
  late final AuthService authService;

  // Domain services
  late final ExerciseService exerciseService;
  late final WorkoutService workoutService;
  late final TrainingSetService trainingSetService;
  late final ActivityService activityService;
  late final FoodService foodService;
  late final CalendarService calendarService;
  late final WorkoutUnitService workoutUnitService;

  void _setupServices() {
    // Initialize core services first
    authService = AuthService();

    // Initialize domain services (they depend on core services)
    exerciseService = ExerciseService();
    workoutService = WorkoutService();
    trainingSetService = TrainingSetService();
    activityService = ActivityService();
    foodService = FoodService();
    calendarService = CalendarService();
    workoutUnitService = WorkoutUnitService();
  }

  // Convenience getters for common operations
  //TODO: mostly not needed anymore?
  bool get isLoggedIn => authService.isLoggedIn;
  String get userName => authService.userName;
  String get userEmail => authService.userEmail;

  // Initialize all services (call this at app startup)
  Future<void> initialize() async {
    await authService.initializeAuth();
  }

  // Notification method for data changes
  void notifyDataChanged() {
    authService.notifyAuthStateChanged();
  }

  //replace calls in files, unecessary redundancy
  Future<List<Map<String, dynamic>>> createTrainingSetsBulk(
    List<Map<String, dynamic>> trainingSets,
  ) async {
    return await trainingSetService.createTrainingSetsBulk(
        trainingSets: trainingSets);
  }

  //replace calls in files, unecessary redundancy
  Future<List<Map<String, dynamic>>> createFoodsBulk(
    List<Map<String, dynamic>> foods,
  ) async {
    return await foodService.createFoodsBulk(foods: foods);
  }

  // Analytics helper methods
  //TODO: replace getLastTrainingDatesPerExercise() calls with getLastTrainingDatesPerExercise calls directly
  Future<Map<String, Map<String, dynamic>>> getLastTrainingDatesPerExercise(
      List<String> exerciseNames) async {
    final lastDates =
        await trainingSetService.getLastTrainingDatesPerExercise();

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
        // Note: API endpoint doesn't provide highest weight,
        // you might need to extend the API or make a separate call
        'highestWeight': 0.0,
      };
    }

    return result;
  }

  //TODO: replace the getTrainingSetsByID calls with direct calls to getTrainingSetsForExercise
  Future<List<dynamic>> getTrainingSetsByExerciseID(int exerciseId) async {
    return await trainingSetService.getTrainingSetsByExerciseID(
        exerciseId: exerciseId);
  }

  Future<int?> getExerciseIdByName(String exerciseName) async {
    try {
      final exercises = await exerciseService.getExercises();
      final exerciseData = exercises.firstWhere(
        (item) => item['name'] == exerciseName,
        orElse: () => null,
      );
      return exerciseData?['id'];
    } catch (e) {
      print('Error resolving exercise name to ID: $e');
      return null;
    }
  }

  Future<String?> getExerciseNameById(int exerciseId) async {
    return await exerciseService.getExerciseById(exerciseId).then((exercise) {
      return exercise['name'];
    });
  }

  // Calendar convenience methods
  Future<Map<String, dynamic>> getCalendarDataForDate(DateTime date) async {
    //TODO: create specialized endpoints or use cache?
    final dateString =
        date.toIso8601String().split('T')[0]; // Get YYYY-MM-DD format

    final notes = await calendarService.getCalendarNotes();
    final workouts = await calendarService.getCalendarWorkouts();
    final periods = await calendarService.getCalendarPeriods();

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
    final notes = await calendarService.getCalendarNotes();
    final workouts = await calendarService.getCalendarWorkouts();
    final periods = await calendarService.getCalendarPeriods();

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
    final logs = await foodService.getFoodLogs(
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
    final logs = await foodService.getFoodLogs(
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
    final workouts = await workoutService
        .getWorkouts(); // Get raw workouts without enrichment for efficiency
    int deletedCount = 0;
    int errorCount = 0;

    for (var workout in workouts) {
      if (workout['id'] != null) {
        try {
          await workoutService.deleteWorkout(workout['id']);
          deletedCount++;
        } catch (e) {
          errorCount++;
          print('Warning: Failed to delete workout ${workout['id']}: $e');
          // Continue with other workouts instead of stopping
        }
      }
    }
    print('Cleared workouts: $deletedCount deleted, $errorCount errors');
  }

  Future<void> clearExercises() async {
    // Get all exercises for this user and delete them
    final exercises = await exerciseService.getExercises();
    int deletedCount = 0;
    int errorCount = 0;

    for (var exercise in exercises) {
      if (exercise['id'] != null) {
        try {
          await exerciseService.deleteExercise(exercise['id']);
          deletedCount++;
        } catch (e) {
          errorCount++;
          print('Warning: Failed to delete exercise ${exercise['id']}: $e');
          // Continue with other exercises instead of stopping
        }
      }
    }
    print('Cleared exercises: $deletedCount deleted, $errorCount errors');
  }

  ///Use this instead of workoutService.createWorkout - to connect units and workout name
  Future<Map<String, dynamic>> createWorkout({
    required String name,
    required List<Map<String, dynamic>> units,
  }) async {
    // Create the workout first and get its data (including ID)
    final workoutData = await workoutService.createWorkout(name: name);
    final workoutId = workoutData['id'] as int;

    // Now create all the workout units
    for (final unit in units) {
      await workoutUnitService.createWorkoutUnit(
        workoutId: workoutId,
        exerciseId: unit['exercise_id'],
        warmups: unit['warmups'],
        worksets: unit['worksets'],
        dropsets: unit['dropsets'],
        type: unit['type'],
      );
    }

    return workoutData;
  }

  Future<List<dynamic>> getWorkouts() async {
    final workouts = await workoutService.getWorkouts();
// Enrich workouts with workout units for display
    return await _enrichWorkoutsWithUnits(workouts);
  }

  Future<List<dynamic>> _enrichWorkoutsWithUnits(List<dynamic> workouts) async {
    try {
      // Get all workout units for this user
      final allWorkoutUnits = await getWorkoutUnits();

      // Group workout units by workout_id
      final Map<int, List<dynamic>> unitsByWorkoutId = {};
      for (var workoutUnit in allWorkoutUnits) {
        final workoutId = workoutUnit['workout_id'] as int?;
        if (workoutId != null) {
          unitsByWorkoutId.putIfAbsent(workoutId, () => []);
          unitsByWorkoutId[workoutId]!.add(workoutUnit);
        }
      }

      // Enrich each workout with its units using Future.wait for async operations
      final List<Future<Map<String, dynamic>>> enrichmentFutures =
          workouts.map((workout) async {
        try {
          final Map<String, dynamic> workoutMap;
          if (workout is Map<String, dynamic>) {
            workoutMap = Map<String, dynamic>.from(workout);
          } else {
            workoutMap = Map<String, dynamic>.from(workout as Map);
          }

          final workoutId = workoutMap['id'] as int?;

          // Check if workout already has units (offline mode)
          if (workoutMap.containsKey('units') &&
              workoutMap['units'] is List &&
              (workoutMap['units'] as List).isNotEmpty) {
            print(
                'DEBUG: Workout ${workoutMap['name']} already has ${(workoutMap['units'] as List).length} units, keeping them');
            // Keep existing units but make sure they're enriched with exercise names
            final existingUnits = workoutMap['units'] as List;
            final enrichedUnits =
                await _enrichWorkoutUnitsWithExerciseNames(existingUnits);
            workoutMap['units'] = enrichedUnits;
          } else if (workoutId != null) {
            // Fetch units from workout units collection (online mode)
            final units = unitsByWorkoutId[workoutId] ?? [];
            workoutMap['units'] = units;
          } else {
            workoutMap['units'] = [];
          }

          return workoutMap;
        } catch (e) {
          print('Error enriching workout with units: $e');
          // Return the original workout with empty units
          final Map<String, dynamic> fallbackMap;
          if (workout is Map<String, dynamic>) {
            fallbackMap = Map<String, dynamic>.from(workout);
          } else {
            fallbackMap = Map<String, dynamic>.from(workout as Map);
          }
          fallbackMap['units'] = [];
          return fallbackMap;
        }
      }).toList();

      // Wait for all enrichment operations to complete
      return await Future.wait(enrichmentFutures);
    } catch (e) {
      print('Error in _enrichWorkoutsWithUnits: $e');
      // Return original workouts with empty units arrays
      return workouts.map((workout) {
        try {
          final Map<String, dynamic> workoutMap;
          if (workout is Map<String, dynamic>) {
            workoutMap = Map<String, dynamic>.from(workout);
          } else {
            workoutMap = Map<String, dynamic>.from(workout as Map);
          }
          workoutMap['units'] = [];
          return workoutMap;
        } catch (conversionError) {
          print(
              'Error converting workout to Map in fallback: $conversionError');
          return workout;
        }
      }).toList();
    }
  }

  Future<List<dynamic>> getWorkoutUnits() async {
    final workoutUnits = await workoutUnitService.getWorkoutUnits();
    return await _enrichWorkoutUnitsWithExerciseNames(workoutUnits);
  }

  Future<List<dynamic>> _enrichWorkoutUnitsWithExerciseNames(
      List<dynamic> workoutUnits) async {
    try {
      // Get all exercises to create a mapping from ID to name
      final exercises = await exerciseService.getExercises();
      final Map<int, String> exerciseIdToName = {};

      for (var exerciseData in exercises) {
        try {
          // Handle both Map and LinkedMap types
          final Map<String, dynamic> exerciseMap;
          if (exerciseData is Map<String, dynamic>) {
            exerciseMap = exerciseData;
          } else {
            exerciseMap = Map<String, dynamic>.from(exerciseData as Map);
          }

          final exerciseId = exerciseMap['id'] as int?;
          final exerciseName = exerciseMap['name'] as String?;
          if (exerciseId != null && exerciseName != null) {
            exerciseIdToName[exerciseId] = exerciseName;
          }
        } catch (e) {
          print('Error parsing exercise data in workout units: $e');
        }
      }

      // Add exercise_name field to each workout unit
      return workoutUnits.map((workoutUnit) {
        try {
          // Handle both Map and LinkedMap types
          final Map<String, dynamic> workoutUnitMap;
          if (workoutUnit is Map<String, dynamic>) {
            workoutUnitMap = Map<String, dynamic>.from(workoutUnit);
          } else {
            workoutUnitMap = Map<String, dynamic>.from(workoutUnit as Map);
          }

          final exerciseId = workoutUnitMap['exercise_id'] as int?;
          if (exerciseId != null) {
            final exerciseName =
                exerciseIdToName[exerciseId] ?? 'Unknown Exercise';
            workoutUnitMap['exercise_name'] = exerciseName;
          }

          return workoutUnitMap;
        } catch (e) {
          print('Error enriching workout unit: $e');
          // Return the original workout unit converted to proper Map if enrichment fails
          try {
            if (workoutUnit is Map<String, dynamic>) {
              return Map<String, dynamic>.from(workoutUnit);
            } else {
              return Map<String, dynamic>.from(workoutUnit as Map);
            }
          } catch (conversionError) {
            print('Error converting workout unit to Map: $conversionError');
            return workoutUnit;
          }
        }
      }).toList();
    } catch (e) {
      print('Error in _enrichWorkoutUnitsWithExerciseNames: $e');
      // Return original workout units converted to proper Maps if enrichment completely fails
      return workoutUnits.map((wu) {
        try {
          if (wu is Map<String, dynamic>) {
            return Map<String, dynamic>.from(wu);
          } else {
            return Map<String, dynamic>.from(wu as Map);
          }
        } catch (conversionError) {
          print(
              'Error converting workout unit to Map in fallback: $conversionError');
          return wu;
        }
      }).toList();
    }
  }
}
