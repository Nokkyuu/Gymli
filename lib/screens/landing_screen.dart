///landing screen for the app
///will be shown upon starting the app and lists all the exercises of the user
///
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Gymli/screens/exercise_screen.dart';
import 'package:Gymli/screens/workout_setup_screen.dart';
import 'landing/controllers/landing_controller.dart';
import 'landing/controllers/landing_cache_controller.dart';
import 'landing/controllers/landing_filter_controller.dart';
import 'landing/repositories/landing_repository.dart';
import 'landing/widgets/landing_loading_widget.dart';
import 'landing/widgets/landing_demo_watermark.dart';
import 'landing/widgets/landing_exercise_list.dart';
import 'landing/widgets/landing_filter_section.dart';

class LandingScreen extends StatefulWidget {
  final void Function(Color)? onPhaseColorChanged;
  const LandingScreen({super.key, this.onPhaseColorChanged});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late LandingController _landingController;
  late LandingCacheController _cacheController;
  late LandingFilterController _filterController;
  late LandingRepository _repository;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() {
    _repository = LandingRepository();
    _cacheController = LandingCacheController();
    _filterController = LandingFilterController();
    _landingController = LandingController(
      repository: _repository,
      cacheController: _cacheController,
      filterController: _filterController,
    );

    // Initialize the landing screen
    _landingController.initialize();
  }

  @override
  void dispose() {
    _landingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _landingController),
        ChangeNotifierProvider.value(value: _cacheController),
        ChangeNotifierProvider.value(value: _filterController),
      ],
      child: Consumer<LandingController>(
        builder: (context, controller, child) {
          return Scaffold(
            body: _buildBody(controller),
          );
        },
      ),
    );
  }

  Widget _buildBody(LandingController controller) {
    if (controller.isLoading) {
      return const LandingLoadingWidget();
    }

    if (controller.errorMessage != null) {
      return LandingErrorWidget(
        message: controller.errorMessage!,
        onRetry: () => controller.initialize(),
      );
    }

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            LandingFilterSection(
              availableWorkouts: controller.cacheController.cachedWorkouts,
              filterController: controller.filterController,
              onWorkoutSelected: _onWorkoutSelected,
              onMuscleSelected: _onMuscleSelected,
              onShowAll: _onShowAll,
              onWorkoutEdit: _onWorkoutEdit,
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: controller.filterApplied,
                builder: (context, bool filterApplied, _) {
                  final sortedExercises = controller.getSortedExercises();
                  if (sortedExercises.isNotEmpty) {
                    return LandingExerciseList(
                      exercises: sortedExercises,
                      metainfo: controller.metainfo,
                      onExerciseTap: _onExerciseTap,
                    );
                  } else {
                    return const LandingEmptyWidget();
                  }
                },
              ),
            ),
          ],
        ),
        LandingDemoWatermark(
          isLoggedIn: _repository.isLoggedIn,
        ),
      ],
    );
  }

  void _onWorkoutSelected(workout) {
    _landingController.applyWorkoutFilter(workout);
  }

  void _onMuscleSelected(muscle) {
    _landingController.applyMuscleFilter(muscle);
  }

  void _onShowAll() {
    _landingController.showAllExercises();
  }

  void _onWorkoutEdit(String workoutName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSetupScreen(workoutName),
      ),
    ).then((_) => _landingController.reload());
  }

  void _onExerciseTap(exercise, description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(
          exercise.name,
          description,
          onPhaseColorChanged: widget.onPhaseColorChanged,
        ),
      ),
    ).then((_) => _landingController.reload());
  }
}
