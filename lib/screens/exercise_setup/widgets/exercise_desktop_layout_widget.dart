import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercise_form_desktop_widget.dart';
import 'exercise_confirm_button_widget.dart';
import 'muscle_selection_desktop_widget.dart';
import '../controllers/muscle_selection_controller.dart';

class ExerciseDesktopLayoutWidget extends StatelessWidget {
  final double boxSpace;
  final VoidCallback? onSuccess;

  const ExerciseDesktopLayoutWidget({
    super.key,
    this.boxSpace = 20,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left side - Exercise form
        Expanded(
          flex: 1,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                ExerciseFormDesktopWidget(boxSpace: boxSpace),
                SizedBox(height: boxSpace),
                ExerciseConfirmButtonWidget(onSuccess: onSuccess),
                const Text("Confirm")
              ],
            ),
          ),
        ),
        // Right side - Muscle selection (always visible)
        SizedBox(
          width: 400,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: ChangeNotifierProvider(
              create: (context) => MuscleSelectionController(),
              child: const MuscleSelectionDesktopWidget(),
            ),
          ),
        ),
      ],
    );
  }
}
