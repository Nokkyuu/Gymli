import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/exercise_setup_controller.dart';

class ExerciseFormMobileWidget extends StatelessWidget {
  final double boxSpace;

  const ExerciseFormMobileWidget({
    super.key,
    this.boxSpace = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseSetupController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                textAlign: TextAlign.center,
                controller: controller.exerciseTitleController,
                obscureText: false,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Exercise Name',
                ),
              ),
            ),
            SizedBox(height: boxSpace),
            SizedBox(height: boxSpace),
            SizedBox(height: boxSpace),
            const Text("Exercise Utility"),
            SizedBox(height: boxSpace),
            SegmentedButton<ExerciseDevice>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<ExerciseDevice>>[
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.free,
                      icon: FaIcon(FontAwesomeIcons.dumbbell)),
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.machine,
                      icon: Icon(Icons.forklift)),
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.cable, icon: Icon(Icons.cable)),
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.body,
                      icon: Icon(Icons.sports_martial_arts)),
                ],
                selected: <ExerciseDevice>{controller.chosenDevice},
                onSelectionChanged: (Set<ExerciseDevice> newSelection) {
                  controller.updateDevice(newSelection.first);
                }),
            SizedBox(height: boxSpace),
            SizedBox(height: boxSpace),
            SizedBox(height: boxSpace),
            const Text("Repetition Range"),
            SizedBox(height: boxSpace),
            RangeSlider(
              values: controller.repRange,
              max: 30,
              min: 1,
              divisions: 29,
              labels: RangeLabels(
                controller.repRange.start.round().toString(),
                controller.repRange.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                controller.updateRepRange(values);
              },
            ),
            SizedBox(height: boxSpace),
            const Text("Weight Increase Increments"),
            SizedBox(height: boxSpace),
            Slider(
              value: controller.weightInc == 0 ? 1 : controller.weightInc,
              min: 1,
              max: 10,
              divisions: 18,
              label: controller.weightInc.toString(),
              onChanged: (double value) {
                controller.updateWeightIncrement(value);
              },
            ),
          ],
        );
      },
    );
  }
}
