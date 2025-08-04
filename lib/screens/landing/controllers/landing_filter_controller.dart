/// Landing Filter Controller - Manages filter state and operations
library;

import 'package:flutter/material.dart';
import '../models/landing_filter_state.dart';
import '../../../utils/api/api_models.dart';

class LandingFilterController extends ChangeNotifier {
  // Controllers for dropdown inputs
  final TextEditingController workoutController = TextEditingController();
  final TextEditingController muscleController = TextEditingController();

  // Filter state
  LandingFilterState _filterState = const LandingFilterState();

  // Getters
  LandingFilterState get filterState => _filterState;
  ApiWorkout? get selectedWorkout => _filterState.selectedWorkout;
  MuscleList? get selectedMuscle => _filterState.selectedMuscle;
  FilterType get filterType => _filterState.filterType;
  bool get hasActiveFilter => _filterState.hasActiveFilter;

  @override
  void dispose() {
    workoutController.dispose();
    muscleController.dispose();
    super.dispose();
  }

  /// Clear all filters and reset controllers
  void clearFilters() {
    _filterState = _filterState.clear();
    workoutController.clear();
    muscleController.clear();
    notifyListeners();
  }

  /// Set workout filter
  void setWorkoutFilter(ApiWorkout workout) {
    _filterState = _filterState.setWorkoutFilter(workout);
    workoutController.text = workout.name;
    muscleController.clear();
    notifyListeners();
  }

  /// Set muscle filter
  void setMuscleFilter(MuscleList muscle) {
    _filterState = _filterState.setMuscleFilter(muscle);
    muscleController.text = muscle.muscleName;
    workoutController.clear();
    notifyListeners();
  }

  /// Restore filter state (used when returning from other screens)
  void restoreFilterState() {
    switch (_filterState.filterType) {
      case FilterType.workout:
        if (_filterState.selectedWorkout != null) {
          workoutController.text = _filterState.selectedWorkout!.name;
          muscleController.clear();
        }
        break;
      case FilterType.muscle:
        if (_filterState.selectedMuscle != null) {
          muscleController.text = _filterState.selectedMuscle!.muscleName;
          workoutController.clear();
        }
        break;
      case FilterType.none:
        workoutController.clear();
        muscleController.clear();
        break;
    }
  }

  /// Get exercises that should be shown based on current filter
  List<String> getFilteredExerciseNames(
      List<ApiExercise> allExercises, List<ApiWorkout> allWorkouts) {
    switch (_filterState.filterType) {
      case FilterType.workout:
        return _getWorkoutFilteredExercises();
      case FilterType.muscle:
        return _getMuscleFilteredExercises(allExercises);
      case FilterType.none:
        return allExercises.map((ex) => ex.name).toList();
    }
  }

  /// Get exercises for workout filter
  List<String> _getWorkoutFilteredExercises() {
    if (_filterState.selectedWorkout == null) return [];

    final filterMask = <String>[];
    for (var unit in _filterState.selectedWorkout!.units) {
      filterMask.add(unit.exerciseName);
    }
    return filterMask;
  }

  /// Get exercises for muscle filter
  List<String> _getMuscleFilteredExercises(List<ApiExercise> allExercises) {
    if (_filterState.selectedMuscle == null) return [];

    final muscleName = _filterState.selectedMuscle!.muscleName;
    return allExercises
        .where((ex) => ex.primaryMuscleGroups.contains(muscleName))
        .map((ex) => ex.name)
        .toList();
  }
}
