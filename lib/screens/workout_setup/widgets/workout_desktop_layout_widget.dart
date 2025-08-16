import 'package:flutter/material.dart';
import 'workout_form_widget.dart';
import 'exercise_selection_desktop_widget.dart';
import 'set_number_picker_widget.dart';
import 'add_exercise_button_widget.dart';
import 'exercise_list_widget.dart';

class WorkoutDesktopLayoutWidget extends StatelessWidget {
  final VoidCallback? onSave;

  const WorkoutDesktopLayoutWidget({
    super.key,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Main content takes 4/7 of the width
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                WorkoutFormWidget(onSave: onSave),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 60),
                    ExerciseSelectionDesktopWidget(),
                    SizedBox(width: 20),
                    SetNumberPickerWidget(isMobile: false),
                    SizedBox(width: 20),
                    AddExerciseButtonWidget(isMobile: false),
                    SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Vertical divider line
        Container(
          width: 1,
          color: Colors.black,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
        ),
        // Exercise list takes 3/7 of the width
        const Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.only(top: 16.0, right: 16.0),
            child: ExerciseListWidget(),
          ),
        ),
      ],
    );
  }
}
