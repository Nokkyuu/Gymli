/// TrainingSetService - Manages individual training set records
///
/// This service handles all CRUD operations for training sets, which are records
/// of individual exercise instances within a workout.
///
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../api/api_base.dart';
import '../models/data_models.dart';

class TrainingSetService {
  /// Retrieves all training sets for a user
  /// Returns a list of training set objects
  Future<List<TrainingSet>> getTrainingSets() async {
    print("DEBUG: Fetching all training sets from API");
    final data = await getData<List<dynamic>>('training_sets');
    return data.map((item) => TrainingSet.fromJson(item)).toList();
  }

  Future<List<TrainingSet>> getTrainingSetsByExerciseID({required int exerciseId}) async {
    final data = await getData<List<dynamic>>('training_sets/exercise/$exerciseId');
    final length = data.length;
    if (kDebugMode) { print("DEBUG: Fetching $length training sets for exercise ID $exerciseId from API"); }
    return data.map((item) => TrainingSet.fromJson(item)).toList();
  }

  Future<TrainingSet?> getTrainingSetById(int id) async {
    final data = await getData<Map<String, dynamic>>('training_sets/$id');
    return data != null ? TrainingSet.fromJson(data) : null;
  }

  /// Creates a new training set record
  Future<TrainingSet> createTrainingSet({
    required int exerciseId,
    required String date,
    required double weight,
    required int repetitions,
    required int setType,
    String? phase,
    bool? myoreps,
  }) async {
    return TrainingSet.fromJson(await createData('training_sets', {
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
  Future<List<TrainingSet>> createTrainingSetsBulk({
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
    return (response as List)
        .map((item) => TrainingSet.fromJson(item))
        .toList();
  }

  Future<TrainingSet> updateTrainingSet(
      int id, Map<String, dynamic> data) async {
    final response = await updateData('training_sets/$id', data);
    return TrainingSet.fromJson(response);
  }

  /// Retrieves last training dates per exercise for a user (optimized for performance)
  /// Returns a map of exercise names to their last training dates
  Future<Map<String, Map<String, dynamic>>> getLastTrainingDatesPerExercise(
      List<String> exerciseNames) async {
    final response = await getData<Map<String, dynamic>>('training_sets/last_dates');
    final lastDates = response.map((key, value) => MapEntry(key, value.toString()));
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
      };
    }
    return result;
  }

//TODO: success response?
  Future<void> deleteTrainingSet(int id) async {
    deleteData('training_sets/$id');
  }

  /// Clears all training sets for a specific user using bulk delete endpoint
  /// This is much more efficient than deleting individual training sets
  Future<Map<String, dynamic>> clearTrainingSets() async {
    final response = await deleteData('training_sets/bulk_clear');
    if (response.statusCode == 200 || response.statusCode == 204) {
      final result = response.isNotEmpty
          ? json.decode(response)
          : {'message': 'Training sets cleared successfully'};
      return result;
    } else {
      throw Exception(
          'Failed to clear training sets: ${response.statusCode} ${response}');
    }
  }
}
