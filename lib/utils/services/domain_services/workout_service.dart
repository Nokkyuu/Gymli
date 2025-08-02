import '../../api/api.dart' as api;
import '../data_service.dart';
import 'exercise_service.dart';

class WorkoutService {
  final DataService _dataService = DataService();
  final ExerciseService _exerciseService = ExerciseService();

  // Getters that delegate to DataService
  bool get isLoggedIn => _dataService.isLoggedIn;
  String get userName => _dataService.userName;

  Future<List<dynamic>> getWorkouts() async {
    final workouts = await _dataService.getData(
      'workouts',
      // API call for authenticated users
      () async => await api.WorkoutService().getWorkouts(userName: userName),
      // Fallback API call for non-authenticated users
      () async =>
          await api.WorkoutService().getWorkouts(userName: 'DefaultUser'),
    );

    // Enrich workouts with workout units for display
    return await _enrichWorkoutsWithUnits(workouts);
  }

  // Enhanced createWorkout method that handles units (matching deprecated UserService exactly)
  Future<Map<String, dynamic>> createWorkout({
    required String name,
    required List<Map<String, dynamic>> units,
  }) async {
    if (isLoggedIn) {
      // Create the workout first and get its data (including ID)
      final workoutData = await api.WorkoutService()
          .createWorkout(userName: userName, name: name);
      final workoutId = workoutData['id'] as int;

      // Now create all the workout units
      for (final unit in units) {
        await createWorkoutUnit(
          workoutId: workoutId,
          exerciseId: unit['exercise_id'],
          warmups: unit['warmups'],
          worksets: unit['worksets'],
          dropsets: unit['dropsets'],
          type: unit['type'],
        );
      }

      return workoutData;
    } else {
      final workoutId = DateTime.now().millisecondsSinceEpoch;
      final workout = {
        'id': workoutId,
        'user_name': 'DefaultUser',
        'name': name,
        'units': units,
      };
      _dataService.addToInMemoryData('workouts', workout);

      // For offline mode, also add individual workout units to workoutUnits list
      for (final unit in units) {
        final workoutUnit = {
          'id': DateTime.now().millisecondsSinceEpoch + units.indexOf(unit),
          'user_name': 'DefaultUser',
          'workout_id': workoutId,
          'exercise_id': unit['exercise_id'],
          'warmups': unit['warmups'],
          'worksets': unit['worksets'],
          'dropsets': unit['dropsets'],
          'type': unit['type'],
        };
        _dataService.addToInMemoryData('workoutUnits', workoutUnit);
      }

      return workout;
    }
  }

  Future<void> updateWorkout(int id, Map<String, dynamic> data) async {
    await _dataService.updateData(
      'workouts',
      id,
      data,
      () async => await api.WorkoutService().updateWorkout(id, data),
    );
  }

  Future<void> deleteWorkout(int id) async {
    await _dataService.deleteData(
      'workouts',
      id,
      () async => await api.WorkoutService().deleteWorkout(id),
    );
  }

  // Workout Unit methods (merged from WorkoutUnitService)
  Future<void> createWorkoutUnit({
    required int workoutId,
    required int exerciseId,
    required int warmups,
    required int worksets,
    required int dropsets,
    required int type,
  }) async {
    if (isLoggedIn) {
      await api.WorkoutUnitService().createWorkoutUnit(
        userName: userName,
        workoutId: workoutId,
        exerciseId: exerciseId,
        warmups: warmups,
        worksets: worksets,
        dropsets: dropsets,
        type: type,
      );
    } else {
      final workoutUnit = {
        'id': _dataService.generateFakeId('workoutUnits'),
        'user_name': 'DefaultUser',
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'warmups': warmups,
        'worksets': worksets,
        'dropsets': dropsets,
        'type': type,
      };
      _dataService.addToInMemoryData('workoutUnits', workoutUnit);
    }
  }

  Future<void> updateWorkoutUnit(int id, Map<String, dynamic> data) async {
    await _dataService.updateData(
      'workoutUnits',
      id,
      data,
      () async => await api.WorkoutUnitService().updateWorkoutUnit(id, data),
    );
  }

  Future<void> deleteWorkoutUnit(int id) async {
    await _dataService.deleteData(
      'workoutUnits',
      id,
      () async => await api.WorkoutUnitService().deleteWorkoutUnit(id),
    );
  }

  Future<List<dynamic>> getWorkoutUnits() async {
    final workoutUnits = await _dataService.getData(
      'workoutUnits',
      () async =>
          await api.WorkoutUnitService().getWorkoutUnits(userName: userName),
      () async => await api.WorkoutUnitService()
          .getWorkoutUnits(userName: 'DefaultUser'),
    );

    return await _enrichWorkoutUnitsWithExerciseNames(workoutUnits);
  }

  // Private method to enrich workouts with their associated workout units (matches deprecated UserService exactly)
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

  // Helper method to enrich workout units with exercise names (matches deprecated UserService exactly)
  Future<List<dynamic>> _enrichWorkoutUnitsWithExerciseNames(
      List<dynamic> workoutUnits) async {
    try {
      // Get all exercises to create a mapping from ID to name
      final exercises = await _exerciseService.getExercises();
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

  // Clear method for settings screen (matches deprecated UserService exactly)
  Future<void> clearWorkouts() async {
    if (isLoggedIn) {
      // Get all workouts for this user and delete them
      final workouts =
          await _getWorkoutsRaw(); // Get raw workouts without enrichment for efficiency
      int deletedCount = 0;
      int errorCount = 0;

      for (var workout in workouts) {
        if (workout['id'] != null) {
          try {
            await deleteWorkout(workout['id']);
            deletedCount++;
          } catch (e) {
            errorCount++;
            print('Warning: Failed to delete workout ${workout['id']}: $e');
            // Continue with other workouts instead of stopping
          }
        }
      }
      print('Cleared workouts: $deletedCount deleted, $errorCount errors');
    } else {
      // Clear in-memory workouts and clear DefaultUser from API
      _dataService.clearSpecificInMemoryData('workouts');
      try {
        final defaultWorkouts =
            await api.WorkoutService().getWorkouts(userName: 'DefaultUser');
        int deletedCount = 0;
        int errorCount = 0;

        for (var workout in defaultWorkouts) {
          if (workout['id'] != null) {
            try {
              await api.WorkoutService().deleteWorkout(workout['id']);
              deletedCount++;
            } catch (e) {
              errorCount++;
              print(
                  'Warning: Failed to delete DefaultUser workout ${workout['id']}: $e');
              // Continue with other workouts instead of stopping
            }
          }
        }
        // Clear in-memory workouts regardless of API success
        _dataService.clearSpecificInMemoryData('workouts');
        print(
            'Cleared DefaultUser workouts: $deletedCount deleted, $errorCount errors');
      } catch (e) {
        print('Error accessing DefaultUser workouts: $e');
        // Continue anyway - we still cleared in-memory data
      }
    }
  }

  // Helper method to get raw workouts without enrichment
  Future<List<dynamic>> _getWorkoutsRaw() async {
    return await _dataService.getData(
      'workouts',
      // API call for authenticated users
      () async => await api.WorkoutService().getWorkouts(userName: userName),
      // Fallback API call for non-authenticated users
      () async =>
          await api.WorkoutService().getWorkouts(userName: 'DefaultUser'),
    );
  }

  // Helper method to get raw workout units data (used internally)
  Future<List<dynamic>> _getWorkoutUnitsRaw() async {
    return await _dataService.getData(
      'workoutUnits',
      // API call for authenticated users
      () async =>
          await api.WorkoutUnitService().getWorkoutUnits(userName: userName),
      // Fallback API call for non-authenticated users
      () async => await api.WorkoutUnitService()
          .getWorkoutUnits(userName: 'DefaultUser'),
    );
  }
}
