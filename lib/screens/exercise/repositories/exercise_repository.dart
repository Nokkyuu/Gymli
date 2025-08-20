import 'package:Gymli/utils/services/temp_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../../utils/api/api_models.dart';
import 'package:get_it/get_it.dart';
import '../../../utils/api/api.dart';


//TODO: Lokale cache logik für den exercise screen überarbeiten

/// Repository class that handles all exercise-related data operations
/// Provides a clean interface between the UI and data sources
class ExerciseRepository {
  // Cache for frequently accessed data
  List<ApiTrainingSet>? _cachedTrainingSets;
  List<ApiExercise>? _cachedExercises;
  DateTime? _lastCacheUpdate;
  int? _currentExerciseId;

  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  TempService get container => GetIt.I<TempService>();

  /// Get all training sets for a specific exercise
  Future<List<ApiTrainingSet>> getTrainingSetsForExercise() async {
    await _ensureCacheIsValid();

    if (_cachedTrainingSets == null) return [];

    return _cachedTrainingSets!
        .where((set) => set.exerciseId == _currentExerciseId)
        .toList();
  }

  /// Get today's training sets for a specific exercise
  Future<List<ApiTrainingSet>> getTodaysTrainingSetsForExercise( // TODO: Endpoint
      String exerciseName) async {
    final allSets = await getTrainingSetsForExercise();
    final today = DateTime.now();

    return allSets
        .where((set) =>
            set.date.day == today.day &&
            set.date.month == today.month &&
            set.date.year == today.year)
        .toList();
  }

  /// Get exercise details by name
  Future<ApiExercise?> getExerciseByName(String exerciseName) async {
    await _ensureCacheIsValid();

    if (_cachedExercises == null) return null;

    try {
      ApiExercise? exerciseData;
      try { 
        exerciseData = _cachedExercises!.firstWhere((item) => item.name == exerciseName);
      } catch (e) {
        exerciseData = null;
      }

      if (exerciseData == null) return null;

      return exerciseData;
    } catch (e) {
      if (kDebugMode) print('Error getting exercise by name: $e');
      return null;
    }
  }

  /// Create a new training set
  Future<ApiTrainingSet?> createTrainingSet({
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
    // String machineName = "",
  }) async {
    try {
      final createdSetData =
          await container.trainingSetService.createTrainingSet(
        exerciseId: exerciseId,
        date: date,
        weight: weight,
        repetitions: repetitions,
        setType: setType,
        phase: phase,
        myoreps: myoreps,
        // baseReps: baseReps,
        // maxReps: maxReps,
        // increment: increment,
        // machineName: machineName,
      );

      if (createdSetData == null) return null;

      // Get exercise data to construct the training set
      final exercise = await GetIt.I<ExerciseService>().getExerciseById(exerciseId);
      if (exercise == null) return null;

      final newSet = ApiTrainingSet(
        id: createdSetData['id'],
        userName: exercise.userName,
        exerciseId: exerciseId,
        exerciseName: exercise.name,
        date: DateTime.parse(date),
        weight: weight,
        repetitions: repetitions,
        setType: setType,
        phase: phase,
        myoreps: myoreps,
        // baseReps: baseReps,
        // maxReps: maxReps,
        // increment: increment,
      );

      // Update cache
      _cachedTrainingSets?.add(newSet);

      return newSet;
    } catch (e) {
      if (kDebugMode) print('Error creating training set: $e');
      return null;
    }
  }

  /// Delete a training set
  Future<bool> deleteTrainingSet(int trainingSetId) async {
    try {
      await container.trainingSetService.deleteTrainingSet(trainingSetId);

      // Update cache
      _cachedTrainingSets?.removeWhere((set) => set.id == trainingSetId);

      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting training set: $e');
      return false;
    }
  }

  /// Force refresh the cache
  Future<void> refreshCache() async {
    _cachedTrainingSets = null;
    _cachedExercises = null;
    _lastCacheUpdate = null;
    await _ensureCacheIsValid();
  }

  void setCurrentExerciseId(int exerciseId) {
    _currentExerciseId = exerciseId;
  }

  /// Private helper to ensure cache is valid and up-to-date
  Future<void> _ensureCacheIsValid() async {
    final now = DateTime.now();

    if (_lastCacheUpdate == null ||
        now.difference(_lastCacheUpdate!) > _cacheValidityDuration ||
        _cachedTrainingSets == null ||
        _cachedExercises == null) {
      await _updateCache();
    }
  }

  /// Private helper to update the cache
  Future<void> _updateCache() async {
    if (_currentExerciseId == null) {
      if (kDebugMode) print('No exercise ID set for cache update');
      return;
    }

    try {
      
      final __c = await container.getTrainingSetsByExerciseID(_currentExerciseId!);
      _cachedTrainingSets =
          __c.map((item) => ApiTrainingSet.fromJson(item)).toList();
      _cachedExercises = await GetIt.I<ExerciseService>().getExercises();
      _lastCacheUpdate = DateTime.now();
    } catch (e) {
      if (kDebugMode) print('Error updating cache: $e');
    }
  }
}
