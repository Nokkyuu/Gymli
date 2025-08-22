/// WorkoutService and WorkoutUnitService - Manages workout templates and workout units
///
/// This service handles all CRUD operations for workouts and workout units.
/// Workouts are templates for user training sessions, and workout units link
/// exercises to workouts and define their order and type within the workout.
///
library;

import 'dart:convert';
import 'api_base.dart';
import '../models/data_models.dart';
import 'package:get_it/get_it.dart';
//----------------- Workout Service -----------------//

class WorkoutService {
  /// Retrieves all workouts for a user
  /// Returns a list of workout objects
  ///
  Future<List<ApiWorkout>> getWorkouts() async {
    final raw = await getData<List<dynamic>>('workouts');
    final workouts = raw.map((e) => ApiWorkout.fromJson(e)).toList();
// Enrich workouts with workout units for display
    return await _enrichWorkoutsWithUnits(workouts);
  }

  Future<List<ApiWorkout>> _enrichWorkoutsWithUnits(
      List<ApiWorkout> workouts) async {
    final unitsByWorkoutId = <int, List<ApiWorkoutUnit>>{};
    final workoutUnits = await GetIt.I<WorkoutUnitService>().getWorkoutUnits();

    // Group workout units by workout_id
    for (var unit in workoutUnits) {
      unitsByWorkoutId.putIfAbsent(unit.workoutId, () => []).add(unit);
    }

    // Enrich each workout with its units
    for (var workout in workouts) {
      final workoutId = workout.id;
      workout.units = unitsByWorkoutId[workoutId] ?? [];
    }

    return workouts;
  }

  Future<Map<String, dynamic>> getWorkoutById(int id) async {
    return getData<Map<String, dynamic>>('workouts/$id');
  }

  /// don't use this, use service_containers createWorkout to create Workouts to connect the Workout with the respective Workout Units
  // Future<Map<String, dynamic>> createWorkout({
  //   required String name,
  //   // Add other required fields as needed
  // }) async {
  //   return json.decode(await createData('workouts', {'name': name}));
  // }

  Future<Map<String, dynamic>> createWorkout({
    //TODO: auf models umstellen
    required String name,
    required List<Map<String, dynamic>> units,
  }) async {
    // Create the workout first and get its data (including ID)
    final workoutData =
        json.decode(await createData('workouts', {'name': name}));
    final workoutId = workoutData['id'] as int;

    // Now create all the workout units
    for (final unit in units) {
      await GetIt.I<WorkoutUnitService>().createWorkoutUnit(
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

  /// Updates an existing workout record
  /// [id] - The unique identifier of the workout to update
  /// [data] - Map containing the fields to update
  Future<void> updateWorkout(int id, Map<String, dynamic> data) async {
    updateData('workouts/$id', data);
  }

  /// Deletes a workout record
  /// [id] - The unique identifier of the workout to delete
  Future<void> deleteWorkout(int id) async {
    return deleteData('workouts/$id');
  }
}

//----------------- Workout Unit Service -----------------//

class WorkoutUnitService {
  /// Retrieves all workout units for a user
  /// Returns a list of workout unit objects
  Future<List<ApiWorkoutUnit>> getWorkoutUnits() async {
    final raw = await getData<List<dynamic>>('workout_units');
    _enrichWorkoutUnitsWithExerciseNames(raw);
    return raw.map((e) => ApiWorkoutUnit.fromJson(e)).toList();
    ;
  }

  Future<List<dynamic>> _enrichWorkoutUnitsWithExerciseNames(
      List<dynamic> workoutUnits) async {
    try {
      // Get all exercises to create a mapping from ID to name
      final exerciseService = GetIt.I<ExerciseService>();
      final exercises = await exerciseService.getExercises();
      final Map<int, String> exerciseIdToName = {};

      for (var exercise in exercises) {
        try {
          exerciseIdToName[exercise.id!] = exercise.name;
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

  /// Retrieves a specific workout unit by its ID
  /// [id] - The unique identifier of the workout unit
  /// Returns a map containing workout unit details
  Future<Map<String, dynamic>> getWorkoutUnitById(int id) async {
    return getData<Map<String, dynamic>>('workout_units/$id');
  }

  /// Creates a new workout unit record
  Future<void> createWorkoutUnit({
    required int workoutId,
    required int exerciseId,
    required int warmups,
    required int worksets,
    required int dropsets,
    required int type,
  }) async {
    createData('workout_units', {
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'warmups': warmups,
      'worksets': worksets,
      'dropsets': dropsets,
      'type': type,
    });
  }

  /// Updates an existing workout unit record
  /// [id] - The unique identifier of the workout unit to update
  /// [data] - Map containing the fields to update
  Future<void> updateWorkoutUnit(int id, Map<String, dynamic> data) async {
    updateData('workout_units/$id', data);
  }

  /// Deletes a workout unit record
  /// [id] - The unique identifier of the workout unit to delete
  Future<void> deleteWorkoutUnit(int id) async {
    return deleteData('workout_units/$id');
  }
}

class ExerciseService {
  Future<List<ApiExercise>> getExercises() async {
    final raw = await getData<List<dynamic>>('exercises');
    return raw.map((e) => ApiExercise.fromJson(e)).toList();
  }

  Future<ApiExercise> getExerciseById(int id) async {
    final raw = await getData<Map<String, dynamic>>('exercises/$id');
    return ApiExercise.fromJson(raw);
  }

  /// Creates a new exercise record
  Future<void> createExercise(Map<String, dynamic> data) async {
    createData('exercises', data);
  }

  Future<void> updateExercise(int id, Map<String, dynamic> data) async {
    updateData('exercises/$id', data);
  }

  Future<void> deleteExercise(int id) async {
    return deleteData('exercises/$id');
  }
}
