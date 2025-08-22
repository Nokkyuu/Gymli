/// Landing Controller - Simplified without caching layer
library;

import 'package:Gymli/utils/services/authentication_service.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import 'package:flutter/foundation.dart';
import '../models/landing_filter_state.dart';
import 'landing_filter_controller.dart';
import '../../../utils/api/api_models.dart';
import '../../../utils/globals.dart' as globals;
import 'package:get_it/get_it.dart';
import 'package:Gymli/utils/api/api.dart';

import 'package:Gymli/utils/workout_data_cache.dart';


class LandingController extends ChangeNotifier {
  final LandingFilterController _filterController;

  // Direct data storage (no separate cache)
  List<ApiExercise> _exercises = [];
  List<ApiWorkout> _workouts = [];
  List<ApiExercise> _filteredExercises = [];
  List<String> _metainfo = [];

  final WorkoutDataCache? _cache;

  bool _isLoading = true;
  String? _errorMessage;
  bool _hasShownWelcomeMessage = false;
  bool _isInitialized = false;

  final ValueNotifier<bool> filterApplied = ValueNotifier<bool>(true);

  LandingController({
    LandingFilterController? filterController,
    WorkoutDataCache? cache})
    : _filterController = filterController ?? LandingFilterController(),
    _cache = cache {
    _cache?.addListener(_onCacheChanged);  // Listen to global exercise data changes
  }

  // Getters
  List<ApiExercise> get exercises => List.from(_exercises);
  List<ApiWorkout> get workouts => List.from(_workouts);
  List<ApiExercise> get filteredExercises => List.from(_filteredExercises);
  List<String> get metainfo => List.from(_metainfo);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasShownWelcomeMessage => _hasShownWelcomeMessage;
  LandingFilterController get filterController => _filterController;

  /// Initialize the landing screen
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode)
        print('🔄 LandingController already initialized, skipping');
      return;
    }

    _clearError();
    _setLoading(true);

    try {
      if (_cache != null && !_cache!.isInitialized) {               // <- !!!
        await _cache!.init();                                       // <- !!!
      }  
      await _loadData();
      await showAllExercises();
      _isInitialized = true;
      notifyListeners();
      if (kDebugMode) print('✅ LandingController initialized successfully');
    } catch (e) {
      if (kDebugMode) print('❌ LandingController initialization failed: $e');
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all data from repository
  Future<void> _loadData() async {
      // return exercises.map((e) => ApiExercise.fromJson(e)).toList();
      if (_cache != null) {
      // Bei Cache stets bevorzugen; nach obigem await init() sind Daten da       // <- !!!
      _exercises = List<ApiExercise>.from(_cache!.exercises);
      _workouts  = List<ApiWorkout>.from(_cache!.workouts);
      print("Using cached data: ${_exercises.length} exercises and ${_workouts.length} workouts");
    } else  {
      _exercises = await GetIt.I<ExerciseService>().getExercises();
      _workouts = (await GetIt.I<WorkoutService>().getWorkouts()).map((e) => ApiWorkout.fromJson(e)).toList();
      print("Used fall back data: ${_exercises.length} exercises and ${_workouts.length} workouts");
    }
  }

  /// Reload data (always fetches fresh data)
  Future<void> reload() async {
    // Safety check: don't operate on disposed controller
    if (!_isInitialized) return;

    try {
      _setLoading(true);
      await _loadData();
      await _restoreFilterState();
    } catch (e) {
      if (_isInitialized) {
        _setError('Error reloading data: $e');
      }
    } finally {
      if (_isInitialized) {
        _setLoading(false);
      }
    }
  }

  /// Show all exercises with training metadata
  Future<void> showAllExercises() async {
    try {
      _filterController.clearFilters();
      _filteredExercises = List<ApiExercise>.from(_filterController.getFilteredExercisesView(_exercises));
      _metainfo = [];

      if (_filteredExercises.isEmpty) {
        _notifyFilterChange();
        return;
      }

      await _buildMetainfoForAllExercises();
      _notifyFilterChange();
    } catch (e) {
      _setError('Error showing all exercises: $e');
    }
  }

  /// Apply workout filter
  Future<void> applyWorkoutFilter(ApiWorkout workout) async {
    try {
      _filterController.setWorkoutFilter(workout);

      _filteredExercises = List<ApiExercise>.from(_filterController.getFilteredExercisesView(_exercises));

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

      _filteredExercises = List<ApiExercise>.from(_filterController.getFilteredExercisesView(_exercises));

      await _buildMetainfoForMuscle();
      _notifyFilterChange();
    } catch (e) {
      _setError('Error applying muscle filter: $e');
    }
  }

  /// Get sorted exercises for display
  List<ApiExercise> getSortedExercises() {
    return List<ApiExercise>.from(_filterController.getFilteredExercisesView(_exercises));
  }

  /// Show welcome message (once per session)
  void showWelcomeMessage() {
    if (!_isInitialized) return;

    if (GetIt.I<AuthenticationService>().isLoggedIn &&
        !_hasShownWelcomeMessage) {
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
    // Safety check: don't notify listeners if disposed
  _isLoading = loading;                       // immer setzen                  // <- !!!
  if (_isInitialized) notifyListeners();      // erst nach Init redraw         // <- !!!
}

  void _setError(String error) {
    _errorMessage = error;                      // immer setzen                  // <- !!!
    if (_isInitialized) notifyListeners();      // erst nach Init redraw         // <- !!!
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _notifyFilterChange() {
    // Safety check: don't notify if disposed
    if (!_isInitialized) return;
    filterApplied.value = !filterApplied.value;
  }

  // <- !!! neu: Reaktion auf Cache-Änderungen
  void _onCacheChanged() { // <- !!!
    if (_cache == null) return;

    // Daten immer übernehmen (Hydration), auch vor _isInitialized              // <- !!!
    _exercises = List<ApiExercise>.from(_cache!.exercises);
    _workouts  = List<ApiWorkout>.from(_cache!.workouts);

    if (!_isInitialized) {
      if (kDebugMode) print('🔄 Cache changed (pre-init) - hydrated');         // <- !!!
      return; // noch nicht redrawen
    }

    if (kDebugMode) print('🔄 Cache changed - updating landing view');
    _restoreFilterState();
    notifyListeners();
  } // <

  void _onAuthStateChanged() {
    // Safety check: don't operate on disposed controller
    if (!_isInitialized) return;

    resetWelcomeMessage();
    reload();
  }

  @override
  void dispose() {
    // Add safety check to prevent calling dispose multiple times
    if (!_isInitialized) return;

    try {
      // Remove global listener safely
      _cache?.removeListener(_onCacheChanged); // <- !!!

      // Dispose filter applied notifier
      filterApplied.dispose();

      // Mark as disposed to prevent future operations
      _isInitialized = false;
    } catch (e) {
      if (kDebugMode)
        print('Warning: Error during LandingController disposal: $e');
    }

    super.dispose();
  }

  /// Build metainfo for all exercises
  Future<void> _buildMetainfoForAllExercises() async {
    _metainfo.clear();

    try {
      final exerciseNames = _filteredExercises.map((ex) => ex.name).toList();
      // final lastTrainingDays = await _repository.getLastTrainingDaysForExercises(exerciseNames);
      final lastTrainingDays = await GetIt.I<TempService>()
          .getLastTrainingDatesPerExercise(exerciseNames);

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
      final lastTrainingDays = await GetIt.I<TempService>()
          .getLastTrainingDatesPerExercise(exerciseNames);

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
