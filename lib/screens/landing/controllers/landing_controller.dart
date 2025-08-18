/// Landing Controller - Simplified without caching layer
library;

import 'package:flutter/foundation.dart';
import '../repositories/landing_repository.dart';
import '../models/landing_filter_state.dart';
import 'landing_filter_controller.dart';
import '../../../utils/api/api_models.dart';
import '../../../utils/globals.dart' as globals;

class LandingController extends ChangeNotifier {
  final LandingRepository _repository;
  final LandingFilterController _filterController;

  // Direct data storage (no separate cache)
  List<ApiExercise> _exercises = [];
  List<ApiWorkout> _workouts = [];
  List<ApiExercise> _filteredExercises = [];
  List<String> _metainfo = [];

  bool _isLoading = true;
  String? _errorMessage;
  bool _hasShownWelcomeMessage = false;
  bool _isInitialized = false;

  final ValueNotifier<bool> filterApplied = ValueNotifier<bool>(true);

  LandingController({
    LandingRepository? repository,
    LandingFilterController? filterController,
  })  : _repository = repository ?? LandingRepository(),
        _filterController = filterController ?? LandingFilterController() {
    // Listen to global exercise data changes
    globals.exerciseDataChangedNotifier.addListener(_onExerciseDataChanged);
  }

  // Getters
  List<ApiExercise> get exercises => List.from(_exercises);
  List<ApiWorkout> get workouts => List.from(_workouts);
  List<ApiExercise> get filteredExercises => List.from(_filteredExercises);
  List<String> get metainfo => List.from(_metainfo);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasShownWelcomeMessage => _hasShownWelcomeMessage;
  LandingRepository get repository => _repository;
  LandingFilterController get filterController => _filterController;

  /// Initialize the landing screen
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();
    _isInitialized = true;

    try {
      await _loadData();
      await showAllExercises();
      _repository.authStateNotifier.addListener(_onAuthStateChanged);
    } catch (e) {
      _isInitialized = false;
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all data from repository
  Future<void> _loadData() async {
    final results = await Future.wait([
      _repository.getExercises(),
      _repository.getWorkouts(),
    ]);

    _exercises = results[0] as List<ApiExercise>;
    _workouts = results[1] as List<ApiWorkout>;

    // Sort data
    _exercises.sort((a, b) => a.name.compareTo(b.name));
    _workouts.sort((a, b) => a.name.compareTo(b.name));
  }

  /// Reload data (always fetches fresh data)
  Future<void> reload() async {
    try {
      _setLoading(true);
      await _loadData();
      await _restoreFilterState();
    } catch (e) {
      _setError('Error reloading data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Show all exercises with training metadata
  Future<void> showAllExercises() async {
    try {
      _filteredExercises = _exercises;
      _metainfo = [];

      if (_filteredExercises.isEmpty) {
        _notifyFilterChange();
        return;
      }

      await _buildMetainfoForAllExercises();
      _filterController.clearFilters();
      _notifyFilterChange();
    } catch (e) {
      _setError('Error showing all exercises: $e');
    }
  }

  /// Apply workout filter
  Future<void> applyWorkoutFilter(ApiWorkout workout) async {
    try {
      _filterController.setWorkoutFilter(workout);

      final allExercises = _exercises;
      final exerciseNames =
          _filterController.getFilteredExerciseNames(allExercises, _workouts);

      _filteredExercises =
          allExercises.where((ex) => exerciseNames.contains(ex.name)).toList();

      await _buildMetainfoForWorkout(workout);
      _notifyFilterChange();
    } catch (e) {
      _setError('Error applying workout filter: $e');
    }
  }

  /// Apply muscle filter
  Future<void> applyMuscleFilter(MuscleList muscle) async {
    try {
      _filterController.setMuscleFilter(muscle);

      final allExercises = _exercises;
      final exerciseNames =
          _filterController.getFilteredExerciseNames(allExercises, _workouts);

      _filteredExercises =
          allExercises.where((ex) => exerciseNames.contains(ex.name)).toList();

      await _buildMetainfoForMuscle();
      _notifyFilterChange();
    } catch (e) {
      _setError('Error applying muscle filter: $e');
    }
  }

  /// Get sorted exercises for display
  List<ApiExercise> getSortedExercises() {
    final items = List<ApiExercise>.from(_filteredExercises);
    items.sort((a, b) =>
        a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase()));
    return items;
  }

  /// Show welcome message (once per session)
  void showWelcomeMessage() {
    if (_repository.isLoggedIn && !_hasShownWelcomeMessage) {
      _hasShownWelcomeMessage = true;
      notifyListeners();
    }
  }

  /// Reset welcome message flag
  void resetWelcomeMessage() {
    _hasShownWelcomeMessage = false;
  }

  // Private methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _notifyFilterChange() {
    filterApplied.value = !filterApplied.value;
  }

  void _onExerciseDataChanged() {
    if (kDebugMode)
      print('🔄 Exercise data changed - reloading landing screen');
    reload();
  }

  void _onAuthStateChanged() {
    resetWelcomeMessage();
    reload();
  }

  @override
  void dispose() {
    globals.exerciseDataChangedNotifier.removeListener(_onExerciseDataChanged);
    _repository.authStateNotifier.removeListener(_onAuthStateChanged);
    filterApplied.dispose();
    super.dispose();
  }

  /// Build metainfo for all exercises
  Future<void> _buildMetainfoForAllExercises() async {
    _metainfo.clear();

    try {
      final exerciseNames = _filteredExercises.map((ex) => ex.name).toList();
      final lastTrainingDays =
          await _repository.getLastTrainingDaysForExercises(exerciseNames);

      for (var ex in _filteredExercises) {
        final lastTraining =
            lastTrainingDays[ex.name]?['lastTrainingDate'] ?? DateTime.now();
        final lastTrainingWeight =
            lastTrainingDays[ex.name]?['highestWeight'] ?? 0.0;
        final dayDiff = DateTime.now().difference(lastTraining).inDays;
        String dayInfo = dayDiff > 0 ? " - $dayDiff days ago" : "";
        String weightInfo =
            lastTrainingWeight > 0 ? " @ $lastTrainingWeight kg" : "";
        _metainfo.add(
            '${ex.defaultRepBase}-${ex.defaultRepMax} Reps$weightInfo$dayInfo');
      }
    } catch (e) {
      if (kDebugMode) print('Error building metainfo for all exercises: $e');
      _buildFallbackMetainfo();
    }

    _ensureMetainfoLength();
  }

  /// Build metainfo for workout filter
  Future<void> _buildMetainfoForWorkout(ApiWorkout workout) async {
    _metainfo = List.filled(_filteredExercises.length, "");

    // Fill in workout-specific information
    for (var unit in workout.units) {
      for (int i = 0; i < _filteredExercises.length; ++i) {
        if (_filteredExercises[i].name == unit.exerciseName) {
          _metainfo[i] = 'Warm: ${unit.warmups}, Work: ${unit.worksets}';
        }
      }
    }

    // Fill remaining empty entries with default info
    for (int i = 0; i < _metainfo.length; i++) {
      if (_metainfo[i].isEmpty) {
        final ex = _filteredExercises[i];
        _metainfo[i] = '${ex.defaultRepBase}-${ex.defaultRepMax} Reps';
      }
    }
  }

  /// Build metainfo for muscle filter
  Future<void> _buildMetainfoForMuscle() async {
    _metainfo.clear();

    try {
      final exerciseNames = _filteredExercises.map((ex) => ex.name).toList();
      final lastTrainingDays =
          await _repository.getLastTrainingDaysForExercises(exerciseNames);

      for (var ex in _filteredExercises) {
        final lastTraining =
            lastTrainingDays[ex.name]?['lastTrainingDate'] ?? DateTime.now();
        final dayDiff = DateTime.now().difference(lastTraining).inDays;
        String dayInfo = dayDiff > 0 ? "$dayDiff days ago" : "today";
        _metainfo.add(
            '${ex.defaultRepBase}-${ex.defaultRepMax} Reps @ ${ex.defaultIncrement}kg - $dayInfo');
      }
    } catch (e) {
      if (kDebugMode) print('Error building metainfo for muscle filter: $e');
      _buildFallbackMetainfoForMuscle();
    }

    _ensureMetainfoLength();
  }

  /// Build fallback metainfo without training data
  void _buildFallbackMetainfo() {
    _metainfo.clear();
    for (var ex in _filteredExercises) {
      _metainfo.add('${ex.defaultRepBase}-${ex.defaultRepMax} Reps');
    }
  }

  /// Build fallback metainfo for muscle filter
  void _buildFallbackMetainfoForMuscle() {
    _metainfo.clear();
    for (var ex in _filteredExercises) {
      _metainfo.add(
          '${ex.defaultRepBase}-${ex.defaultRepMax} Reps @ ${ex.defaultIncrement}kg');
    }
  }

  /// Ensure metainfo and filteredExercises have same length
  void _ensureMetainfoLength() {
    while (_metainfo.length < _filteredExercises.length) {
      final ex = _filteredExercises[_metainfo.length];
      _metainfo.add('${ex.defaultRepBase}-${ex.defaultRepMax} Reps');
    }
  }

  /// Restore filter state when returning from other screens
  Future<void> _restoreFilterState() async {
    final filterState = _filterController.filterState;

    switch (filterState.filterType) {
      case FilterType.workout:
        if (filterState.selectedWorkout != null) {
          await applyWorkoutFilter(filterState.selectedWorkout!);
          _filterController.restoreFilterState();
        }
        break;
      case FilterType.muscle:
        if (filterState.selectedMuscle != null) {
          await applyMuscleFilter(filterState.selectedMuscle!);
          _filterController.restoreFilterState();
        }
        break;
      case FilterType.none:
        await showAllExercises();
        break;
    }
  }
}
