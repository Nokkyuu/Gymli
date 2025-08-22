/// TrainingSetService - Manages individual training set records
///
/// This service handles all CRUD operations for training sets, which are records
/// of individual exercise instances within a workout.
///
library;

import 'dart:convert';
import 'api_base.dart';

class TrainingSetService {
  /// Retrieves all training sets for a user
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
    required int exerciseId,
    required String date,
    required double weight,
    required int repetitions,
    required int setType,
    String? phase,
    bool? myoreps,
  }) async {
    return json.decode(await createData('training_sets', {
      'exercise_id': exerciseId,
      'date': date,
      'weight': weight,
      'repetitions': repetitions,
      'set_type': setType,
      'phase': phase,
      'myoreps': myoreps,
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

    final response = await createData('training_sets/bulk', trainingSets);
    return json.decode(response).cast<Map<String, dynamic>>();
  }

  /// Updates an existing training set record
  /// [id] - The unique identifier of the training set to update
  /// [data] - Map containing the fields to update
  Future<void> updateTrainingSet(int id, Map<String, dynamic> data) async {
    updateData('training_sets/$id', data);
  }

  /// Retrieves last training dates per exercise for a user (optimized for performance)
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
