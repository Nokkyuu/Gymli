///landing screen for the app
///will be shown upon starting the app and lists all the exercises of the user
///
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Gymli/widgets/app_router.dart';
import 'landing/controllers/landing_controller.dart';
import 'landing/controllers/landing_filter_controller.dart';
import 'landing/widgets/landing_loading_widget.dart';
import 'landing/widgets/landing_demo_watermark.dart';
import 'landing/widgets/landing_exercise_list.dart';
import 'landing/widgets/landing_filter_section.dart';
import 'package:Gymli/utils/services/authentication_service.dart';
import 'package:Gymli/utils/providers.dart'; // workoutDataCacheProvider & landingControllerProvider

class LandingScreen extends ConsumerWidget {
  final void Function(Color)? onPhaseColorChanged;
  const LandingScreen({super.key, this.onPhaseColorChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(landingControllerProvider);

    Widget buildBody() {
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
                availableWorkouts: controller.workouts,
                filterController: controller.filterController,
                onWorkoutSelected: (w) => controller.applyWorkoutFilter(w),
                onMuscleSelected: (m) => controller.applyMuscleFilter(m),
                onShowAll: () => controller.showAllExercises(),
                onWorkoutEdit: (name) => _onWorkoutEdit(context, name, controller),
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
                        onExerciseTap: (ex, desc) => _onExerciseTap(context, ex, desc, controller),
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
            isLoggedIn: GetIt.I<AuthenticationService>().isLoggedIn,
          ),
        ],
      );
    }

    return Scaffold(body: buildBody());
  }

  void _onWorkoutEdit(BuildContext context, String workoutName, LandingController controller) {
    context
        .push('${AppRouter.workoutSetup}?type=${Uri.encodeComponent(workoutName)}')
        .then((_) => controller.reload());
  }

  void _onExerciseTap(BuildContext context, dynamic exercise, String description, LandingController controller) {
    final queryParams = {
      'id': exercise.id.toString(),
      'name': Uri.encodeComponent(exercise.name),
      'description': Uri.encodeComponent(description),
    };
    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    context
        .push('${AppRouter.exercise}?$queryString')
        .then((_) => controller.reload());
  }
}
