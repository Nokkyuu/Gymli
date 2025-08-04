import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:numberpicker/numberpicker.dart';
import '../controllers/exercise_selection_controller.dart';

class SetNumberPickerWidget extends StatelessWidget {
  final bool isMobile;

  const SetNumberPickerWidget({
    super.key,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseSelectionController>(
      builder: (context, controller, child) {
        return isMobile
            ? _buildMobilePicker(controller)
            : _buildDesktopPicker(controller);
      },
    );
  }

  Widget _buildMobilePicker(ExerciseSelectionController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            const Text('Warm Ups'),
            NumberPicker(
              decoration: BoxDecoration(border: Border.all()),
              value: controller.warmups,
              minValue: 0,
              maxValue: 10,
              onChanged: (value) => controller.updateWarmups(value),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Column(
          children: [
            const Text('Work Sets'),
            NumberPicker(
              decoration: BoxDecoration(border: Border.all()),
              value: controller.worksets,
              minValue: 0,
              maxValue: 10,
              onChanged: (value) => controller.updateWorksets(value),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildDesktopPicker(ExerciseSelectionController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 20),
        Column(
          children: [
            const Text('Warm Ups'),
            SizedBox(
              width: 80,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                controller:
                    TextEditingController(text: controller.warmups.toString()),
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? 0;
                  controller.updateWarmups(intValue);
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 80,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                controller:
                    TextEditingController(text: controller.worksets.toString()),
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? 1;
                  controller.updateWorksets(intValue);
                },
              ),
            ),
            const Text('Work Sets'),
          ],
        ),
      ],
    );
  }
}
