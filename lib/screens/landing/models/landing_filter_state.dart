/// Landing Filter State - Model for filter state management
library;

import '../../../utils/models/data_models.dart';

enum MuscleList {
  Pectoralis_major("Pectoralis major"),
  Trapezius("Trapezius"),
  Biceps("Biceps"),
  Abdominals("Abdominals"),
  Delts("Deltoids"),
  Latissimus_dorsi("Latissimus dorsi"),
  Triceps("Triceps"),
  Gluteus_maximus("Gluteus maximus"),
  Hamstrings("Hamstrings"),
  Quadriceps("Quadriceps"),
  Forearms("Forearms"),
  Calves("Calves");

  const MuscleList(this.muscleName);
  final String muscleName;
}

enum FilterType { none, workout, muscle }

class LandingFilterState {
  final FilterType filterType;
  final ApiWorkout? selectedWorkout;
  final MuscleList? selectedMuscle;

  const LandingFilterState({
    this.filterType = FilterType.none,
    this.selectedWorkout,
    this.selectedMuscle,
  });

  LandingFilterState copyWith({
    FilterType? filterType,
    ApiWorkout? selectedWorkout,
    MuscleList? selectedMuscle,
  }) {
    return LandingFilterState(
      filterType: filterType ?? this.filterType,
      selectedWorkout: selectedWorkout ?? this.selectedWorkout,
      selectedMuscle: selectedMuscle ?? this.selectedMuscle,
    );
  }

  /// Clear all filters
  LandingFilterState clear() {
    return const LandingFilterState(filterType: FilterType.none);
  }

  /// Set workout filter
  LandingFilterState setWorkoutFilter(ApiWorkout workout) {
    return LandingFilterState(
      filterType: FilterType.workout,
      selectedWorkout: workout,
    );
  }

  /// Set muscle filter
  LandingFilterState setMuscleFilter(MuscleList muscle) {
    return LandingFilterState(
      filterType: FilterType.muscle,
      selectedMuscle: muscle,
    );
  }

  /// Check if any filter is active
  bool get hasActiveFilter => filterType != FilterType.none;

  /// Get display text for current filter
  String get displayText {
    switch (filterType) {
      case FilterType.workout:
        return selectedWorkout?.name ?? '';
      case FilterType.muscle:
        return selectedMuscle?.muscleName ?? '';
      case FilterType.none:
        return '';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandingFilterState &&
        other.filterType == filterType &&
        other.selectedWorkout == selectedWorkout &&
        other.selectedMuscle == selectedMuscle;
  }

  @override
  int get hashCode {
    return filterType.hashCode ^
        selectedWorkout.hashCode ^
        selectedMuscle.hashCode;
  }
}
