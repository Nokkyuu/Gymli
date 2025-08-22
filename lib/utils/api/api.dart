/// API Service Classes for Gymli Application
///
/// This file contains all the HTTP API service classes that handle communication
/// with the Gymli backend server. Each service class manages CRUD operations
/// for its respective entity type.
///
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show compute, kDebugMode;
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'api_cache.dart';
import 'api_models.dart';

const bool useCache = false; // Set to false to disable caching
// Main API base URL - Azure hosted backend service
const String baseUrl = kDebugMode
    //? 'http://127.0.0.1:8000'
    ? 'https://gymliapi-dev-f6c3gzfafgazanbf.germanywestcentral-01.azurewebsites.net'
    : 'https://gymliapi-gyg0ardqh5dadaba.germanywestcentral-01.azurewebsites.net';

// Map<String, String> defaultHeaders = {'Content-Type': 'application/json', 'X-API-Key': ApiConfig.apiKey! };
final http.Client _httpClient =
    http.Client(); //TODO: What does the http.Client do?
final ApiCache _cache = ApiCache();
Map<String, String> get defaultHeaders => ApiConfig.getHeaders();

Future<T> getData<T>(String url) async {
  // Check cache first
  if (useCache) {
    final cached = _cache.get<T>(url);
    if (cached != null) {
      if (kDebugMode) {
        print('DEBUG API: Cache hit for $url');
      }
      return cached;
    }
  }

  try {
    final response = await _httpClient
        .get(Uri.parse('$baseUrl/$url'), headers: defaultHeaders)
        .timeout(const Duration(seconds: 30)); // Add timeout

    if (response.statusCode == 200 || response.statusCode == 204) {
      // Parse JSON in isolate for large responses
      final decoded = await _parseJsonInIsolate(response.body);

      // Cache the result
      if (useCache) {
        _cache.put(url, decoded);
      }

      return decoded;
    } else {
      throw Exception("Failed to fetch $url: ${response.statusCode}");
    }
  } catch (e) {
    rethrow;
  }
}

// Add JSON parsing in isolate
Future<dynamic> _parseJsonInIsolate(String jsonString) async {
  if (jsonString.length > 1000) {
    // Parse large JSON in isolate to avoid blocking main thread
    return await compute(json.decode, jsonString);
  } else {
    return json.decode(jsonString);
  }
}

Future deleteData(String url) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/$url'),
    headers: defaultHeaders,
  );
  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception('Failed to delete');
  }

  // Invalidate related cache entries
  // _invalidateCacheForMutation(url);

  return response;
}

Future updateData<T>(String url, T data) async {
  final response = await http.put(Uri.parse('$baseUrl/$url'),
      headers: defaultHeaders, body: json.encode(data));
  if (response.statusCode != 200) {
    throw Exception('Failed to update');
  }

  // Invalidate related cache entries
  // _invalidateCacheForMutation(url);

  return response;
}

Future createData<T>(String url, T data) async {
  // Invalidate related cache entries
  // _invalidateCacheForMutation(url);
  final response = await http.post(Uri.parse('$baseUrl/$url'),
      headers: defaultHeaders, body: json.encode(data));
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to create');
  }

  // Invalidate related cache entries
  // _invalidateCacheForMutation(url);

  return response.body;
}

void _invalidateCacheForMutation(String url) {
  if (kDebugMode) {
    print('DEBUG API: Invalidating cache for $url');
  }
  // Smart cache invalidation based on the endpoint
  if (url.contains('exercises')) {
    _cache.invalidateByPattern('exercises');
  } else if (url.contains('workouts')) {
    _cache.invalidateByPattern('workouts');
    _cache.invalidateByPattern('workout_units');
  } else if (url.contains('training_sets')) {
    _cache.invalidateByPattern('training_sets');
  } else if (url.contains('activities')) {
    _cache.invalidateByPattern('activities');
    _cache.invalidateByPattern('activity_logs');
  } else if (url.contains('food')) {
    _cache.invalidateByPattern('foods');
    _cache.invalidateByPattern('food_logs');
  } else if (url.contains('calendar')) {
    _cache.invalidateByPattern('calendar');
    _cache.invalidateByPattern('periods');
  } else {
    // Fallback: clear everything for unknown endpoints
    _cache.clear();
  }
}

// Add this function to be called when user logs in
void clearApiCache() {
  _cache.clear();
}

//----------------- Exercise Service -----------------//
/// ExerciseService - Manages exercise definitions and data
/// This service handles all CRUD operations for exercises, which are used
/// in workout planning and tracking.
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

//----------------- Workout Service -----------------//

/// WorkoutService - Manages workout templates and data
///
/// This service handles all CRUD operations for workouts, which are templates
/// for user training sessions.
class WorkoutService {
  /// Retrieves all workouts for a user
  /// [userName] - The username to fetch workouts for
  /// Returns a list of workout objects
  Future<List<dynamic>> getWorkouts() async {
    return getData<List<dynamic>>('workouts');
  }

  /// Retrieves a specific workout by its ID
  /// [id] - The unique identifier of the workout
  /// Returns a map containing workout details
  Future<Map<String, dynamic>> getWorkoutById(int id) async {
    return getData<Map<String, dynamic>>('workouts/$id');
  }

  /// don't use this, use service_containers createWorkout to create Workouts to connect the Workout with the respective Workout Units
  Future<Map<String, dynamic>> createWorkout({
    required String name,
    // Add other required fields as needed
  }) async {
    return json.decode(await createData('workouts', {'name': name}));
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
  Future<List<dynamic>> getTrainingSets() async {
    return getData<List<dynamic>>('training_sets');
  }

  Future<List<dynamic>> getTrainingSetsByExerciseID(
      {required int exerciseId}) async {
    return getData<List<dynamic>>('training_sets/exercise/$exerciseId');
  }

  /// Retrieves a specific training set by its ID
  /// [id] - The unique identifier of the training set
  /// Returns a map containing training set details
  Future<Map<String, dynamic>> getTrainingSetById(int id) async {
    return getData<Map<String, dynamic>>('training_sets/$id');
  }

  /// Creates a new training set record
  Future<Map<String, dynamic>> createTrainingSet({
    //required String userName,
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
    return json.decode(await createData('training_sets', {
      //'user_name': userName,
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
              //'user_name': userName,
              ...ts,
            })
        .toList();
    final response =
        await createData('training_sets/bulk', trainingSetsWithUser);
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
  Future<Map<String, String>> getLastTrainingDatesPerExercise() async {
    final response =
        await getData<Map<String, dynamic>>('training_sets/last_dates');
    return response.map((key, value) => MapEntry(key, value.toString()));
  }

  /// Deletes a training set record
  /// [id] - The unique identifier of the training set to delete
  Future<void> deleteTrainingSet(int id) async {
    deleteData('training_sets/$id');
  }

  /// Clears all training sets for a specific user using bulk delete endpoint
  /// This is much more efficient than deleting individual training sets
  Future<Map<String, dynamic>> clearTrainingSets() async {
    final response = await deleteData('training_sets/bulk_clear');
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
  Future<List<dynamic>> getWorkoutUnits() async {
    return getData<List<dynamic>>('workout_units');
  }

  /// Retrieves a specific workout unit by its ID
  /// [id] - The unique identifier of the workout unit
  /// Returns a map containing workout unit details
  Future<Map<String, dynamic>> getWorkoutUnitById(int id) async {
    return getData<Map<String, dynamic>>('workout_units/$id');
  }

  /// Creates a new workout unit record
  Future<void> createWorkoutUnit({
    //required String userName,
    required int workoutId,
    required int exerciseId,
    required int warmups,
    required int worksets,
    required int dropsets,
    required int type,
  }) async {
    createData('workout_units', {
      //'user_name': userName,
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
  /// Retrieves all activities for a user
  /// [userName] - The username to fetch activities for
  /// Returns a list of activity objects
  Future<List<dynamic>> getActivities() async {
    return getData<List<dynamic>>('activities');
  }

  /// Creates a new custom activity for a user
  Future<Map<String, dynamic>> createActivity({
    //required String userName,
    required String name,
    required double kcalPerHour,
  }) async {
    return json.decode(await createData('activities', {
      //'user_name': userName,
      'name': name,
      'kcal_per_hour': kcalPerHour,
    }));
  }

  /// Updates an existing activity
  Future<Map<String, dynamic>> updateActivity({
    required int activityId,
    //required String userName,
    required String name,
    required double kcalPerHour,
  }) async {
    final response = await updateData(
        'activities/$activityId', {'name': name, 'kcal_per_hour': kcalPerHour});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update activity: ${response.body}');
    }
  }

  /// Deletes an activity
  Future<void> deleteActivity({
    required int activityId,
    //required String userName,
  }) async {
    final response = await deleteData('activities/$activityId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete activity: ${response.body}');
    }
  }

  /// Retrieves activity logs with optional filtering
  Future<List<dynamic>> getActivityLogs({
    //required String userName,
    String? activityName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '/activity_logs';
    if (activityName != null) {
      url += '&activity_name=${Uri.encodeComponent(activityName)}';
    }
    if (startDate != null) {
      url += '&start_date=${startDate.toIso8601String()}';
    }
    if (endDate != null) {
      url += '&end_date=${endDate.toIso8601String()}';
    }
    return getData<List<dynamic>>(url);
  }

  /// Creates a new activity log entry
  Future<Map<String, dynamic>> createActivityLog({
    //required String userName,
    required String activityName,
    required DateTime date,
    required int durationMinutes,
    String? notes,
  }) async {
    return json.decode(await createData('activity_logs', {
      //'user_name': userName,
      'activity_name': activityName,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'notes': notes,
    }));
  }

  /// Retrieves activity statistics for a user
  Future<Map<String, dynamic>> getActivityStats({
    //required String userName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '/activity_logs/stats?';
    if (startDate != null) {
      url += '&start_date=${startDate.toIso8601String()}';
    }
    if (endDate != null) {
      url += '&end_date=${endDate.toIso8601String()}';
    }
    return getData<Map<String, dynamic>>(url);
  }

  /// Deletes an activity log entry
  Future<void> deleteActivityLog({
    required int logId,
    //required String userName,
  }) async {
    final response = await deleteData('activity_logs/$logId');
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
  Future<List<dynamic>> getFoods() async {
    return getData<List<dynamic>>('foods');
  }

  /// Creates a new food item
  Future<Map<String, dynamic>> createFood({
    // required String userName,
    required String name,
    required double kcalPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    String? notes,
  }) async {
    return json.decode(await createData('foods', {
      //'user_name': userName,
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
    //required String userName,
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
              //'user_name': userName,
              ...food,
            })
        .toList();
    return json.decode(await createData('foods/bulk', foodsWithUser));
  }

  Future<Map<String, dynamic>> clearFoods() async {
    final response = await deleteData('foods/bulk_clear');
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
    //required String userName,
  }) async {
    final response = await deleteData('foods/$foodId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete food: ${response.body}');
    }
  }

  /// Retrieves food logs with optional filtering
  Future<List<dynamic>> getFoodLogs({
    //required String userName,
    String? foodName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '/food_logs?';

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
    //required String userName,
    required String foodName,
    required DateTime date,
    required double grams,
    required double kcalPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
  }) async {
    return json.decode(await createData('food_logs', {
      // 'user_name': userName,
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
    //required String userName,
  }) async {
    final response = await deleteData('food_logs/$logId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete food log: ${response.body}');
    }
  }
}

class CalendarService {
  Future<List<dynamic>> getCalendarNotes() async {
    return getData<List<dynamic>>('calendar_notes');
  }

  Future<Map<String, dynamic>> createCalendarNote({
    //required String userName,
    required DateTime date,
    required String note,
  }) async {
    return json.decode(await createData('calendar_notes', {
      //'user_name': userName,
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
    //required String userName,
    required DateTime date,
    required String note,
  }) async {
    final response = await updateData(
        'calendar_notes/$id', {'date': date.toIso8601String(), 'note': note});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update calendar note');
    }
  }

  Future<List<dynamic>> getCalendarWorkouts() async {
    return getData<List<dynamic>>('calendar_workouts');
  }

  Future<Map<String, dynamic>> createCalendarWorkout({
    //required String userName,
    required DateTime date,
    required String workout,
  }) async {
    return json.decode(await createData('calendar_workouts', {
      //'user_name': userName,
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

  Future<List<dynamic>> getCalendarPeriods() async {
    return getData<List<dynamic>>('periods');
  }

  Future<Map<String, dynamic>> createCalendarPeriod({
    //required String userName,
    required String type,
    required DateTime start_date,
    required DateTime end_date,
  }) async {
    return json.decode(await createData('periods', {
      //'user_name': userName,
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
