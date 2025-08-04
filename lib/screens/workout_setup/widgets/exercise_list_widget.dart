import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/workout_setup_controller.dart';
import '../controllers/exercise_selection_controller.dart';
import 'exercise_tile_widget.dart';

class ExerciseListWidget extends StatelessWidget {
  const ExerciseListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkoutSetupController, ExerciseSelectionController>(
      builder: (context, workoutController, selectionController, child) {
        return ValueListenableBuilder(
          valueListenable: workoutController.exerciseListNotifier,
          builder: (context, bool value, _) {
            final exercises = workoutController.addedExercises;

            if (exercises.isNotEmpty) {
              return ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final icon =
                      selectionController.getExerciseIcon(exercise.type);

                  return ExerciseTileWidget(
                    exercise: exercise,
                    icon: icon,
                    onRemove: () => workoutController.removeExercise(exercise),
                  );
                },
              );
            } else {
              return const Center(child: Text("No exercises yet"));
            }
          },
        );
      },
    );
  }
}
