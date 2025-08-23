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
  Future<List<Workout>> getWorkouts() async {
    final raw = await getData<List<dynamic>>('workouts');
    final workouts = raw.map((e) => Workout.fromJson(e)).toList();
// Enrich workouts with workout units for display
    return await _enrichWorkoutsWithUnits(workouts);
  }

  Future<List<Workout>> _enrichWorkoutsWithUnits(List<Workout> workouts) async {
    final unitsByWorkoutId = <int, List<WorkoutUnit>>{};
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

  Future<void> updateWorkout(int id, Map<String, dynamic> data) async {
    updateData('workouts/$id', data);
  }

  Future<void> deleteWorkout(int id) async {
    return deleteData('workouts/$id');
  }
}

//----------------- Workout Unit Service -----------------//

class WorkoutUnitService {
  Future<List<WorkoutUnit>> getWorkoutUnits() async {
    final raw = await getData<List<dynamic>>('workout_units');
    final wu = raw.map((e) => WorkoutUnit.fromJson(e)).toList();
    return await _enrichWorkoutUnitsWithExerciseNames(wu);
    ;
  }

  Future<List<WorkoutUnit>> _enrichWorkoutUnitsWithExerciseNames(
      List<WorkoutUnit> workoutUnits) async {
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

      // Enrich workout units with exercise names
      for (var unit in workoutUnits) {
        unit.exerciseName = exerciseIdToName[unit.exerciseId] ?? '';
      }

      return workoutUnits;
    } catch (e) {
      print('Error in _enrichWorkoutUnitsWithExerciseNames: $e');
      // Return original workout units converted to proper Maps if enrichment completely fails
      return workoutUnits;
    }
  }

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

  Future<void> updateWorkoutUnit(int id, Map<String, dynamic> data) async {
    updateData('workout_units/$id', data);
  }

  Future<void> deleteWorkoutUnit(int id) async {
    return deleteData('workout_units/$id');
  }
}

class ExerciseService {
  Future<List<Exercise>> getExercises() async {
    final raw = await getData<List<dynamic>>('exercises');
    return raw.map((e) => Exercise.fromJson(e)).toList();
  }

  Future<Exercise> getExerciseById(int id) async {
    final raw = await getData<Map<String, dynamic>>('exercises/$id');
    return Exercise.fromJson(raw);
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
