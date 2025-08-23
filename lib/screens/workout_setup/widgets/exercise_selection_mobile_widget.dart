import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/exercise_selection_controller.dart';
import '../controllers/workout_setup_controller.dart';
import '../../../utils/models/data_models.dart';

class ExerciseSelectionMobileWidget extends StatelessWidget {
  const ExerciseSelectionMobileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExerciseSelectionController, WorkoutSetupController>(
      builder: (context, selectionController, workoutController, child) {
        return Column(
          children: [
            // Exercise dropdown
            DropdownMenu<Exercise>(
              width: MediaQuery.of(context).size.width * 0.7,
              controller: selectionController.exerciseController,
              menuHeight: 500,
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                constraints: BoxConstraints.tight(const Size.fromHeight(40)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              requestFocusOnTap: false,
              label: const Text('Exercises'),
              onSelected: (selectedExercise) {
                selectionController.setSelectedExercise(selectedExercise);
              },
              dropdownMenuEntries: workoutController.allExercises
                  .map<DropdownMenuEntry<Exercise>>((Exercise exercise) {
                return DropdownMenuEntry<Exercise>(
                    value: exercise,
                    label: exercise.name,
                    leadingIcon: SizedBox(
                      width: 20,
                      child: FaIcon(
                        selectionController.getExerciseIcon(exercise.type),
                        size: 16,
                      ),
                    ));
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
