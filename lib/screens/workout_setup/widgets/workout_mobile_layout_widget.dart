import 'package:flutter/material.dart';
import 'workout_form_widget.dart';
import 'exercise_selection_mobile_widget.dart';
import 'set_number_picker_widget.dart';
import 'add_exercise_button_widget.dart';
import 'exercise_list_widget.dart';

class WorkoutMobileLayoutWidget extends StatelessWidget {
  final VoidCallback? onSave;

  const WorkoutMobileLayoutWidget({
    super.key,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Control UI section
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WorkoutFormWidget(onSave: onSave),
            const ExerciseSelectionMobileWidget(),
            const SetNumberPickerWidget(isMobile: true),
            const AddExerciseButtonWidget(isMobile: true),
            const SizedBox(height: 20),
          ],
        ),
        // Divider
        const Divider(),
        // Exercise list section
        const Expanded(
          child: ExerciseListWidget(),
        ),
      ],
    );
  }
}
