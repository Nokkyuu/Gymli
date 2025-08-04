import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercise_form_mobile_widget.dart';
import 'exercise_confirm_button_widget.dart';
import 'muscle_selection_bottom_sheet_widget.dart';
import '../controllers/muscle_selection_controller.dart';

class ExerciseMobileLayoutWidget extends StatelessWidget {
  final double boxSpace;
  final VoidCallback? onSuccess;

  const ExerciseMobileLayoutWidget({
    super.key,
    this.boxSpace = 20,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          ExerciseFormMobileWidget(boxSpace: boxSpace),
          SizedBox(height: boxSpace),
          IconButton(
            icon: const Icon(Icons.accessibility_new),
            iconSize: 50,
            tooltip: 'muscles',
            onPressed: () {
              showModalBottomSheet<dynamic>(
                isScrollControlled: true,
                context: context,
                sheetAnimationStyle: AnimationStyle(
                  duration: const Duration(milliseconds: 600),
                  reverseDuration: const Duration(milliseconds: 600),
                ),
                builder: (BuildContext context) {
                  return ChangeNotifierProvider(
                    create: (context) => MuscleSelectionController(),
                    child: const MuscleSelectionBottomSheetWidget(),
                  );
                },
              );
            },
          ),
          SizedBox(height: boxSpace),
          ExerciseConfirmButtonWidget(onSuccess: onSuccess),
        ],
      ),
    );
  }
}
