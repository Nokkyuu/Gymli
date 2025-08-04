import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/exercise_setup_controller.dart';

class ExerciseFormDesktopWidget extends StatelessWidget {
  final double boxSpace;

  const ExerciseFormDesktopWidget({
    super.key,
    this.boxSpace = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseSetupController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: SizedBox(
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
            ),
            SizedBox(height: boxSpace),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: boxSpace),
                SizedBox(width: boxSpace), // Spacer
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          SizedBox(width: 30),
                          Text("Exercise Utility"),
                        ],
                      ),
                      RadioListTile<ExerciseDevice>(
                        title: const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 30,
                                child: FaIcon(FontAwesomeIcons.dumbbell)),
                            SizedBox(width: 8),
                            Text('Free Weights'),
                          ],
                        ),
                        value: ExerciseDevice.free,
                        groupValue: controller.chosenDevice,
                        onChanged: (ExerciseDevice? value) {
                          if (value != null) controller.updateDevice(value);
                        },
                      ),
                      RadioListTile<ExerciseDevice>(
                        title: const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 30, child: Icon(Icons.forklift)),
                            SizedBox(width: 8),
                            Text('Machine'),
                          ],
                        ),
                        value: ExerciseDevice.machine,
                        groupValue: controller.chosenDevice,
                        onChanged: (ExerciseDevice? value) {
                          if (value != null) controller.updateDevice(value);
                        },
                      ),
                      RadioListTile<ExerciseDevice>(
                        title: const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 30, child: Icon(Icons.cable)),
                            SizedBox(width: 8),
                            Text('Cable'),
                          ],
                        ),
                        value: ExerciseDevice.cable,
                        groupValue: controller.chosenDevice,
                        onChanged: (ExerciseDevice? value) {
                          if (value != null) controller.updateDevice(value);
                        },
                      ),
                      RadioListTile<ExerciseDevice>(
                        title: const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 30,
                                child: Icon(Icons.sports_martial_arts)),
                            SizedBox(width: 8),
                            Text('Bodyweight'),
                          ],
                        ),
                        value: ExerciseDevice.body,
                        groupValue: controller.chosenDevice,
                        onChanged: (ExerciseDevice? value) {
                          if (value != null) controller.updateDevice(value);
                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text("Repetition Range"),
                    SizedBox(height: boxSpace),
                    RotatedBox(
                      quarterTurns: 3,
                      child: RangeSlider(
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
                    )
                  ],
                ),
                SizedBox(width: boxSpace),
                Column(
                  children: [
                    const Text("Weight Increments"),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: controller.weightInc,
                        min: 1,
                        max: 10,
                        divisions: 18,
                        label: controller.weightInc.toString(),
                        onChanged: (double value) {
                          controller.updateWeightIncrement(value);
                        },
                      ),
                    ),
                    Text("${controller.weightInc} kg"),
                  ],
                ),
                SizedBox(width: boxSpace),
                SizedBox(width: boxSpace),
              ],
            )
          ],
        );
      },
    );
  }
}
