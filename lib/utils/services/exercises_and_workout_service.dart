/// WorkoutService and WorkoutUnitService - Manages workout templates and workout units
///
/// This service handles all CRUD operations for workouts and workout units.
/// Workouts are templates for user training sessions, and workout units link
/// exercises to workouts and define their order and type within the workout.
///
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../api/api_base.dart';
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

  Future<Workout> createWorkout({
    required String name,
    required List<Map<String, dynamic>> units,
  }) async {
    // Create the workout first and get its data (including ID)
    final workoutData = await createData('workouts', {'name': name});
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

    return Workout.fromJson(workoutData);
  }

  Future<Workout> updateWorkout(int id, Map<String, dynamic> data) async {
    final workoutData = await updateData('workouts/$id', data);
    //TODO: Proper implementation of updating Workout Units
    return Workout.fromJson(workoutData);
  }

  Future<void> deleteWorkout(int id) async {
    //TODO: implement success reponse?
    return deleteData('workouts/$id');
  }

  Future<void> clearWorkouts() async {
    // Get all workouts for this user and delete them
    //TODO: Integrate clearing of workout units before workouts?
    final workouts =
        await getWorkouts(); // Get raw workouts without enrichment for efficiency
    int deletedCount = 0;
    int errorCount = 0;

    for (var workout in workouts) {
      if (workout.id != null) {
        try {
          await deleteWorkout(workout.id!);
          deletedCount++;
        } catch (e) {
          errorCount++;
          if (kDebugMode) {
            print('Warning: Failed to delete workout ${workout.id}: $e');
          }
          // Continue with other workouts instead of stopping
        }
      }
    }
    if (kDebugMode) {
      print('Cleared workouts: $deletedCount deleted, $errorCount errors');
    }
  }
}

//----------------- Workout Unit Service -----------------//

class WorkoutUnitService {
  Future<List<WorkoutUnit>> getWorkoutUnits() async {
    final raw = await getData<List<dynamic>>('workout_units');
    final wu = raw.map((e) => WorkoutUnit.fromJson(e)).toList();
    return await _enrichWorkoutUnitsWithExerciseNames(wu);
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
          if (kDebugMode) {
            print('Error parsing exercise data in workout units: $e');
          }
        }
      }

      // Enrich workout units with exercise names
      for (var unit in workoutUnits) {
        unit.exerciseName = exerciseIdToName[unit.exerciseId] ?? '';
      }

      return workoutUnits;
    } catch (e) {
      if (kDebugMode) {
        print('Error in _enrichWorkoutUnitsWithExerciseNames: $e');
      }
      // Return original workout units converted to proper Maps if enrichment completely fails
      return workoutUnits;
    }
  }

  Future<WorkoutUnit> getWorkoutUnitById(int id) async {
    final data = await getData<Map<String, dynamic>>('workout_units/$id');
    return WorkoutUnit.fromJson(data);
  }

  /// Creates a new workout unit record
  Future<WorkoutUnit> createWorkoutUnit({
    required int workoutId,
    required int exerciseId,
    required int warmups,
    required int worksets,
    required int dropsets,
    required int type,
  }) async {
    final data = await createData('workout_units', {
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'warmups': warmups,
      'worksets': worksets,
      'dropsets': dropsets,
      'type': type,
    });
    return WorkoutUnit.fromJson(data);
  }

  Future<WorkoutUnit> updateWorkoutUnit(
      int id, Map<String, dynamic> data) async {
    final updatedData = await updateData('workout_units/$id', data);
    return WorkoutUnit.fromJson(updatedData);
  }

  Future<void> deleteWorkoutUnit(int id) async {
    //TODO: success response?
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
  Future<Exercise> createExercise({
    required String name,
    required int type,
    required int defaultRepBase,
    required int defaultRepMax,
    required double defaultIncrement,
    required double pectoralisMajor,
    required double trapezius,
    required double biceps,
    required double abdominals,
    required double frontDelts,
    required double deltoids,
    required double backDelts,
    required double latissimusDorsi,
    required double triceps,
    required double gluteusMaximus,
    required double hamstrings,
    required double quadriceps,
    required double forearms,
    required double calves,
  }) async {
    final data = await createData('exercises', {
      'name': name,
      'type': type,
      'default_rep_base': defaultRepBase,
      'default_rep_max': defaultRepMax,
      'default_increment': defaultIncrement,
      'pectoralis_major': pectoralisMajor,
      'trapezius': trapezius,
      'biceps': biceps,
      'abdominals': abdominals,
      'front_delts': frontDelts,
      'deltoids': deltoids,
      'back_delts': backDelts,
      'latissimus_dorsi': latissimusDorsi,
      'triceps': triceps,
      'gluteus_maximus': gluteusMaximus,
      'hamstrings': hamstrings,
      'quadriceps': quadriceps,
      'forearms': forearms,
      'calves': calves,
    });
    return Exercise.fromJson(data);
  }

  Future<Exercise> updateExercise(int id, Map<String, dynamic> data) async {
    final updatedData = await updateData('exercises/$id', data);
    return Exercise.fromJson(updatedData);
  }

  Future<void> deleteExercise(int id) async {
    return deleteData('exercises/$id');
  }

  Future<int?> getExerciseIdByName(String exerciseName) async {
    try {
      final exercises = await getExercises();
      final exerciseData =
          exercises.firstWhere((item) => item.name == exerciseName);
      return exerciseData.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving exercise name to ID: $e');
      }
      return null;
    }
  }

  Future<void> clearExercises() async {
    return clearData('exercises/clear');

    // // Get all exercises for this user and delete them
    // final exercises = await getExercises();
    // int deletedCount = 0;
    // int errorCount = 0;

    // for (var exercise in exercises) {
    //   if (exercise.id != null) {
    //     try {
    //       await deleteExercise(exercise.id!);
    //       deletedCount++;
    //     } catch (e) {
    //       errorCount++;
    //       if (kDebugMode) {
    //         print('Warning: Failed to delete exercise ${exercise.id}: $e');
    //       }
    //       // Continue with other exercises instead of stopping
    //     }
    //   }
    // }
    // if (kDebugMode) {
    //   print('Cleared exercises: $deletedCount deleted, $errorCount errors');
    // }
  }
}
