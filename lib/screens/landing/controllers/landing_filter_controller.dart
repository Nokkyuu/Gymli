/// Landing Filter Controller - Pure state + ordered views (no UI controllers, no ChangeNotifier)
library;

import '../models/landing_filter_state.dart';
import '../../../utils/models/data_models.dart';

/// Comparator used app-wide for alphabetic exercise ordering (case/space-insensitive).
int _byName(Exercise a, Exercise b) =>
    a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase());

/// Return an ordered *view* of exercises for display, without mutating the source list.
/// - For workout filter: preserves the unit order from the workout.
/// - For muscle/none: yields alphabetically by name.
Iterable<Exercise> orderedExercisesView(
  LandingFilterState state,
  Iterable<Exercise> allExercises,
) sync* {
  switch (state.filterType) {
    case FilterType.workout:
      final w = state.selectedWorkout;
      if (w == null) return;
      // Build a lookup once; does not copy exercise objects
      final Map<String, Exercise> byName = {
        for (final e in allExercises) e.name: e,
      };
      for (final u in w.units) {
        final ex = byName[u.exerciseName];
        if (ex != null) yield ex;
      }
      return;

    case FilterType.muscle:
      // Filter and sort on the fly; sort uses a small in-memory list of refs
      final filtered = allExercises.where((e) =>
          state.selectedMuscle != null &&
          e.primaryMuscleGroups.contains(state.selectedMuscle!.muscleName));
      final list = filtered.toList(growable: false);
      list.sort(_byName);
      for (final e in list) {
        yield e;
      }
      return;

    case FilterType.none:
      final list = allExercises.toList(growable: false);
      list.sort(_byName);
      for (final e in list) {
        yield e;
      }
      return;
  }
}

/// Stateless helper: compute *names* for a given filter state (sorted where applicable).
List<String> computeFilteredExerciseNames(
  LandingFilterState state,
  List<Exercise> allExercises,
) {
  switch (state.filterType) {
    case FilterType.workout:
      final w = state.selectedWorkout;
      if (w == null) return const <String>[];
      // Preserve workout order
      return w.units.map((u) => u.exerciseName).toList(growable: false);

    case FilterType.muscle:
      final m = state.selectedMuscle;
      if (m == null) return const <String>[];
      final muscleName = m.muscleName;
      final names = allExercises
          .where((ex) => ex.primaryMuscleGroups.contains(muscleName))
          .map((ex) => ex.name.trim())
          .toList(growable: false);
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return names;

    case FilterType.none:
      final names =
          allExercises.map((ex) => ex.name.trim()).toList(growable: false);
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return names;
  }
}

/// Controller with immutable state. No framework/UI coupling.
class LandingFilterController {
  LandingFilterState _filterState = const LandingFilterState();

  // --- Getters (public surface) ---
  LandingFilterState get filterState => _filterState;
  Workout? get selectedWorkout => _filterState.selectedWorkout;
  MuscleList? get selectedMuscle => _filterState.selectedMuscle;
  FilterType get filterType => _filterState.filterType;
  bool get hasActiveFilter => _filterState.hasActiveFilter;

  void clearFilters() {
    _filterState = _filterState.clear();
  }

  void setWorkoutFilter(Workout workout) {
    _filterState = _filterState.setWorkoutFilter(workout);
  }

  void setMuscleFilter(MuscleList muscle) {
    _filterState = _filterState.setMuscleFilter(muscle);
  }

  // /// Restore filter state (kept for API compatibility; UI text controllers were removed).
  // void restoreFilterState() {
  //   // No-op: UI widgets should reflect state explicitly when building.
  // }

  List<String> getFilteredExerciseNames(
      List<Exercise> allExercises, List<Workout> allWorkouts) {
    return computeFilteredExerciseNames(_filterState, allExercises);
  }

  Iterable<Exercise> getFilteredExercisesView(Iterable<Exercise> allExercises) {
    return orderedExercisesView(_filterState, allExercises);
  }
}
