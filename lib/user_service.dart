/**
 * User Service for Authentication and Data Management
 * 
 * This service manages user authentication using Auth0 and provides
 * data persistence capabilities for both authenticated and anonymous users.
 * 
 * Key features:
 * - Auth0 integration for secure user authentication
 * - Singleton pattern for global access across the application
 * - In-memory data storage for non-authenticated users
 * - Real-time authentication state notifications
 * - User data synchronization between local and cloud storage
 * 
 * The service handles:
 * - Login/logout operations
 * - User credential management
 * - Data persistence (exercises, workouts, training sets)
 * - Authentication state broadcasting
 */

// ignore_for_file: non_constant_identifier_names

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
      // Clear stored auth state
      _clearStoredAuthState();
    } else {
      // Save auth state when logging in
      _saveAuthState(credentials!);
    }

    // Notify listeners if auth state changed
    if (wasLoggedIn != isNowLoggedIn) {
      authStateNotifier.value = isNowLoggedIn;
    }
  }

  // Save authentication state to persistent storage
  Future<void> _saveAuthState(Credentials credentials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authData = {
        'accessToken': credentials.accessToken,
        'idToken': credentials.idToken,
        'refreshToken': credentials.refreshToken,
        'tokenType': credentials.tokenType,
        'expiresAt': credentials.expiresAt.millisecondsSinceEpoch,
        'scopes': credentials.scopes.toList(),
        'user': {
          'sub': credentials.user.sub,
          'name': credentials.user.name,
          'givenName': credentials.user.givenName,
          'familyName': credentials.user.familyName,
          'middleName': credentials.user.middleName,
          'nickname': credentials.user.nickname,
          'preferredUsername': credentials.user.preferredUsername,
          'pictureUrl': credentials.user.pictureUrl?.toString(),
          'profileUrl': credentials.user.profileUrl?.toString(),
          'websiteUrl': credentials.user.websiteUrl?.toString(),
          'email': credentials.user.email,
          'isEmailVerified': credentials.user.isEmailVerified,
          'gender': credentials.user.gender,
          'birthdate': credentials.user.birthdate,
          'zoneinfo': credentials.user.zoneinfo,
          'locale': credentials.user.locale,
          'phoneNumber': credentials.user.phoneNumber,
          'isPhoneNumberVerified': credentials.user.isPhoneNumberVerified,
          'address': credentials.user.address,
          'updatedAt': credentials.user.updatedAt?.toIso8601String(),
          'customClaims': credentials.user.customClaims,
        }
      };
      await prefs.setString('auth_credentials', json.encode(authData));
      await prefs.setBool('is_logged_in', true);
      print('Auth state saved to persistent storage');
    } catch (e) {
      print('Error saving auth state: $e');
    }
  }

  // Load authentication state from persistent storage
  Future<Credentials?> loadStoredAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) {
        return null;
      }

      final authDataString = prefs.getString('auth_credentials');
      if (authDataString == null) {
        return null;
      }

      final authData = json.decode(authDataString);

      // Check if token is expired
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(authData['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        print('Stored credentials have expired');
        await _clearStoredAuthState();
        return null;
      }

      // Reconstruct credentials with only available UserProfile fields
      final userData = authData['user'];
      final user = UserProfile(
        sub: userData['sub'],
        name: userData['name'],
        givenName: userData['givenName'],
        familyName: userData['familyName'],
        middleName: userData['middleName'],
        nickname: userData['nickname'],
        preferredUsername: userData['preferredUsername'],
        pictureUrl: userData['pictureUrl'] != null
            ? Uri.parse(userData['pictureUrl'])
            : null,
        profileUrl: userData['profileUrl'] != null
            ? Uri.parse(userData['profileUrl'])
            : null,
        websiteUrl: userData['websiteUrl'] != null
            ? Uri.parse(userData['websiteUrl'])
            : null,
        email: userData['email'],
        isEmailVerified: userData['isEmailVerified'],
        gender: userData['gender'],
        birthdate: userData['birthdate'],
        zoneinfo: userData['zoneinfo'],
        locale: userData['locale'],
        phoneNumber: userData['phoneNumber'],
        isPhoneNumberVerified: userData['isPhoneNumberVerified'],
        address: userData['address'] != null
            ? Map<String, String>.from(userData['address'])
            : null,
        updatedAt: userData['updatedAt'] != null
            ? DateTime.parse(userData['updatedAt'])
            : null,
        customClaims: userData['customClaims'] != null
            ? Map<String, dynamic>.from(userData['customClaims'])
            : null,
      );

      final credentials = Credentials(
        accessToken: authData['accessToken'],
        idToken: authData['idToken'],
        refreshToken: authData['refreshToken'],
        tokenType: authData['tokenType'],
        expiresAt: expiresAt,
        scopes: Set<String>.from(authData['scopes'] ?? []),
        user: user,
      );

      print('Auth state loaded from persistent storage for user: ${user.name}');
      return credentials;
    } catch (e) {
      print('Error loading stored auth state: $e');
      await _clearStoredAuthState();
      return null;
    }
  }

  // Clear stored authentication state
  Future<void> _clearStoredAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_credentials');
      await prefs.setBool('is_logged_in', false);
      print('Stored auth state cleared');
    } catch (e) {
      print('Error clearing stored auth state: $e');
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
      // When not logged in, prioritize in-memory data if it exists
      final inMemoryExercises = _inMemoryData['exercises'] as List<dynamic>;
      if (inMemoryExercises.isNotEmpty) {
        return inMemoryExercises;
      } else {
        // Only try API if no in-memory data exists
        try {
          return await api.ExerciseService()
              .getExercises(userName: 'DefaultUser');
        } catch (e) {
          // If API fails, return empty in-memory data
          return inMemoryExercises;
        }
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
    List<dynamic> rawWorkouts;

    if (isLoggedIn) {
      rawWorkouts = await api.WorkoutService().getWorkouts(userName: userName);
    } else {
      // When not logged in, prioritize in-memory data if it exists
      final inMemoryWorkouts = _inMemoryData['workouts'] as List<dynamic>;
      if (inMemoryWorkouts.isNotEmpty) {
        rawWorkouts = inMemoryWorkouts;
      } else {
        // Only try API if no in-memory data exists
        try {
          rawWorkouts =
              await api.WorkoutService().getWorkouts(userName: 'DefaultUser');
        } catch (e) {
          rawWorkouts = inMemoryWorkouts; // Fallback to empty in-memory data
        }
      }
    }

    // Enrich workouts with their units
    return await _enrichWorkoutsWithUnits(rawWorkouts);
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
            print(
                'DEBUG: Workout ${workoutMap['name']} fetched ${units.length} units from workout units collection');
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
      (_inMemoryData['workouts'] as List<dynamic>).add(workout);

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
        (_inMemoryData['workoutUnits'] as List<dynamic>).add(workoutUnit);
      }

      return workout;
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
      // When not logged in, prioritize in-memory data if it exists
      final inMemoryTrainingSets =
          _inMemoryData['trainingSets'] as List<dynamic>;
      if (inMemoryTrainingSets.isNotEmpty) {
        rawTrainingSets = inMemoryTrainingSets;
      } else {
        // Only try API if no in-memory data exists
        try {
          rawTrainingSets = await api.TrainingSetService()
              .getTrainingSets(userName: 'DefaultUser');
        } catch (e) {
          rawTrainingSets =
              inMemoryTrainingSets; // Fallback to empty in-memory data
        }
      }
    }

    // Enrich training sets with exercise names
    return await _enrichTrainingSetsWithExerciseNames(rawTrainingSets);
  }

  /// Gets the last training date for each exercise
  /// Returns a map where keys are exercise names and values are the most recent training dates
  Future<Map<String, DateTime>> getLastTrainingDatesPerExercise() async {
    try {
      final trainingSets = await getTrainingSets();
      final Map<String, DateTime> lastDates = {};

      for (var trainingSet in trainingSets) {
        final exerciseName = trainingSet['exercise_name'] as String?;
        final dateString = trainingSet['date'] as String?;
        final setType = trainingSet['set_type'] as int? ?? 0;

        // Only count actual work sets (set_type > 0), skip warmups
        if (exerciseName != null && dateString != null && setType > 0) {
          try {
            final trainingDate = DateTime.parse(dateString);

            // Update if this is the first date for this exercise or if it's more recent
            if (!lastDates.containsKey(exerciseName) ||
                trainingDate.isAfter(lastDates[exerciseName]!)) {
              lastDates[exerciseName] = trainingDate;
            }
          } catch (e) {
            print('Error parsing date for exercise $exerciseName: $e');
          }
        }
      }

      return lastDates;
    } catch (e) {
      print('Error getting last training dates per exercise: $e');
      return {};
    }
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

  /// Creates multiple training sets in a single batch operation
  /// This method is optimized for bulk imports and significantly reduces
  /// the number of HTTP requests compared to creating sets individually.
  ///
  /// [trainingSets] - List of training set data to create. Each item should contain:
  ///   - exerciseId, date, weight, repetitions, setType, baseReps, maxReps, increment, machineName
  ///
  /// Returns a list of created training sets with their assigned IDs
  Future<List<Map<String, dynamic>>> createTrainingSetsBulk(
    List<Map<String, dynamic>> trainingSets,
  ) async {
    if (trainingSets.isEmpty) {
      return [];
    }

    if (isLoggedIn) {
      // Convert the training sets to the format expected by the API
      final apiTrainingSets = trainingSets
          .map((ts) => {
                'exercise_id': ts['exerciseId'],
                'date': ts['date'],
                'weight': ts['weight'],
                'repetitions': ts['repetitions'],
                'set_type': ts['setType'],
                'base_reps': ts['baseReps'],
                'max_reps': ts['maxReps'],
                'increment': ts['increment'],
                'machine_name': ts['machineName'],
              })
          .toList();

      return await api.TrainingSetService().createTrainingSetsBulk(
        userName: userName,
        trainingSets: apiTrainingSets,
      );
    } else {
      // For offline mode, add all training sets to in-memory storage
      final createdSets = <Map<String, dynamic>>[];
      for (final ts in trainingSets) {
        final trainingSet = {
          'id': DateTime.now().millisecondsSinceEpoch + createdSets.length,
          'user_name': 'DefaultUser',
          'exercise_id': ts['exerciseId'],
          'date': ts['date'],
          'weight': ts['weight'],
          'repetitions': ts['repetitions'],
          'set_type': ts['setType'],
          'base_reps': ts['baseReps'],
          'max_reps': ts['maxReps'],
          'increment': ts['increment'],
          'machine_name': ts['machineName'],
        };
        (_inMemoryData['trainingSets'] as List<dynamic>).add(trainingSet);
        createdSets.add(trainingSet);
      }
      return createdSets;
    }
  }

  /// Deletes a training set by its ID
  /// [id] - The unique identifier of the training set to delete
  Future<void> deleteTrainingSet(int id) async {
    if (isLoggedIn) {
      await api.TrainingSetService().deleteTrainingSet(id);
    } else {
      // Remove from in-memory storage
      (_inMemoryData['trainingSets'] as List<dynamic>)
          .removeWhere((ts) => ts['id'] == id);
    }
  }

  // Workout Unit Services
  Future<List<dynamic>> getWorkoutUnits() async {
    List<dynamic> rawWorkoutUnits;

    if (isLoggedIn) {
      rawWorkoutUnits =
          await api.WorkoutUnitService().getWorkoutUnits(userName: userName);
    } else {
      try {
        rawWorkoutUnits = await api.WorkoutUnitService()
            .getWorkoutUnits(userName: 'DefaultUser');
      } catch (e) {
        rawWorkoutUnits = _inMemoryData['workoutUnits'] as List<dynamic>;
      }
    }

    // Enrich workout units with exercise names
    return await _enrichWorkoutUnitsWithExerciseNames(rawWorkoutUnits);
  }

  Future<List<dynamic>> _enrichWorkoutUnitsWithExerciseNames(
      List<dynamic> workoutUnits) async {
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
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_name': 'DefaultUser',
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'warmups': warmups,
        'worksets': worksets,
        'dropsets': dropsets,
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
      // OPTIMIZED: Use bulk delete endpoint instead of individual deletes
      await api.TrainingSetService().clearTrainingSets(userName: userName);
      print('Training sets cleared using bulk delete endpoint');
    } else {
      // For offline mode, clear in-memory data
      _inMemoryData['trainingSets'] = <Map<String, dynamic>>[];
    }

    // Always clear in-memory data regardless of login status to prevent cache issues
    _inMemoryData['trainingSets'] = <Map<String, dynamic>>[];
    print('Cleared in-memory training sets cache');
  }

  Future<void> clearExercises() async {
    if (isLoggedIn) {
      // Get all exercises for this user and delete them
      final exercises = await getExercises();
      int deletedCount = 0;
      int errorCount = 0;

      for (var exercise in exercises) {
        if (exercise['id'] != null) {
          try {
            await deleteExercise(exercise['id']);
            deletedCount++;
          } catch (e) {
            errorCount++;
            print('Warning: Failed to delete exercise ${exercise['id']}: $e');
            // Continue with other exercises instead of stopping
          }
        }
      }
      print('Cleared exercises: $deletedCount deleted, $errorCount errors');
    } else {
      // Clear in-memory exercises and clear DefaultUser from API
      _inMemoryData['exercises'] = <Map<String, dynamic>>[];
      try {
        final defaultExercises =
            await api.ExerciseService().getExercises(userName: 'DefaultUser');
        int deletedCount = 0;
        int errorCount = 0;

        for (var exercise in defaultExercises) {
          if (exercise['id'] != null) {
            try {
              await api.ExerciseService().deleteExercise(exercise['id']);
              deletedCount++;
            } catch (e) {
              errorCount++;
              print(
                  'Warning: Failed to delete DefaultUser exercise ${exercise['id']}: $e');
              // Continue with other exercises instead of stopping
            }
          }
        }
        print(
            'Cleared DefaultUser exercises: $deletedCount deleted, $errorCount errors');
      } catch (e) {
        print('Error accessing DefaultUser exercises: $e');
        // Continue anyway - we still cleared in-memory data
      }
    }
  }

  Future<void> clearWorkouts() async {
    if (isLoggedIn) {
      // Get all workouts for this user and delete them
      final workouts = await getWorkouts();
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
      _inMemoryData['workouts'] = <Map<String, dynamic>>[];
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
        print(
            'Cleared DefaultUser workouts: $deletedCount deleted, $errorCount errors');
      } catch (e) {
        print('Error accessing DefaultUser workouts: $e');
        // Continue anyway - we still cleared in-memory data
      }
    }
  }

  // Helper method for import/export - resolve exercise name to ID
  Future<int?> getExerciseIdByName(String exerciseName) async {
    try {
      final exercises = await getExercises();
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

  // Helper method for import/export - resolve exercise ID to name
  Future<String?> getExerciseNameById(int exerciseId) async {
    try {
      final exercises = await getExercises();
      final exerciseData = exercises.firstWhere(
        (item) => item['id'] == exerciseId,
        orElse: () => null,
      );
      return exerciseData?['name'];
    } catch (e) {
      print('Error resolving exercise ID to name: $e');
      return null;
    }
  }
}
