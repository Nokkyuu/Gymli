import '../../../user_service.dart';
import '../../../api_models.dart';

/// Repository class that handles all exercise-related data operations
/// Provides a clean interface between the UI and data sources
class ExerciseRepository {
  final UserService _userService;

  // Cache for frequently accessed data
  List<ApiTrainingSet>? _cachedTrainingSets;
  List<dynamic>? _cachedExercises;
  DateTime? _lastCacheUpdate;

  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  ExerciseRepository({UserService? userService})
      : _userService = userService ?? UserService();

  /// Get all training sets for a specific exercise
  Future<List<ApiTrainingSet>> getTrainingSetsForExercise(
      String exerciseName) async {
    await _ensureCacheIsValid();

    if (_cachedTrainingSets == null) return [];

    return _cachedTrainingSets!
        .where((set) => set.exerciseName == exerciseName)
        .toList();
  }

  /// Get today's training sets for a specific exercise
  Future<List<ApiTrainingSet>> getTodaysTrainingSetsForExercise(
      String exerciseName) async {
    final allSets = await getTrainingSetsForExercise(exerciseName);
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
      final exerciseData = _cachedExercises!.firstWhere(
        (item) => item['name'] == exerciseName,
        orElse: () => <String, dynamic>{},
      );

      if (exerciseData.isEmpty) return null;

      return ApiExercise.fromJson(exerciseData);
    } catch (e) {
      print('Error getting exercise by name: $e');
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
    required int baseReps,
    required int maxReps,
    required double increment,
    String machineName = "",
  }) async {
    try {
      final createdSetData = await _userService.createTrainingSet(
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

      if (createdSetData == null) return null;

      // Get exercise data to construct the training set
      final exercise =
          await getExerciseByName(_getExerciseNameById(exerciseId));
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
        baseReps: baseReps,
        maxReps: maxReps,
        increment: increment,
      );

      // Update cache
      _cachedTrainingSets?.add(newSet);

      return newSet;
    } catch (e) {
      print('Error creating training set: $e');
      return null;
    }
  }

  /// Delete a training set
  Future<bool> deleteTrainingSet(int trainingSetId) async {
    try {
      await _userService.deleteTrainingSet(trainingSetId);

      // Update cache
      _cachedTrainingSets?.removeWhere((set) => set.id == trainingSetId);

      return true;
    } catch (e) {
      print('Error deleting training set: $e');
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
    try {
      final results = await Future.wait([
        _userService.getTrainingSets(),
        _userService.getExercises(),
      ]);

      _cachedTrainingSets =
          results[0].map((item) => ApiTrainingSet.fromJson(item)).toList();
      _cachedExercises = results[1];
      _lastCacheUpdate = DateTime.now();
    } catch (e) {
      print('Error updating cache: $e');
    }
  }

  /// Helper to get exercise name by ID (temporary solution)
  String _getExerciseNameById(int exerciseId) {
    if (_cachedExercises == null) return '';

    try {
      final exercise = _cachedExercises!.firstWhere(
        (item) => item['id'] == exerciseId,
        orElse: () => <String, dynamic>{},
      );
      return exercise['name'] ?? '';
    } catch (e) {
      return '';
    }
  }
}
