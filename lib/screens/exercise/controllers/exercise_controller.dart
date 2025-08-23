import 'package:flutter/material.dart';
import '../../../utils/models/data_models.dart';
import 'exercise_graph_controller.dart';
import 'package:get_it/get_it.dart';
import '../../../utils/workout_data_cache.dart';
import '../../../utils/api/api_export.dart'; // for ExerciseService via GetIt
import '../../../utils/services/authentication_service.dart';

enum ExerciseType { warmup, work }

/// Controller for managing exercise screen state and business logic
class ExerciseController extends ChangeNotifier {
  final ExerciseGraphController _graphController;

  // Exercise data
  Exercise? _currentExercise;
  bool _isLoading = false;
  String? _errorMessage;
  String? phase;
  bool? myoreps;
  // Workout state
  Set<ExerciseType> _selectedType = {ExerciseType.work};
  int _weightKg = 40;
  int _weightDg = 0;
  int _repetitions = 10;

  // Workout context
  int _numWarmUps = 0;
  int _numWorkSets = 0;
  DateTime _lastActivity = DateTime.now();
  DateTime _workoutStartTime = DateTime.now();

  // Color mapping for reps
  final Map<int, Color> _colorMap = {};

  WorkoutDataCache get _cache => GetIt.I<WorkoutDataCache>();
  ExerciseService get _exerciseService => GetIt.I<ExerciseService>();
  TrainingSetService get _trainingSetService => GetIt.I<TrainingSetService>();

  ExerciseController({
    ExerciseGraphController? graphController,
  }) : _graphController = graphController ?? ExerciseGraphController();

  // Getters
  Exercise? get currentExercise => _currentExercise;
  List<TrainingSet> get todaysTrainingSets {
    if (_currentExercise?.id == null) return const [];
    final all = _cache.getCachedTrainingSets(_currentExercise!.id!) ??
        const <TrainingSet>[];
    final now = DateTime.now();
    return all.where((s) => _isSameDay(s.date, now)).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<ExerciseType> get selectedType => _selectedType;
  int get weightKg => _weightKg;
  int get weightDg => _weightDg;
  int get repetitions => _repetitions;
  int get numWarmUps => _numWarmUps;
  int get numWorkSets => _numWorkSets;
  DateTime get lastActivity => _lastActivity;
  DateTime get workoutStartTime => _workoutStartTime;
  Map<int, Color> get colorMap => _colorMap;
  ExerciseGraphController get graphController => _graphController;

  /// Initialize the exercise screen with data
  Future<void> initialize(
      String exerciseName, String workoutDescription) async {
    _setLoading(true);
    _clearError();

    try {
      // Parse workout description
      _parseWorkoutDescription(workoutDescription);

      // Load exercise data
      await _loadExerciseData(exerciseName);

      // Pass exercise data to graph controller
      _graphController.setCurrentExercise(_currentExercise);

      // Update workout timing
      _updateWorkoutTiming();

      // Set initial weight and reps
      await _updateWeightAndReps();

      // Update workout counts
      _updateWorkoutCounts();

      // Update graph (cache-first, then server fetch if needed)
      await refreshGraphData(exerciseName);

      // Update color mapping
      _updateColorMapping();

      // Explicitly notify listeners after full initialization to ensure
      // widgets receive the updated weight and reps values
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize exercise: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new training set (optimistic, local-first)
  String _currentUserName() {
    try {
      final auth = GetIt.I<AuthenticationService>();
      // Try common fields without binding to a specific auth model
      return (auth as dynamic).userName ??
          (auth as dynamic).currentUserName ??
          (auth as dynamic).currentUser?.userName ??
          '';
    } catch (_) {
      return '';
    }
  }

  Future<bool> addTrainingSet(
    String exerciseName,
    double weight,
    int repetitions,
    int setType,
    String when,
    String? phase,
    bool? myoreps,
  ) async {
    if (_currentExercise == null) {
      _setError('Exercise data not loaded');
      return false;
    }

    try {
      final userName = _currentUserName();
      final TrainingSet newSet = _cache.createTrainingSetOptimistic(
        userName: userName,
        exerciseId: _currentExercise!.id!,
        exerciseName: _currentExercise!.name,
        date: DateTime.tryParse(when) ?? DateTime.now(),
        weight: weight,
        repetitions: repetitions,
        setType: setType,
        phase: phase,
        myoreps: myoreps,
      );
      _lastActivity = DateTime.now();
      final graphUpdated = _graphController.updateGraphWithNewSet(newSet);
      if (!graphUpdated) {
        final allTrainingSets =
            _cache.getCachedTrainingSets(_currentExercise!.id!) ??
                const <TrainingSet>[];
        _graphController.updateGraphFromTrainingSets(allTrainingSets);
      }
      _updateWorkoutCounts();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add training set: $e');
      return false;
    }
  }

  /// Delete a training set (optimistic, local-first)
  Future<bool> deleteTrainingSet(TrainingSet trainingSet) async {
    try {
      if (_currentExercise?.id == null || trainingSet.id == null) {
        _setError('Invalid delete parameters');
        return false;
      }
      _cache.deleteTrainingSetOptimistic(
        exerciseId: _currentExercise!.id!,
        setId: trainingSet.id!,
      );
      final allTrainingSets =
          _cache.getCachedTrainingSets(_currentExercise!.id!) ??
              const <TrainingSet>[];
      _graphController.updateGraphFromTrainingSets(allTrainingSets);
      _updateWorkoutCounts();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete training set: $e');
      return false;
    }
  }

  Future<void> refreshTodaysTrainingSets() async {
    try {
      if (_currentExercise?.id != null) {
        _updateWorkoutCounts();
        notifyListeners();
      }
    } catch (e) {
      _setError('Fehler beim Aktualisieren der TrainingSets: $e');
    }
  }

  /// Update selected exercise type
  void updateSelectedType(Set<ExerciseType> newSelection) {
    if (_selectedType == newSelection) return; // no change
    _selectedType = newSelection;
    _updateWeightAndReps()
        .then((_) => notifyListeners()); // recompute then notify once
  }

  /// Update weight values
  void updateWeight(int kg, int dg) {
    if (_weightKg == kg && _weightDg == dg) return; // no change
    _weightKg = kg;
    _weightDg = dg;
    notifyListeners();
  }

  /// Update repetitions
  void updateRepetitions(int reps) {
    if (_repetitions == reps) return; // no change
    _repetitions = reps;
    notifyListeners();
  }

  /// Get formatted weight as double
  double get weightAsDouble =>
      _weightKg.toDouble() + _weightDg.toDouble() / 100.0;

  /// Refresh graph data with latest training sets
  Future<void> refreshGraphData(String _exerciseName) async {
    try {
      final ex = _currentExercise;
      if (ex?.id == null) return;
      final exerciseId = ex!.id!;
      // Cache-first
      final cached = _cache.getCachedTrainingSets(exerciseId);
      if (cached != null && cached.isNotEmpty) {
        _graphController.updateGraphFromTrainingSets(cached);
        return;
      }
      // Cache miss: fetch from server, populate cache, then update graph
      final raw = await _trainingSetService.getTrainingSetsByExerciseID(
          exerciseId: exerciseId);
      final sets = raw
          .whereType<Map<String, dynamic>>()
          .map((m) => TrainingSet.fromJson(m))
          .toList();
      _cache.setExerciseTrainingSets(exerciseId, sets);
      _graphController.updateGraphFromTrainingSets(sets);
    } catch (e) {
      print('Error refreshing graph data: $e');
    }
  }

  /// Get warm/work text labels
  Text get warmText =>
      _numWarmUps > 0 ? Text("${_numWarmUps}x Warm") : const Text("Warm");
  Text get workText =>
      _numWorkSets > 0 ? Text("${_numWorkSets}x Work") : const Text("Work");

  // Private methods

  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // no change
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    if (_errorMessage == error) return; // no change
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> _loadExerciseData(String exerciseName) async {
    // Try cache first
    _currentExercise = null;
    for (final e in _cache.exercises) {
      if (e.name == exerciseName) {
        _currentExercise = e;
        break;
      }
    }
    if (_currentExercise == null) {
      try {
        // Fallback: fetch exercises metadata (not training sets)
        final all = await _exerciseService.getExercises();
        Exercise? match;
        for (final e in all) {
          if (e.name == exerciseName) {
            match = e;
            break;
          }
        }
        _currentExercise = match;
        // Optionally seed cache:
        // _cache.setExercises(all);
      } catch (_) {
        // ignore; caller will handle error state
      }
    }
  }

  void _parseWorkoutDescription(String workoutDescription) {
    _numWarmUps = 0;
    _numWorkSets = 0;

    if (workoutDescription.isNotEmpty &&
        workoutDescription.startsWith("Warm:")) {
      try {
        final parts = workoutDescription.split(", ");
        if (parts.length == 2) {
          // Parse warmups
          final warmPart = parts[0];
          if (warmPart.contains(":")) {
            final warmValue = warmPart.split(":")[1].trim();
            _numWarmUps = int.tryParse(warmValue) ?? 0;
          }

          // Parse worksets
          final workPart = parts[1];
          if (workPart.contains(":")) {
            final workValue = workPart.split(":")[1].trim();
            _numWorkSets = int.tryParse(workValue) ?? 0;
          }
        }
      } catch (e) {
        print('Error parsing workout description: $e');
        _numWarmUps = 0;
        _numWorkSets = 0;
      }
    }
  }

  void _updateWorkoutTiming() {
    final today = todaysTrainingSets;
    if (today.isNotEmpty) {
      _workoutStartTime = today.first.date;
      _lastActivity = today.last.date;
    }
  }

  /// Set initial weight and reps - now async to get recent values if needed
  Future<void> _updateWeightAndReps() async {
    if (_currentExercise == null) return;

    double weight = _currentExercise!.defaultIncrement;
    int reps = _currentExercise!.defaultRepBase;

    // First, try to get values from today's sets
    bool foundValuesFromToday = false;

    if (todaysTrainingSets.isNotEmpty) {
      if (_selectedType.first == ExerciseType.warmup) {
        // For warmup: Look for the most recent warmup set
        final warmupSets =
            todaysTrainingSets.where((set) => set.setType == 0).toList();

        if (warmupSets.isNotEmpty) {
          final lastWarmupSet = warmupSets.last;
          weight = lastWarmupSet.weight;
          reps = lastWarmupSet.repetitions;
          foundValuesFromToday = true;
        }
      } else {
        // For work sets: Find the best set from today's sessions
        final workSets =
            todaysTrainingSets.where((set) => set.setType > 0).toList();

        if (workSets.isNotEmpty) {
          // Find the best set (highest weight, then most reps)
          TrainingSet? bestSet;
          for (var set in workSets) {
            if (bestSet == null ||
                set.weight > bestSet.weight ||
                (set.weight == bestSet.weight &&
                    set.repetitions > bestSet.repetitions)) {
              bestSet = set;
            }
          }

          if (bestSet != null) {
            weight = bestSet.weight;
            reps = bestSet.repetitions;
            foundValuesFromToday = true;
          }
        }
      }
    }

    // If no appropriate values found from today, look at recent training history
    if (!foundValuesFromToday) {
      final recentValues = await _loadRecentTrainingValues();
      if (recentValues != null) {
        weight = recentValues['weight'];
        reps = recentValues['reps'];
      }
    }

    _weightKg = weight.toInt();
    _weightDg = (weight * 100.0).toInt() % 100;
    _repetitions = reps;
  }

  void _updateWorkoutCounts() {
    final originalWarmUps = _numWarmUps;
    final originalWorkSets = _numWorkSets;
    final today = todaysTrainingSets;
    final warmDone = today.where((s) => s.setType == 0).length;
    final workDone = today.where((s) => s.setType > 0).length;
    _numWarmUps = (originalWarmUps - warmDone).clamp(0, originalWarmUps);
    _numWorkSets = (originalWorkSets - workDone).clamp(0, originalWorkSets);
  }

  /// Load recent training values for weight and reps based on exercise type
  Future<Map<String, dynamic>?> _loadRecentTrainingValues() async {
    if (_currentExercise == null) return null;

    try {
      final sets = _currentExercise?.id != null
          ? (_cache.getCachedTrainingSets(_currentExercise!.id!) ??
              const <TrainingSet>[])
          : const <TrainingSet>[];
      if (sets.isEmpty) return null;

      final sortedSets = List<TrainingSet>.from(sets)
        ..sort((a, b) => b.date.compareTo(a.date));

      if (_selectedType.first == ExerciseType.warmup) {
        // For warmup: Look for the most recent warmup set
        final recentWarmupSets = sortedSets
            .where((set) => set.setType == 0)
            .take(5) // Look at last 5 warmup sets
            .toList();

        if (recentWarmupSets.isNotEmpty) {
          final lastWarmupSet = recentWarmupSets.first;
          return {
            'weight': lastWarmupSet.weight,
            'reps': lastWarmupSet.repetitions,
          };
        } else {
          // Fallback: Use the most recent work set and halve the weight
          final recentWorkSets =
              sortedSets.where((set) => set.setType > 0).take(5).toList();

          if (recentWorkSets.isNotEmpty) {
            final lastWorkSet = recentWorkSets.first;
            double warmupWeight = lastWorkSet.weight / 2.0;
            // Round to nearest increment
            warmupWeight =
                (warmupWeight / _currentExercise!.defaultIncrement).round() *
                    _currentExercise!.defaultIncrement;
            return {
              'weight': warmupWeight,
              'reps': _currentExercise!.defaultRepBase,
            };
          }
        }
      } else {
        // For work sets: Find the best recent work set
        final recentWorkSets = sortedSets
            .where((set) => set.setType > 0)
            .take(10) // Look at last 10 work sets
            .toList();

        if (recentWorkSets.isNotEmpty) {
          // Find the best set (highest weight, then most reps)
          TrainingSet? bestSet;
          for (var set in recentWorkSets) {
            if (bestSet == null ||
                set.weight > bestSet.weight ||
                (set.weight == bestSet.weight &&
                    set.repetitions > bestSet.repetitions)) {
              bestSet = set;
            }
          }

          if (bestSet != null) {
            return {
              'weight': bestSet.weight,
              'reps': bestSet.repetitions,
            };
          }
        }
      }

      return null;
    } catch (e) {
      print('Error loading recent training values: $e');
      return null;
    }
  }

  void updatePhase(String? newPhase) {
    phase = newPhase;
    notifyListeners();
  }

  void updateMyoreps(bool? value) {
    myoreps = value;
    notifyListeners();
  }

  void _updateColorMapping() {
    if (_currentExercise != null) {
      _colorMap.clear();
      for (int i = _currentExercise!.defaultRepBase;
          i <= _currentExercise!.defaultRepMax;
          ++i) {
        _colorMap[i] = Colors.red;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
