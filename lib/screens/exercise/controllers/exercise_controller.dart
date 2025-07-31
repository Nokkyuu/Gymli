import 'package:flutter/material.dart';
import '../../../utils/api/api_models.dart';
import '../repositories/exercise_repository.dart';
import 'exercise_graph_controller.dart';

enum ExerciseType { warmup, work }

/// Controller for managing exercise screen state and business logic
class ExerciseController extends ChangeNotifier {
  final ExerciseRepository _repository;
  final ExerciseGraphController _graphController;

  // Exercise data
  ApiExercise? _currentExercise;
  List<ApiTrainingSet> _todaysTrainingSets = [];
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

  ExerciseController({
    ExerciseRepository? repository,
    ExerciseGraphController? graphController,
  })  : _repository = repository ?? ExerciseRepository(),
        _graphController = graphController ?? ExerciseGraphController();

  // Getters
  ApiExercise? get currentExercise => _currentExercise;
  List<ApiTrainingSet> get todaysTrainingSets => _todaysTrainingSets;
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

      // Load exercise and training data
      await Future.wait([
        _loadExerciseData(exerciseName),
        _loadTodaysTrainingSets(exerciseName),
      ]);

      // Pass exercise data to graph controller
      _graphController.setCurrentExercise(_currentExercise);

      // Update workout timing
      _updateWorkoutTiming();

      // Set initial weight and reps
      await _updateWeightAndReps();

      // Update workout counts
      _updateWorkoutCounts();

      // Update graph
      final allTrainingSets =
          await _repository.getTrainingSetsForExercise(exerciseName);
      _graphController.updateGraphFromTrainingSets(allTrainingSets);

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

  /// Add a new training set
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
      final newSet = await _repository.createTrainingSet(
        exerciseId: _currentExercise!.id!,
        date: when,
        weight: weight,
        repetitions: repetitions,
        setType: setType,
        phase: phase,
        myoreps: myoreps,
        // baseReps: _currentExercise!.defaultRepBase,
        // maxReps: _currentExercise!.defaultRepMax,
        // increment: _currentExercise!.defaultIncrement,
      );

      if (newSet == null) {
        _setError('Failed to create training set');
        return false;
      }

      // Update local cache
      _todaysTrainingSets.add(newSet);
      _lastActivity = DateTime.now();

      // Update graph efficiently
      final graphUpdated = _graphController.updateGraphWithNewSet(newSet);
      if (!graphUpdated) {
        // Fallback to full graph update
        final allTrainingSets =
            await _repository.getTrainingSetsForExercise(exerciseName);
        _graphController.updateGraphFromTrainingSets(allTrainingSets);
      }

      // Update workout counts
      _updateWorkoutCounts();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add training set: $e');
      return false;
    }
  }

  /// Delete a training set
  Future<bool> deleteTrainingSet(ApiTrainingSet trainingSet) async {
    try {
      final success = await _repository.deleteTrainingSet(trainingSet.id!);

      if (success) {
        _todaysTrainingSets.removeWhere((set) => set.id == trainingSet.id);

        // Update graph
        if (_currentExercise != null) {
          final allTrainingSets = await _repository
              .getTrainingSetsForExercise(_currentExercise!.name);
          _graphController.updateGraphFromTrainingSets(allTrainingSets);
        }

        // Update workout counts
        _updateWorkoutCounts();

        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to delete training set: $e');
      return false;
    }
  }

  /// Update selected exercise type
  void updateSelectedType(Set<ExerciseType> newSelection) {
    if (_selectedType != newSelection) {
      _selectedType = newSelection;
      // Update weight and reps based on the new exercise type selection
      _updateWeightAndReps().then((_) {
        notifyListeners();
      });
    }
  }

  /// Update weight values
  void updateWeight(int kg, int dg) {
    _weightKg = kg;
    _weightDg = dg;
    notifyListeners();
  }

  /// Update repetitions
  void updateRepetitions(int reps) {
    _repetitions = reps;
    notifyListeners();
  }

  /// Get formatted weight as double
  double get weightAsDouble =>
      _weightKg.toDouble() + _weightDg.toDouble() / 100.0;

  /// Refresh graph data with latest training sets
  Future<void> refreshGraphData(String exerciseName) async {
    try {
      final allTrainingSets =
          await _repository.getTrainingSetsForExercise(exerciseName);
      _graphController.updateGraphFromTrainingSets(allTrainingSets);
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

  Future<void> _loadExerciseData(String exerciseName) async {
    _currentExercise = await _repository.getExerciseByName(exerciseName);
  }

  Future<void> _loadTodaysTrainingSets(String exerciseName) async {
    _todaysTrainingSets =
        await _repository.getTodaysTrainingSetsForExercise(exerciseName);
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
    if (_todaysTrainingSets.isNotEmpty) {
      _workoutStartTime = _todaysTrainingSets.first.date;
      _lastActivity = _todaysTrainingSets.last.date;
    }
  }

  /// Set initial weight and reps - now async to get recent values if needed
  Future<void> _updateWeightAndReps() async {
    if (_currentExercise == null) return;

    double weight = _currentExercise!.defaultIncrement;
    int reps = _currentExercise!.defaultRepBase;

    // First, try to get values from today's sets
    bool foundValuesFromToday = false;

    if (_todaysTrainingSets.isNotEmpty) {
      if (_selectedType.first == ExerciseType.warmup) {
        // For warmup: Look for the most recent warmup set
        final warmupSets =
            _todaysTrainingSets.where((set) => set.setType == 0).toList();

        if (warmupSets.isNotEmpty) {
          final lastWarmupSet = warmupSets.last;
          weight = lastWarmupSet.weight;
          reps = lastWarmupSet.repetitions;
          foundValuesFromToday = true;
        }
      } else {
        // For work sets: Find the best set from today's sessions
        final workSets =
            _todaysTrainingSets.where((set) => set.setType > 0).toList();

        if (workSets.isNotEmpty) {
          // Find the best set (highest weight, then most reps)
          ApiTrainingSet? bestSet;
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
    int originalWarmUps = _numWarmUps;
    int originalWorkSets = _numWorkSets;

    for (var set in _todaysTrainingSets) {
      if (set.setType == 0) {
        _numWarmUps = (_numWarmUps - 1).clamp(0, originalWarmUps);
      } else if (set.setType == 1) {
        _numWorkSets = (_numWorkSets - 1).clamp(0, originalWorkSets);
      }
    }
  }

  /// Load recent training values for weight and reps based on exercise type
  Future<Map<String, dynamic>?> _loadRecentTrainingValues() async {
    if (_currentExercise == null) return null;

    try {
      // Get all training sets for this exercise
      final allTrainingSets =
          await _repository.getTrainingSetsForExercise(_currentExercise!.name);

      if (allTrainingSets.isEmpty) return null;

      // Sort by date (most recent first)
      allTrainingSets.sort((a, b) => b.date.compareTo(a.date));

      if (_selectedType.first == ExerciseType.warmup) {
        // For warmup: Look for the most recent warmup set
        final recentWarmupSets = allTrainingSets
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
              allTrainingSets.where((set) => set.setType > 0).take(5).toList();

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
        final recentWorkSets = allTrainingSets
            .where((set) => set.setType > 0)
            .take(10) // Look at last 10 work sets
            .toList();

        if (recentWorkSets.isNotEmpty) {
          // Find the best set (highest weight, then most reps)
          ApiTrainingSet? bestSet;
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
}
