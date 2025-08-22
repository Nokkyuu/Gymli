/// Landing Filter Section - Workout and muscle filter dropdown menus
library;

import 'package:flutter/material.dart';
import '../../../utils/api/api_models.dart';
import '../models/landing_filter_state.dart';
import '../controllers/landing_filter_controller.dart';

class LandingFilterSection extends StatelessWidget {
  final List<ApiWorkout> availableWorkouts;
  final LandingFilterController filterController;
  final Function(ApiWorkout) onWorkoutSelected;
  final Function(MuscleList) onMuscleSelected;
  final VoidCallback onShowAll;
  final Function(String) onWorkoutEdit;

  const LandingFilterSection({
    super.key,
    required this.availableWorkouts,
    required this.filterController,
    required this.onWorkoutSelected,
    required this.onMuscleSelected,
    required this.onShowAll,
    required this.onWorkoutEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildShowAllSection(),
        _buildDropdownSection(context),
        const Divider(),
      ],
    );
  }

  Widget _buildShowAllSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Filter by or "),
        TextButton.icon(
          onPressed: () {
            onShowAll();
            filterController.clearFilters();
          },
          label: const Text("Show All"),
          icon: const Icon(Icons.search),
        )
      ],
    );
  }

  Widget _buildDropdownSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Spacer(),
        _buildWorkoutDropdown(context),
        const Spacer(),
        _buildMuscleDropdown(context),
        const Spacer(),
      ],
    );
  }

  Widget _buildWorkoutDropdown(BuildContext context) {
    return DropdownMenu<ApiWorkout>(
      width: MediaQuery.of(context).size.width * 0.45,
      enabled: true,
      key:
          ValueKey('workout-${filterController.selectedWorkout?.id ?? 'none'}'),
      initialSelection: (filterController.filterType == FilterType.workout &&
              filterController.hasActiveFilter)
          ? filterController.selectedWorkout
          : null,
      requestFocusOnTap: false,
      label: const Text('Workouts'),
      onSelected: (ApiWorkout? workout) {
        if (workout != null) {
          onWorkoutSelected(workout);
        }
      },
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        constraints: BoxConstraints.tight(const Size.fromHeight(40)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dropdownMenuEntries: availableWorkouts
          .map<DropdownMenuEntry<ApiWorkout>>((ApiWorkout workout) {
        return DropdownMenuEntry<ApiWorkout>(
          value: workout,
          label: workout.name,
          trailingIcon: IconButton(
            onPressed: () => onWorkoutEdit(workout.name),
            icon: const Icon(Icons.edit),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMuscleDropdown(BuildContext context) {
    return DropdownMenu<MuscleList>(
      width: MediaQuery.of(context).size.width * 0.45,
      enabled: true,
      key: ValueKey(
          'muscle-${filterController.selectedMuscle?.muscleName ?? 'none'}'),
      initialSelection: (filterController.filterType == FilterType.muscle &&
              filterController.hasActiveFilter)
          ? filterController.selectedMuscle
          : null,
      requestFocusOnTap: false,
      label: const Text('Muscles'),
      onSelected: (MuscleList? muscle) {
        if (muscle != null) {
          onMuscleSelected(muscle);
        }
      },
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        constraints: BoxConstraints.tight(const Size.fromHeight(40)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dropdownMenuEntries: MuscleList.values
          .map<DropdownMenuEntry<MuscleList>>((MuscleList muscle) {
        return DropdownMenuEntry<MuscleList>(
          value: muscle,
          label: muscle.muscleName,
        );
      }).toList(),
    );
  }
}
