/// API Service Classes for Gymli Application
///
/// This file contains all the HTTP API service classes that handle communication
/// with the Gymli backend server. Each service class manages CRUD operations
/// for its respective entity type.
///
/// Services included:
/// - AnimalService: For animal data (testing/demo purposes)
/// - ExerciseService: For exercise definitions and management
/// - WorkoutService: For workout templates and management
/// - TrainingSetService: For individual training set records
/// - WorkoutUnitService: For workout unit associations
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

// Main API base URL - Azure hosted backend service
const String baseUrl =
    'https://gymliapi-gyg0ardqh5dadaba.germanywestcentral-01.azurewebsites.net/';

//----------------- Animals Service -----------------//

/// AnimalService - Demo/test service for API testing
///
/// This service provides basic CRUD operations for animal entities.
/// It's primarily used for testing API connectivity and functionality.
class AnimalService {
  /// Retrieves all animals from the API
  /// Returns a list of animal objects
  Future<List<dynamic>> getAnimals() async {
    final response = await http.get(Uri.parse('$baseUrl/animals'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load animals');
    }
  }

  /// Retrieves a specific animal by its ID
  /// [id] - The unique identifier of the animal
  /// Returns a map containing animal details
  Future<Map<String, dynamic>> getAnimalById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/animals/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch animal');
    }
  }

  /// Creates a new animal record
  /// [name] - The name of the animal
  /// [sound] - The sound the animal makes
  Future<void> createAnimal(String name, String sound) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animals'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'sound': sound}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create animal');
    }
  }

  /// Updates an existing animal record
  /// [id] - The unique identifier of the animal to update
  /// [data] - Map containing the fields to update
  Future<void> updateAnimal(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/animals/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update animal');
    }
  }

  /// Deletes an animal record
  /// [id] - The unique identifier of the animal to delete
  Future<void> deleteAnimal(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/animals/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete animal');
    }
  }
}

//----------------- Exercise Service -----------------//

/// ExerciseService - Manages exercise definitions and data
///
/// This service handles all CRUD operations for exercises, which are used
/// in workout planning and tracking.
class ExerciseService {
  /// Retrieves all exercises for a user
  /// [userName] - The username to fetch exercises for
  /// Returns a list of exercise objects
  Future<List<dynamic>> getExercises({required String userName}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/exercises?user_name=$userName'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load exercises');
    }
  }

  /// Retrieves a specific exercise by its ID
  /// [id] - The unique identifier of the exercise
  /// Returns a map containing exercise details
  Future<Map<String, dynamic>> getExerciseById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/exercises/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch exercise');
    }
  }

  /// Creates a new exercise record
  /// [userName] - The username associated with the exercise
  /// [name] - The name of the exercise
  /// [type] - The type/category of the exercise
  /// [defaultRepBase] - Default base repetitions
  /// [defaultRepMax] - Default maximum repetitions
  /// [defaultIncrement] - Default increment value for progression
  /// [pectoralisMajor] - Targeting pectoralis major muscle (percentage)
  /// [trapezius] - Targeting trapezius muscle (percentage)
  /// [biceps] - Targeting biceps muscle (percentage)
  /// [abdominals] - Targeting abdominals muscle (percentage)
  /// [frontDelts] - Targeting front deltoids muscle (percentage)
  /// [deltoids] - Targeting deltoids muscle (percentage)
  /// [backDelts] - Targeting rear deltoids muscle (percentage)
  /// [latissimusDorsi] - Targeting latissimus dorsi muscle (percentage)
  /// [triceps] - Targeting triceps muscle (percentage)
  /// [gluteusMaximus] - Targeting gluteus maximus muscle (percentage)
  /// [hamstrings] - Targeting hamstrings muscle (percentage)
  /// [quadriceps] - Targeting quadriceps muscle (percentage)
  /// [calves] - Targeting calves muscle (percentage)
  Future<void> createExercise({
    required String userName,
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
    final response = await http.post(
      Uri.parse('$baseUrl/exercises'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
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
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create exercise');
    }
  }

  /// Updates an existing exercise record
  /// [id] - The unique identifier of the exercise to update
  /// [data] - Map containing the fields to update
  Future<void> updateExercise(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/exercises/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update exercise');
    }
  }

  /// Deletes an exercise record
  /// [id] - The unique identifier of the exercise to delete
  Future<void> deleteExercise(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/exercises/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete exercise');
    }
  }
}

//----------------- Workout Service -----------------//

/// WorkoutService - Manages workout templates and data
///
/// This service handles all CRUD operations for workouts, which are templates
/// for user training sessions.
class WorkoutService {
  /// Retrieves all workouts for a user
  /// [userName] - The username to fetch workouts for
  /// Returns a list of workout objects
  Future<List<dynamic>> getWorkouts({required String userName}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/workouts?user_name=$userName'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load workouts');
    }
  }

  /// Retrieves a specific workout by its ID
  /// [id] - The unique identifier of the workout
  /// Returns a map containing workout details
  Future<Map<String, dynamic>> getWorkoutById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/workouts/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch workout');
    }
  }

  /// Creates a new workout record
  /// [userName] - The username associated with the workout
  /// [name] - The name of the workout
  /// Returns the created workout data including its ID
  Future<Map<String, dynamic>> createWorkout({
    required String userName,
    required String name,
    // Add other required fields as needed
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workouts'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
        'name': name,
        // Add additional fields here
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create workout');
    }
    return json.decode(response.body);
  }

  /// Updates an existing workout record
  /// [id] - The unique identifier of the workout to update
  /// [data] - Map containing the fields to update
  Future<void> updateWorkout(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workouts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update workout');
    }
  }

  /// Deletes a workout record
  /// [id] - The unique identifier of the workout to delete
  Future<void> deleteWorkout(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/workouts/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete workout');
    }
  }
}

//----------------- Training Set Service -----------------//

/// TrainingSetService - Manages individual training set records
///
/// This service handles all CRUD operations for training sets, which are records
/// of individual exercise instances within a workout.
class TrainingSetService {
  /// Retrieves all training sets for a user
  /// [userName] - The username to fetch training sets for
  /// Returns a list of training set objects
  Future<List<dynamic>> getTrainingSets({required String userName}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/training_sets?user_name=$userName'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load training sets');
    }
  }

  /// Retrieves a specific training set by its ID
  /// [id] - The unique identifier of the training set
  /// Returns a map containing training set details
  Future<Map<String, dynamic>> getTrainingSetById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/training_sets/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch training set');
    }
  }

  /// Creates a new training set record
  /// [userName] - The username associated with the training set
  /// [exerciseId] - The ID of the exercise
  /// [date] - The date of the training session
  /// [weight] - The weight used in the training set
  /// [repetitions] - The number of repetitions
  /// [setType] - The type of set (e.g., warm-up, working set)
  /// [baseReps] - Base number of repetitions for the set
  /// [maxReps] - Maximum number of repetitions for the set
  /// [increment] - Increment value for progression
  /// [machineName] - Optional machine name used for the exercise
  Future<void> createTrainingSet({
    required String userName,
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
    final response = await http.post(
      Uri.parse('$baseUrl/training_sets'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
        'exercise_id': exerciseId,
        'date': date,
        'weight': weight,
        'repetitions': repetitions,
        'set_type': setType,
        'base_reps': baseReps,
        'max_reps': maxReps,
        'increment': increment,
        'machine_name': machineName,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create training set');
    }
  }

  /// Creates multiple training sets in a single batch operation
  /// This method is optimized for bulk imports and significantly reduces
  /// the number of HTTP requests compared to creating sets individually.
  ///
  /// [userName] - The username associated with all training sets
  /// [trainingSets] - List of training set data to create
  ///
  /// Returns a list of created training sets with their assigned IDs
  Future<List<Map<String, dynamic>>> createTrainingSetsBulk({
    required String userName,
    required List<Map<String, dynamic>> trainingSets,
  }) async {
    if (trainingSets.isEmpty) {
      throw Exception('Training sets list cannot be empty');
    }

    if (trainingSets.length > 1000) {
      throw Exception(
          'Cannot create more than 1000 training sets in a single request');
    }

    // Ensure all training sets have the required user_name field
    final trainingSetsWithUser = trainingSets
        .map((ts) => {
              'user_name': userName,
              ...ts,
            })
        .toList();

    final response = await http.post(
      Uri.parse('$baseUrl/training_sets/bulk'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(trainingSetsWithUser),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> responseData = json.decode(response.body);
      return responseData.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Failed to create training sets in bulk: ${response.body}');
    }
  }

  /// Updates an existing training set record
  /// [id] - The unique identifier of the training set to update
  /// [data] - Map containing the fields to update
  Future<void> updateTrainingSet(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/training_sets/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update training set');
    }
  }

  /// Retrieves last training dates per exercise for a user (optimized for performance)
  /// [userName] - The username to fetch last training dates for
  /// Returns a map of exercise names to their last training dates
  Future<Map<String, String>> getLastTrainingDatesPerExercise(
      {required String userName}) async {
    final response = await http.get(
        Uri.parse('$baseUrl/training_sets/last_dates?user_name=$userName'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      // Convert the response to Map<String, String> format
      return responseData.map((key, value) => MapEntry(key, value.toString()));
    } else {
      throw Exception('Failed to load last training dates');
    }
  }

  /// Deletes a training set record
  /// [id] - The unique identifier of the training set to delete
  Future<void> deleteTrainingSet(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/training_sets/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete training set');
    }
  }

  /// Clears all training sets for a specific user using bulk delete endpoint
  /// This is much more efficient than deleting individual training sets
  Future<Map<String, dynamic>> clearTrainingSets({
    required String userName,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/training_sets/bulk_clear?user_name=$userName'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      final result = response.body.isNotEmpty
          ? json.decode(response.body)
          : {'message': 'Training sets cleared successfully'};
      return result;
    } else {
      throw Exception(
          'Failed to clear training sets: ${response.statusCode} ${response.body}');
    }
  }
}

//----------------- Workout Unit Service -----------------//

/// WorkoutUnitService - Manages workout unit associations
///
/// This service handles all CRUD operations for workout units, which link exercises
/// to workouts and define their order and type within the workout.
class WorkoutUnitService {
  /// Retrieves all workout units for a user
  /// [userName] - The username to fetch workout units for
  /// Returns a list of workout unit objects
  Future<List<dynamic>> getWorkoutUnits({required String userName}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/workout_units?user_name=$userName'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load workout units');
    }
  }

  /// Retrieves a specific workout unit by its ID
  /// [id] - The unique identifier of the workout unit
  /// Returns a map containing workout unit details
  Future<Map<String, dynamic>> getWorkoutUnitById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/workout_units/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch workout unit');
    }
  }

  /// Creates a new workout unit record
  /// [userName] - The username associated with the workout unit
  /// [workoutId] - The ID of the workout
  /// [exerciseId] - The ID of the exercise
  /// [warmups] - The number of warm-up sets
  /// [worksets] - The number of work sets
  /// [dropsets] - The number of drop sets
  /// [type] - The type of workout unit (e.g., exercise, rest)
  Future<void> createWorkoutUnit({
    required String userName,
    required int workoutId,
    required int exerciseId,
    required int warmups,
    required int worksets,
    required int dropsets,
    required int type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workout_units'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'warmups': warmups,
        'worksets': worksets,
        'dropsets': dropsets,
        'type': type,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create workout unit');
    }
  }

  /// Updates an existing workout unit record
  /// [id] - The unique identifier of the workout unit to update
  /// [data] - Map containing the fields to update
  Future<void> updateWorkoutUnit(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workout_units/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update workout unit');
    }
  }

  /// Deletes a workout unit record
  /// [id] - The unique identifier of the workout unit to delete
  Future<void> deleteWorkoutUnit(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/workout_units/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete workout unit');
    }
  }
}
