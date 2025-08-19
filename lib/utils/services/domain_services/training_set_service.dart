import '../../api/api.dart' as api;
import '../data_service.dart';
import 'exercise_service.dart';

class TrainingSetService {
  final DataService _dataService = DataService();
  final ExerciseService _exerciseService = ExerciseService();

  // Getters that delegate to DataService
  bool get isLoggedIn => _dataService.isLoggedIn;
  String get userName => _dataService.userName;

  Future<List<dynamic>> getTrainingSets() async {
    final trainingSets = await _dataService.getData(
      'trainingSets',
      // API call for authenticated users
      () async =>
          await api.TrainingSetService().getTrainingSets(userName: userName),
      // Fallback API call for non-authenticated users
      () async => await api.TrainingSetService()
          .getTrainingSets(userName: 'DefaultUser'),
    );

    // Enrich training sets with exercise names for display
    return await _enrichTrainingSetsWithExerciseNames(trainingSets);
  }

  Future<Map<String, dynamic>?> createTrainingSet({
    required int exerciseId,
    required String date,
    required double weight,
    required int repetitions,
    required int setType,
    String? phase,
    bool? myoreps,
  }) async {
    if (isLoggedIn) {
      // Return the created set from the API
      return await api.TrainingSetService().createTrainingSet(
        userName: userName,
        exerciseId: exerciseId,
        date: date,
        weight: weight,
        repetitions: repetitions,
        setType: setType,
        phase: phase,
        myoreps: myoreps,
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
        'phase': phase,
        'myoreps': myoreps,
      };
      _dataService.addToInMemoryData('trainingSets', trainingSet);
      return trainingSet;
    }
  }

  /// Creates multiple training sets in a single batch operation
  /// This method is optimized for bulk imports and significantly reduces
  /// the number of HTTP requests compared to creating sets individually.
  ///
  /// [trainingSets] - List of training set data to create. Each item should contain:
  ///   - exerciseId, date, weight, repetitions, setType
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
                if (ts.containsKey('phase')) 'phase': ts['phase'],
                if (ts.containsKey('myoreps')) 'myoreps': ts['myoreps'],
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
          if (ts.containsKey('phase')) 'phase': ts['phase'],
          if (ts.containsKey('myoreps')) 'myoreps': ts['myoreps'],
        };
        _dataService.addToInMemoryData('trainingSets', trainingSet);
        createdSets.add(trainingSet);
      }
      return createdSets;
    }
  }

  /// Deletes a training set by its ID
  /// [id] - The unique identifier of the training set to delete
  Future<void> deleteTrainingSet(int id) async {
    await _dataService.deleteData(
      'trainingSets',
      id,
      () async => await api.TrainingSetService().deleteTrainingSet(id),
    );
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

  /// Optimized batch function to get last training days and highest weights for multiple exercises
  /// This replaces the functionality from database.dart for better integration
  Future<Map<String, Map<String, dynamic>>> getLastTrainingDaysForExercises(
      List<String> exerciseNames) async {
    try {
      if (isLoggedIn) {
        // Use the optimized API endpoint
        final lastDates = await api.TrainingSetService()
            .getLastTrainingDatesPerExercise(userName: userName);

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
      } else {
        // Keep the existing logic for offline mode
        try {
          final trainingSets = await getTrainingSets();
          Map<String, Map<String, dynamic>> result = {};
          final now = DateTime.now();

          // Initialize result for all requested exercises
          for (String exerciseName in exerciseNames) {
            result[exerciseName] = {
              'lastTrainingDate': now,
              'highestWeight': 0.0,
            };
          }

          // Process training sets to find last date and highest weight for each exercise
          for (var trainingSet in trainingSets) {
            final exerciseName = trainingSet['exercise_name'] as String?;
            final dateString = trainingSet['date'] as String?;
            final setType = trainingSet['set_type'] as int? ?? 0;
            final weight = (trainingSet['weight'] as num?)?.toDouble() ?? 0.0;

            // Only count actual work sets (set_type > 0), skip warmups
            if (exerciseName != null &&
                dateString != null &&
                setType > 0 &&
                exerciseNames.contains(exerciseName)) {
              try {
                final trainingDate = DateTime.parse(dateString);

                // Update if this is the first date for this exercise or if it's more recent
                if (trainingDate
                        .isAfter(result[exerciseName]!['lastTrainingDate']) ||
                    result[exerciseName]!['lastTrainingDate'] == now) {
                  result[exerciseName]!['lastTrainingDate'] = trainingDate;
                }

                // Update highest weight if this is higher
                if (weight > result[exerciseName]!['highestWeight']) {
                  result[exerciseName]!['highestWeight'] = weight;
                }
              } catch (e) {
                print('Error parsing date for exercise $exerciseName: $e');
              }
            }
          }

          return result;
        } catch (e) {
          print(
              'Error getting last training days and weights for exercises: $e');
          // Return fallback data for all exercises
          Map<String, Map<String, dynamic>> fallback = {};
          for (String exerciseName in exerciseNames) {
            fallback[exerciseName] = {
              'lastTrainingDate': DateTime.now(),
              'highestWeight': 0.0,
            };
          }
          return fallback;
        }
      }
    } catch (e) {
      print('Error getting last training days: $e');
      // Return fallback data for all exercises
      Map<String, Map<String, dynamic>> fallback = {};
      for (String exerciseName in exerciseNames) {
        fallback[exerciseName] = {
          'lastTrainingDate': DateTime.now(),
          'highestWeight': 0.0,
        };
      }
      return fallback;
    }
  }

  // Private method to enrich training sets with exercise names
  Future<List<dynamic>> _enrichTrainingSetsWithExerciseNames(
      List<dynamic> trainingSets) async {
    if (trainingSets.isEmpty) return trainingSets;

    try {
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
          print('Error parsing exercise data: $e');
        }
      }

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
          } else {
            print('DEBUG: Training set missing exercise_id: $trainingSetMap');
          }

          return trainingSetMap;
        } catch (e) {
          print('Error enriching training set: $e');
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

  // Clear method for settings screen
  Future<void> clearTrainingSets() async {
    if (isLoggedIn) {
      // OPTIMIZED: Use bulk delete endpoint instead of individual deletes
      try {
        await api.TrainingSetService().clearTrainingSets(userName: userName);
        print('Training sets cleared using bulk delete endpoint');
      } catch (e) {
        print('Error with bulk clear, falling back to individual deletes: $e');

        // Fallback to individual deletes
        final trainingSets = await _getTrainingSetsRaw();
        int deletedCount = 0;
        int errorCount = 0;

        for (var set in trainingSets) {
          if (set['id'] != null) {
            try {
              await deleteTrainingSet(set['id']);
              deletedCount++;
            } catch (e) {
              errorCount++;
              print('Warning: Failed to delete training set ${set['id']}: $e');
            }
          }
        }
        print(
            'Cleared training sets: $deletedCount deleted, $errorCount errors');
      }
    } else {
      // For offline mode, clear in-memory data
      _dataService.clearSpecificInMemoryData('trainingSets');
    }

    // Always clear in-memory data regardless of login status to prevent cache issues
    _dataService.clearSpecificInMemoryData('trainingSets');
    print('Cleared in-memory training sets cache');
  }

  // Helper method to get raw training sets without enrichment
  Future<List<dynamic>> _getTrainingSetsRaw() async {
    return await _dataService.getData(
      'trainingSets',
      // API call for authenticated users
      () async =>
          await api.TrainingSetService().getTrainingSets(userName: userName),
      // Fallback API call for non-authenticated users
      () async => await api.TrainingSetService()
          .getTrainingSets(userName: 'DefaultUser'),
    );
  }

  Future<List<dynamic>> getTrainingSetsByID(int exerciseId) async {
    return await _dataService.getData(
      'trainingSets',
      // API call for authenticated users
      () async => await api.TrainingSetService().getTrainingSetsForExercise(
          exerciseId: exerciseId, userName: userName),
      // Fallback API call for non-authenticated users
      () async => await api.TrainingSetService().getTrainingSetsForExercise(
          exerciseId: exerciseId, userName: 'DefaultUser'),
    );
  }
}
