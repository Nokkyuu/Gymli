/// Score Calculation Service for Gymli Application
///
/// This service manages score calculations for training sets by handling
/// exercise lookups and caching to avoid redundant data storage.
///
/// Key features:
/// - Exercise caching for efficient lookups
/// - Score calculation with proper exercise parameters
/// - Batch processing for multiple training sets

import 'package:Gymli/api_models.dart';
import 'package:Gymli/globals.dart';

class ScoreCalculationService {
  final Map<int, ApiExercise> _exerciseCache = {};

  /// Cache a single exercise for later lookup
  void cacheExercise(ApiExercise exercise) {
    if (exercise.id != null) {
      _exerciseCache[exercise.id!] = exercise;
    }
  }

  /// Cache multiple exercises at once
  void cacheExercises(List<ApiExercise> exercises) {
    for (final exercise in exercises) {
      cacheExercise(exercise);
    }
  }

  /// Calculate score for a single training set using cached exercise data
  double calculateScoreForSet(ApiTrainingSet trainingSet) {
    final exercise = _exerciseCache[trainingSet.exerciseId];
    if (exercise == null) {
      throw Exception(
          'Exercise not found for training set. Exercise ID: ${trainingSet.exerciseId}');
    }

    return calculateScoreWithExercise(trainingSet, exercise);
  }

  /// Calculate scores for multiple training sets
  List<double> calculateScoresForSets(List<ApiTrainingSet> trainingSets) {
    return trainingSets.map((set) => calculateScoreForSet(set)).toList();
  }

  /// Get cached exercise by ID
  ApiExercise? getExercise(int exerciseId) {
    return _exerciseCache[exerciseId];
  }

  /// Clear the exercise cache
  void clearCache() {
    _exerciseCache.clear();
  }

  /// Check if an exercise is cached
  bool hasExercise(int exerciseId) {
    return _exerciseCache.containsKey(exerciseId);
  }
}
