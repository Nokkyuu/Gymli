// ignore_for_file: non_constant_identifier_names

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'api.dart' as api;
import 'api_models.dart';

class UserService {
  static UserService? _instance;

  // Updated singleton pattern that's more web-friendly
  factory UserService() {
    _instance ??= UserService._internal();
    return _instance!;
  }

  UserService._internal();

  Credentials? _credentials;
  bool get isLoggedIn => _credentials != null;
  String get userName => _credentials?.user.name ?? 'DefaultUser';
  String get userEmail => _credentials?.user.email ?? '';

  // Notifier for authentication state changes
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  // In-memory storage for non-authenticated users
  Map<String, dynamic> _inMemoryData = {
    'exercises': <Map<String, dynamic>>[],
    'workouts': <Map<String, dynamic>>[],
    'trainingSets': <Map<String, dynamic>>[],
    'workoutUnits': <Map<String, dynamic>>[],
    'groups': <Map<String, dynamic>>[],
  };

  void setCredentials(Credentials? credentials) {
    final wasLoggedIn = isLoggedIn;
    _credentials = credentials;
    final isNowLoggedIn = isLoggedIn;

    if (!isLoggedIn) {
      // Clear in-memory data when logging out
      _clearInMemoryData();
    }

    // Notify listeners if auth state changed
    if (wasLoggedIn != isNowLoggedIn) {
      authStateNotifier.value = isNowLoggedIn;
    }
  }

  void _clearInMemoryData() {
    _inMemoryData = {
      'exercises': <Map<String, dynamic>>[],
      'workouts': <Map<String, dynamic>>[],
      'trainingSets': <Map<String, dynamic>>[],
      'workoutUnits': <Map<String, dynamic>>[],
      'groups': <Map<String, dynamic>>[],
    };
  }

  // Exercise Services
  Future<List<dynamic>> getExercises() async {
    if (isLoggedIn) {
      return await api.ExerciseService().getExercises(userName: userName);
    } else {
      // For non-authenticated users, load DefaultUser data
      try {
        return await api.ExerciseService()
            .getExercises(userName: 'DefaultUser');
      } catch (e) {
        // If API fails, return in-memory data
        return _inMemoryData['exercises'] as List<dynamic>;
      }
    }
  }

  Future<void> createExercise({
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
    required double calves,
  }) async {
    if (isLoggedIn) {
      await api.ExerciseService().createExercise(
        userName: userName,
        name: name,
        type: type,
        defaultRepBase: defaultRepBase,
        defaultRepMax: defaultRepMax,
        defaultIncrement: defaultIncrement,
        pectoralisMajor: pectoralisMajor,
        trapezius: trapezius,
        biceps: biceps,
        abdominals: abdominals,
        frontDelts: frontDelts,
        deltoids: deltoids,
        backDelts: backDelts,
        latissimusDorsi: latissimusDorsi,
        triceps: triceps,
        gluteusMaximus: gluteusMaximus,
        hamstrings: hamstrings,
        quadriceps: quadriceps,
        calves: calves,
      );
    } else {
      // For non-authenticated users, store in memory only
      final exercise = {
        'id': DateTime.now().millisecondsSinceEpoch, // Generate fake ID
        'user_name': 'DefaultUser',
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
        'calves': calves,
      };
      (_inMemoryData['exercises'] as List<dynamic>).add(exercise);
    }
  }

  Future<void> updateExercise(int id, Map<String, dynamic> data) async {
    if (isLoggedIn) {
      await api.ExerciseService().updateExercise(id, data);
    } else {
      // Update in memory
      final exercises = _inMemoryData['exercises'] as List<dynamic>;
      final index = exercises.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        exercises[index] = {...exercises[index], ...data};
      }
    }
  }

  Future<void> deleteExercise(int id) async {
    if (isLoggedIn) {
      await api.ExerciseService().deleteExercise(id);
    } else {
      // Remove from memory
      final exercises = _inMemoryData['exercises'] as List<dynamic>;
      exercises.removeWhere((e) => e['id'] == id);
    }
  }

  // Workout Services
  Future<List<dynamic>> getWorkouts() async {
    if (isLoggedIn) {
      return await api.WorkoutService().getWorkouts(userName: userName);
    } else {
      try {
        return await api.WorkoutService().getWorkouts(userName: 'DefaultUser');
      } catch (e) {
        return _inMemoryData['workouts'] as List<dynamic>;
      }
    }
  }

  Future<void> createWorkout({
    required String name,
    required List<Map<String, dynamic>> units,
  }) async {
    if (isLoggedIn) {
      await api.WorkoutService().createWorkout(userName: userName, name: name);
    } else {
      final workout = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_name': 'DefaultUser',
        'name': name,
        'units': units,
      };
      (_inMemoryData['workouts'] as List<dynamic>).add(workout);
    }
  }

  Future<void> updateWorkout(int id, Map<String, dynamic> data) async {
    if (isLoggedIn) {
      await api.WorkoutService().updateWorkout(id, data);
    } else {
      final workouts = _inMemoryData['workouts'] as List<dynamic>;
      final index = workouts.indexWhere((w) => w['id'] == id);
      if (index != -1) {
        workouts[index] = {...workouts[index], ...data};
      }
    }
  }

  Future<void> deleteWorkout(int id) async {
    if (isLoggedIn) {
      await api.WorkoutService().deleteWorkout(id);
    } else {
      final workouts = _inMemoryData['workouts'] as List<dynamic>;
      workouts.removeWhere((w) => w['id'] == id);
    }
  }

  // Training Set Services
  Future<List<dynamic>> getTrainingSets() async {
    List<dynamic> rawTrainingSets;

    if (isLoggedIn) {
      rawTrainingSets =
          await api.TrainingSetService().getTrainingSets(userName: userName);
    } else {
      try {
        rawTrainingSets = await api.TrainingSetService()
            .getTrainingSets(userName: 'DefaultUser');
      } catch (e) {
        rawTrainingSets = _inMemoryData['trainingSets'] as List<dynamic>;
      }
    }

    // Enrich training sets with exercise names
    return await _enrichTrainingSetsWithExerciseNames(rawTrainingSets);
  }

  Future<List<dynamic>> _enrichTrainingSetsWithExerciseNames(
      List<dynamic> trainingSets) async {
    try {
      // Get all exercises to create a mapping from ID to name
      final exercises = await getExercises();
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

          final exercise = ApiExercise.fromJson(exerciseMap);
          exerciseIdToName[exercise.id!] = exercise.name;
        } catch (e) {
          print('Error parsing exercise data: $e');
          print('Exercise data: $exerciseData');
          print('Exercise data type: ${exerciseData.runtimeType}');
        }
      }

      print('DEBUG: Created exercise ID to name mapping: $exerciseIdToName');

      // Add exercise_name field to each training set
      return trainingSets.map((trainingSet) {
        try {
          // Handle both Map and LinkedMap types
          final Map<String, dynamic> trainingSetMap;
          if (trainingSet is Map<String, dynamic>) {
            trainingSetMap = Map<String, dynamic>.from(trainingSet);
          } else {
            trainingSetMap = Map<String, dynamic>.from(trainingSet as Map);
          }

          final exerciseId = trainingSetMap['exercise_id'] as int?;
          if (exerciseId != null) {
            final exerciseName =
                exerciseIdToName[exerciseId] ?? 'Unknown Exercise';
            trainingSetMap['exercise_name'] = exerciseName;
            print(
                'DEBUG: Enriched training set ${trainingSetMap['id']} with exercise name: $exerciseName');
          } else {
            print('DEBUG: Training set missing exercise_id: $trainingSetMap');
          }

          return trainingSetMap;
        } catch (e) {
          print('Error enriching training set: $e');
          print('Training set data: $trainingSet');
          print('Training set data type: ${trainingSet.runtimeType}');

          // Return the original training set converted to proper Map if enrichment fails
          try {
            if (trainingSet is Map<String, dynamic>) {
              return Map<String, dynamic>.from(trainingSet);
            } else {
              return Map<String, dynamic>.from(trainingSet as Map);
            }
          } catch (conversionError) {
            print('Error converting training set to Map: $conversionError');
            return trainingSet;
          }
        }
      }).toList();
    } catch (e) {
      print('Error in _enrichTrainingSetsWithExerciseNames: $e');
      print('Stack trace: ${StackTrace.current}');

      // Return original training sets converted to proper Maps if enrichment completely fails
      return trainingSets.map((ts) {
        try {
          if (ts is Map<String, dynamic>) {
            return Map<String, dynamic>.from(ts);
          } else {
            return Map<String, dynamic>.from(ts as Map);
          }
        } catch (conversionError) {
          print(
              'Error converting training set to Map in fallback: $conversionError');
          return ts;
        }
      }).toList();
    }
  }

  Future<void> createTrainingSet({
    required int exerciseId,
    required String date,
    required double weight,
    required int repetitions,
    required int setType,
    required int baseReps,
    required int maxReps,
    required double increment,
    String? machineName,
  }) async {
    if (isLoggedIn) {
      await api.TrainingSetService().createTrainingSet(
        userName: userName,
        exerciseId: exerciseId,
        date: date,
        weight: weight,
        repetitions: repetitions,
        setType: setType,
        baseReps: baseReps,
        maxReps: maxReps,
        increment: increment,
        machineName: machineName,
      );
    } else {
      final trainingSet = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_name': 'DefaultUser',
        'exercise_id': exerciseId,
        'date': date,
        'weight': weight,
        'repetitions': repetitions,
        'set_type': setType,
        'base_reps': baseReps,
        'max_reps': maxReps,
        'increment': increment,
        'machine_name': machineName,
      };
      (_inMemoryData['trainingSets'] as List<dynamic>).add(trainingSet);
    }
  }

  Future<void> updateTrainingSet(int id, Map<String, dynamic> data) async {
    if (isLoggedIn) {
      await api.TrainingSetService().updateTrainingSet(id, data);
    } else {
      final trainingSets = _inMemoryData['trainingSets'] as List<dynamic>;
      final index = trainingSets.indexWhere((ts) => ts['id'] == id);
      if (index != -1) {
        trainingSets[index] = {...trainingSets[index], ...data};
      }
    }
  }

  Future<void> deleteTrainingSet(int id) async {
    if (isLoggedIn) {
      await api.TrainingSetService().deleteTrainingSet(id);
    } else {
      final trainingSets = _inMemoryData['trainingSets'] as List<dynamic>;
      trainingSets.removeWhere((ts) => ts['id'] == id);
    }
  }

  // Workout Unit Services
  Future<List<dynamic>> getWorkoutUnits() async {
    if (isLoggedIn) {
      return await api.WorkoutUnitService().getWorkoutUnits(userName: userName);
    } else {
      try {
        return await api.WorkoutUnitService()
            .getWorkoutUnits(userName: 'DefaultUser');
      } catch (e) {
        return _inMemoryData['workoutUnits'] as List<dynamic>;
      }
    }
  }

  Future<void> createWorkoutUnit({
    required int workoutId,
    required int exerciseId,
    required int warmups,
    required int worksets,
    required int type,
  }) async {
    if (isLoggedIn) {
      await api.WorkoutUnitService().createWorkoutUnit(
        userName: userName,
        workoutId: workoutId,
        exerciseId: exerciseId,
        warmups: warmups,
        worksets: worksets,
        type: type,
      );
    } else {
      final workoutUnit = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_name': 'DefaultUser',
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'warmups': warmups,
        'worksets': worksets,
        'type': type,
      };
      (_inMemoryData['workoutUnits'] as List<dynamic>).add(workoutUnit);
    }
  }

  Future<void> updateWorkoutUnit(int id, Map<String, dynamic> data) async {
    if (isLoggedIn) {
      await api.WorkoutUnitService().updateWorkoutUnit(id, data);
    } else {
      final workoutUnits = _inMemoryData['workoutUnits'] as List<dynamic>;
      final index = workoutUnits.indexWhere((wu) => wu['id'] == id);
      if (index != -1) {
        workoutUnits[index] = {...workoutUnits[index], ...data};
      }
    }
  }

  Future<void> deleteWorkoutUnit(int id) async {
    if (isLoggedIn) {
      await api.WorkoutUnitService().deleteWorkoutUnit(id);
    } else {
      final workoutUnits = _inMemoryData['workoutUnits'] as List<dynamic>;
      workoutUnits.removeWhere((wu) => wu['id'] == id);
    }
  }

  // Group methods - Currently using in-memory storage only
  // TODO: Implement API calls when GroupService is available
  Future<List<Map<String, dynamic>>> getGroups() async {
    // For now, always use in-memory storage regardless of login status
    return List<Map<String, dynamic>>.from(_inMemoryData['groups']);
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    required List<String> exercises,
  }) async {
    // For now, always use in-memory storage regardless of login status
    final newGroup = {
      'id': DateTime.now().millisecondsSinceEpoch, // Generate simple ID
      'user_name': userName,
      'name': name,
      'exercises': exercises,
    };
    (_inMemoryData['groups'] as List<dynamic>).add(newGroup);
    return newGroup;
  }

  Future<void> updateGroup(int id, Map<String, dynamic> data) async {
    // For now, always use in-memory storage regardless of login status
    final groups = _inMemoryData['groups'] as List<dynamic>;
    final index = groups.indexWhere((g) => g['id'] == id);
    if (index != -1) {
      groups[index] = {...groups[index], ...data};
    }
  }

  Future<void> deleteGroup(int id) async {
    // For now, always use in-memory storage regardless of login status
    final groups = _inMemoryData['groups'] as List<dynamic>;
    groups.removeWhere((g) => g['id'] == id);
  }

  // Clear all data methods for settings screen
  Future<void> clearTrainingSets() async {
    if (isLoggedIn) {
      // Get all training sets for this user and delete them
      final trainingSets = await getTrainingSets();
      for (var set in trainingSets) {
        if (set['id'] != null) {
          await deleteTrainingSet(set['id']);
        }
      }
    } else {
      // Clear in-memory training sets and clear DefaultUser from API
      _inMemoryData['trainingSets'] = <Map<String, dynamic>>[];
      try {
        final defaultSets = await api.TrainingSetService()
            .getTrainingSets(userName: 'DefaultUser');
        for (var set in defaultSets) {
          if (set['id'] != null) {
            await api.TrainingSetService().deleteTrainingSet(set['id']);
          }
        }
      } catch (e) {
        // Ignore API errors for DefaultUser data
      }
    }
  }

  Future<void> clearExercises() async {
    if (isLoggedIn) {
      // Get all exercises for this user and delete them
      final exercises = await getExercises();
      for (var exercise in exercises) {
        if (exercise['id'] != null) {
          await deleteExercise(exercise['id']);
        }
      }
    } else {
      // Clear in-memory exercises and clear DefaultUser from API
      _inMemoryData['exercises'] = <Map<String, dynamic>>[];
      try {
        final defaultExercises =
            await api.ExerciseService().getExercises(userName: 'DefaultUser');
        for (var exercise in defaultExercises) {
          if (exercise['id'] != null) {
            await api.ExerciseService().deleteExercise(exercise['id']);
          }
        }
      } catch (e) {
        // Ignore API errors for DefaultUser data
      }
    }
  }

  Future<void> clearWorkouts() async {
    if (isLoggedIn) {
      // Get all workouts for this user and delete them
      final workouts = await getWorkouts();
      for (var workout in workouts) {
        if (workout['id'] != null) {
          await deleteWorkout(workout['id']);
        }
      }
    } else {
      // Clear in-memory workouts and clear DefaultUser from API
      _inMemoryData['workouts'] = <Map<String, dynamic>>[];
      try {
        final defaultWorkouts =
            await api.WorkoutService().getWorkouts(userName: 'DefaultUser');
        for (var workout in defaultWorkouts) {
          if (workout['id'] != null) {
            await api.WorkoutService().deleteWorkout(workout['id']);
          }
        }
      } catch (e) {
        // Ignore API errors for DefaultUser data
      }
    }
  }
}
