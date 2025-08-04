import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/exercise_selection_controller.dart';
import '../controllers/workout_setup_controller.dart';

class AddExerciseButtonWidget extends StatelessWidget {
  final bool isMobile;

  const AddExerciseButtonWidget({
    super.key,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExerciseSelectionController, WorkoutSetupController>(
      builder: (context, selectionController, workoutController, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: SizedBox(
            width: 100,
            height: isMobile ? null : 200,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                if (selectionController.selectedExercise != null) {
                  workoutController.addExercise(
                    selectionController.selectedExercise!,
                    selectionController.warmups,
                    selectionController.worksets,
                  );
                }
              },
              child:
                  Icon(isMobile ? Icons.arrow_downward : Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }
}
