/// API Service Classes for Gymli Application
///
/// This file contains all the HTTP API service classes that handle communication
/// with the Gymli backend server. Each service class manages CRUD operations
/// for its respective entity type.
///
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

// Main API base URL - Azure hosted backend service
const String baseUrl = 'https://gymliapi-gyg0ardqh5dadaba.germanywestcentral-01.azurewebsites.net';


Map<String, String> defaultHeaders = {'Content-Type': 'application/json', 'X-API-Key': ApiConfig.apiKey! };

Future<T> getData<T>(String url) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/$url'), headers: defaultHeaders);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded;
    } else { throw Exception("Failed to fetch"); }
  } catch (e) {
    // TODO: MAYBE LOGGING!
    rethrow;
  }
}

Future deleteData(String url) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/$url'), headers: defaultHeaders,
  );
  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception('Failed to delete');
  }
  return response;
}

Future updateData<T>(String url, T data) async {
  final response = await http.put(Uri.parse('$baseUrl/$url'), headers: defaultHeaders, body: json.encode(data) );
  if (response.statusCode != 200) {
    throw Exception('Failed to update');
  }
  return response;
}

Future createData<T>(String url, T data) async {
  final response = await http.post(
      Uri.parse('$baseUrl/$url'), headers: defaultHeaders, body: json.encode(data) );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create');
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
    return getData<List<dynamic>>('exercises?user_name=$userName');
  }

  /// Retrieves a specific exercise by its ID
  /// [id] - The unique identifier of the exercise
  /// Returns a map containing exercise details
  Future<Map<String, dynamic>> getExerciseById(int id) async {
    return getData<Map<String, dynamic>>('exercises/$id');
  }

  /// Creates a new exercise record
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
    required double forearms,
    required double calves,
  }) async {
    // Add debug logging to see exactly what's being sent
    // print('DEBUG API: Creating exercise "${name}" with forearms value: $forearms');
    // print('DEBUG API: Full request body: ${json.encode(requestBody)}');

    createData('exercises', {
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
      'forearms': forearms,
      'calves': calves
    });
    // print('DEBUG API: Response status: ${response.statusCode}');
    // print('DEBUG API: Response body: ${response.body}');
  }

  /// Updates an existing exercise record
  /// [id] - The unique identifier of the exercise to update
  /// [data] - Map containing the fields to update
  Future<void> updateExercise(int id, Map<String, dynamic> data) async {
    updateData('exercises/$id', data);
  }

  /// Deletes an exercise record
  /// [id] - The unique identifier of the exercise to delete
  Future<void> deleteExercise(int id) async {
    return deleteData('exercises/$id');
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
    return getData<List<dynamic>>('workouts?user_name=$userName');
  }

  /// Retrieves a specific workout by its ID
  /// [id] - The unique identifier of the workout
  /// Returns a map containing workout details
  Future<Map<String, dynamic>> getWorkoutById(int id) async {
    return getData<Map<String, dynamic>>('workouts/$id');
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
    return json.decode(await createData('workouts', {'user_name': userName, 'name': name}));
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
    return getData<List<dynamic>>('training_sets?user_name=$userName');
  }

  /// Retrieves a specific training set by its ID
  /// [id] - The unique identifier of the training set
  /// Returns a map containing training set details
  Future<Map<String, dynamic>> getTrainingSetById(int id) async {
    return getData<Map<String, dynamic>>('training_sets/$id');
  }

  /// Creates a new training set record
  Future<Map<String, dynamic>> createTrainingSet({
    required String userName,
    required int exerciseId,
    required String date,
    required double weight,
    required int repetitions,
    required int setType,
    String? phase,
    bool? myoreps,
    // required int baseReps,
    // required int maxReps,
    // required double increment,
    // String? machineName,
  }) async {
    return json.decode(await createData('training_sets', 
    {
        'user_name': userName,
        'exercise_id': exerciseId,
        'date': date,
        'weight': weight,
        'repetitions': repetitions,
        'set_type': setType,
        'phase': phase,
        'myoreps': myoreps,
        // 'base_reps': baseReps,
        // 'max_reps': maxReps,
        // 'increment': increment,
        // 'machine_name': machineName,
      }));
  }

  /// Creates multiple training sets in a single batch operation
  Future<List<Map<String, dynamic>>> createTrainingSetsBulk({
    required String userName,
    required List<Map<String, dynamic>> trainingSets,
  }) async {
    if (trainingSets.isEmpty) { throw Exception('Training sets list cannot be empty');}
    if (trainingSets.length > 1000) { throw Exception('Cannot create more than 1000 training sets in a single request'); }
    // Ensure all training sets have the required user_name field
    final trainingSetsWithUser = trainingSets.map((ts) => {'user_name': userName, ...ts,}).toList();
    final response = await createData('training_sets/bulk', trainingSetsWithUser);
    return json.decode(response.body).cast<Map<String, dynamic>>();
  }

  /// Updates an existing training set record
  /// [id] - The unique identifier of the training set to update
  /// [data] - Map containing the fields to update
  Future<void> updateTrainingSet(int id, Map<String, dynamic> data) async {
    updateData('training_sets/$id', data);
  }

  /// Retrieves last training dates per exercise for a user (optimized for performance)
  /// [userName] - The username to fetch last training dates for
  /// Returns a map of exercise names to their last training dates
  Future<Map<String, String>> getLastTrainingDatesPerExercise(
      {required String userName}) async {
    final response = await getData<Map<String, dynamic>>('training_sets/last_dates?user_name=$userName');
    return response.map((key, value) => MapEntry(key, value.toString()));
  }

  /// Deletes a training set record
  /// [id] - The unique identifier of the training set to delete
  Future<void> deleteTrainingSet(int id) async {
    deleteData('training_sets/$id');
  }

  /// Clears all training sets for a specific user using bulk delete endpoint
  /// This is much more efficient than deleting individual training sets
  Future<Map<String, dynamic>> clearTrainingSets({
    required String userName,
  }) async {
    final response = await deleteData('training_sets/bulk_clear?user_name=$userName');
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
    return getData<List<dynamic>>('workout_units?user_name=$userName');
  }

  /// Retrieves a specific workout unit by its ID
  /// [id] - The unique identifier of the workout unit
  /// Returns a map containing workout unit details
  Future<Map<String, dynamic>> getWorkoutUnitById(int id) async {
    return getData<Map<String, dynamic>>('workout_units/$id');
  }

  /// Creates a new workout unit record
  Future<void> createWorkoutUnit({
    required String userName,
    required int workoutId,
    required int exerciseId,
    required int warmups,
    required int worksets,
    required int dropsets,
    required int type,
  }) async {
    createData('workout_units', {
      'user_name': userName,
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

//----------------- Activity Service -----------------//

/// ActivityService - Manages activity types and activity logs
///
/// This service handles all CRUD operations for activities and activity logs,
/// which are used for tracking cardio and other physical activities.
class ActivityService {
  /// Initializes default activities for a new user
  /// [userName] - The username to initialize activities for
  /// Returns a success message with count of initialized activities
  Future<Map<String, dynamic>> initializeUserActivities({
    required String userName,
  }) async {
    return json.decode(await createData('users/$userName/initialize_activities', {}));
  }

  /// Retrieves all activities for a user
  /// [userName] - The username to fetch activities for
  /// Returns a list of activity objects
  Future<List<dynamic>> getActivities({required String userName}) async {
    return getData<List<dynamic>>('activities?user_name=$userName');
  }

  /// Creates a new custom activity for a user
  Future<Map<String, dynamic>> createActivity({
    required String userName,
    required String name,
    required double kcalPerHour,
  }) async {
    return json.decode(await createData('activities', {
      'user_name': userName,
      'name': name,
      'kcal_per_hour': kcalPerHour,
    }));
  }

  /// Updates an existing activity
  Future<Map<String, dynamic>> updateActivity({
    required int activityId,
    required String userName,
    required String name,
    required double kcalPerHour,
  }) async {
    final response = await updateData('activities/$activityId?user_name=$userName',
      {'name': name, 'kcal_per_hour': kcalPerHour}
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update activity: ${response.body}');
    }
  }

  /// Deletes an activity
  Future<void> deleteActivity({
    required int activityId,
    required String userName,
  }) async {
    final response = await deleteData('activities/$activityId?user_name=$userName');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete activity: ${response.body}');
    }
  }

  /// Retrieves activity logs with optional filtering
  Future<List<dynamic>> getActivityLogs({
    required String userName,
    String? activityName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '$baseUrl/activity_logs?user_name=$userName';
    if (activityName != null) { url += '&activity_name=${Uri.encodeComponent(activityName)}'; }
    if (startDate != null) { url += '&start_date=${startDate.toIso8601String()}'; }
    if (endDate != null) { url += '&end_date=${endDate.toIso8601String()}'; }
    return getData<List<dynamic>>(url);
  }

  /// Creates a new activity log entry
  Future<Map<String, dynamic>> createActivityLog({
    required String userName,
    required String activityName,
    required DateTime date,
    required int durationMinutes,
    String? notes,
  }) async {
    return json.decode(await createData('activity_logs', {
      'user_name': userName,
      'activity_name': activityName,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'notes': notes,
    }));
  }

  /// Retrieves activity statistics for a user
  Future<Map<String, dynamic>> getActivityStats({
    required String userName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '$baseUrl/activity_logs/stats?user_name=$userName';
    if (startDate != null) { url += '&start_date=${startDate.toIso8601String()}'; }
    if (endDate != null) { url += '&end_date=${endDate.toIso8601String()}'; }
    return getData<Map<String, dynamic>>(url);
  }

  /// Deletes an activity log entry
  Future<void> deleteActivityLog({
    required int logId,
    required String userName,
  }) async {
    final response = await deleteData('activity_logs/$logId?user_name=$userName');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete activity log: ${response.body}');
    }
  }
}

//----------------- Food Service -----------------//

/// FoodService - Manages food items and food logs
///
/// This service handles all CRUD operations for food items and food logs,
/// which are used for nutrition tracking and calorie management.
class FoodService {
  /// Retrieves all food items for a user
  /// [userName] - The username to fetch food items for
  /// Returns a list of food item objects
  Future<List<dynamic>> getFoods({required String userName}) async {
    return getData<List<dynamic>>('foods?user_name=$userName');
  }

  /// Creates a new food item
  Future<Map<String, dynamic>> createFood({
    required String userName,
    required String name,
    required double kcalPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    String? notes,
  }) async {
    return json.decode(await createData('foods', {
      'user_name': userName,
      'name': name,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'notes': notes,
    }));
  }

  /// Creates multiple food items in a single batch operation
  Future<List<Map<String, dynamic>>> createFoodsBulk({
    required String userName,
    required List<Map<String, dynamic>> foods,
  }) async {
    if (foods.isEmpty) {
      throw Exception('Food items list cannot be empty');
    }

    if (foods.length > 1000) {
      throw Exception(
          'Cannot create more than 1000 food items in a single request');
    }

    // Ensure all food items have the required user_name field
    final foodsWithUser = foods
        .map((food) => {
              'user_name': userName,
              ...food,
            })
        .toList();
    return json.decode(await createData('foods/bulk', foodsWithUser));
  }

  Future<Map<String, dynamic>> clearFoods({
    required String userName,
  }) async {
    final response = await deleteData('foods/bulk_clear?user_name=$userName');
    if (response.statusCode == 200 || response.statusCode == 204) {
      final result = response.body.isNotEmpty
          ? json.decode(response.body)
          : {'message': 'Food items cleared successfully'};
      return result;
    } else {
      throw Exception(
          'Failed to clear food items: ${response.statusCode} ${response.body}');
    }
  }

  /// Deletes a food item
  Future<void> deleteFood({
    required int foodId,
    required String userName,
  }) async {
    final response = await deleteData('foods/$foodId?user_name=$userName');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete food: ${response.body}');
    }
  }

  /// Retrieves food logs with optional filtering
  Future<List<dynamic>> getFoodLogs({
    required String userName,
    String? foodName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '$baseUrl/food_logs?user_name=$userName';

    if (foodName != null) {
      url += '&food_name=${Uri.encodeComponent(foodName)}';
    }
    if (startDate != null) {
      url += '&start_date=${startDate.toIso8601String()}';
    }
    if (endDate != null) {
      url += '&end_date=${endDate.toIso8601String()}';
    }

    return getData<List<dynamic>>(url);
  }

  /// Creates a new food log entry
  Future<Map<String, dynamic>> createFoodLog({
    required String userName,
    required String foodName,
    required DateTime date,
    required double grams,
    required double kcalPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
  }) async {
    return json.decode(await createData('food_logs', {
      'user_name': userName,
      'food_name': foodName,
      'date': date.toIso8601String(),
      'grams': grams,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
    }));
  }

  /// Deletes a food log entry
  Future<void> deleteFoodLog({
    required int logId,
    required String userName,
  }) async {
    final response = await deleteData('food_logs/$logId?user_name=$userName');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete food log: ${response.body}');
    }
  }
}

class CalendarNoteService {
  Future<List<dynamic>> getCalendarNotes({required String userName}) async {
    return getData<List<dynamic>>('calendar_notes?user_name=$userName');
  }

  Future<Map<String, dynamic>> createCalendarNote({
    required String userName,
    required DateTime date,
    required String note,
  }) async {
    return json.decode(await createData('calendar_notes', {
      'user_name': userName,
      'date': date.toIso8601String(),
      'note': note,
    }));
  }

  Future<void> deleteCalendarNote(int id) async {
    final response = await deleteData('calendar_notes/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete calendar note');
    }
  }

  Future<Map<String, dynamic>> updateCalendarNote({
    required int id,
    required String userName,
    required DateTime date,
    required String note,
  }) async {
    final response = await updateData('calendar_notes/$id',
    {'user_name': userName, 'date': date.toIso8601String(), 'note': note}
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update calendar note');
    }
  }
}

class CalendarWorkoutService {
  Future<List<dynamic>> getCalendarWorkouts({required String userName}) async {
    return getData<List<dynamic>>('calendar_workouts?user_name=$userName');
  }

  Future<Map<String, dynamic>> createCalendarWorkout({
    required String userName,
    required DateTime date,
    required String workout,
  }) async {
    return json.decode(await createData('calendar_workouts', {
      'user_name': userName,
      'date': date.toIso8601String(),
      'workout': workout,
    }));
  }

  Future<void> deleteCalendarWorkout(int id) async {
    final response = await deleteData('calendar_workouts/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete calendar workout');
    }
  }
}

class CalendarPeriodService {
  Future<List<dynamic>> getCalendarPeriods({required String userName}) async {
    return getData<List<dynamic>>('periods?user_name=$userName');
  }

  Future<Map<String, dynamic>> createCalendarPeriod({
    required String userName,
    required String type,
    required DateTime start_date,
    required DateTime end_date,
  }) async {
    return json.decode(await createData('periods', {
      'user_name': userName,
      'type': type,
      'start_date': start_date.toIso8601String(),
      'end_date': end_date.toIso8601String(),
    }));
  }

  Future<void> deleteCalendarPeriod(int id) async {
    final response = await deleteData('periods/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete calendar period');
    }
  }
}
