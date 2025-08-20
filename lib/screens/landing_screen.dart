///landing screen for the app
///will be shown upon starting the app and lists all the exercises of the user
///
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Gymli/config/app_router.dart';
import 'landing/controllers/landing_controller.dart';
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
  late LandingFilterController _filterController;
  late LandingRepository _repository;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() {
    _repository = LandingRepository();
    _filterController = LandingFilterController();
    _landingController = LandingController(
      repository: _repository,
      filterController: _filterController,
    );

    // Initialize the landing screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _landingController.initialize();
    });
  }

  @override
  void dispose() {
    // Safely dispose the controller with error handling
    try {
      _landingController.dispose();
    } catch (e) {
      if (kDebugMode) print('Warning: Error disposing LandingController: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _landingController),
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
              availableWorkouts:
                  controller.workouts, // Direct access instead of cache
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
    context
        .push(
            '${AppRouter.workoutSetup}?type=${Uri.encodeComponent(workoutName)}')
        .then((_) => _landingController.reload());
  }

  void _onExerciseTap(exercise, description) {
    final queryParams = {
      'id': exercise.id.toString(),
      'name': Uri.encodeComponent(exercise.name),
      'description': Uri.encodeComponent(description),
    };
    final queryString =
        queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    context
        .push('${AppRouter.exercise}?$queryString')
        .then((_) => _landingController.reload());
  }
}
