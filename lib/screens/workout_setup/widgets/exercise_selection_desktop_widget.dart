import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/exercise_selection_controller.dart';
import '../controllers/workout_setup_controller.dart';

class ExerciseSelectionDesktopWidget extends StatelessWidget {
  const ExerciseSelectionDesktopWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExerciseSelectionController, WorkoutSetupController>(
      builder: (context, selectionController, workoutController, child) {
        return Container(
          width: 300,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                width: double.infinity,
                child: const Text(
                  'Select Exercise',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: workoutController.allExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = workoutController.allExercises[index];
                    final isSelected =
                        selectionController.selectedExercise?.id == exercise.id;

                    return ListTile(
                      selected: isSelected,
                      leading: FaIcon(
                        selectionController.getExerciseIcon(exercise.type),
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                      ),
                      title: Text(
                        exercise.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                      ),
                      onTap: () {
                        selectionController.setSelectedExercise(exercise);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
