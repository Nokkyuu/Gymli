import 'package:flutter/material.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:hive/hive.dart';
import 'dart:developer';

enum ExerciseDevice { free, machine, cable, body }

class ExerciseSetupScreen extends StatefulWidget {
  const ExerciseSetupScreen({super.key});

  @override
  State<ExerciseSetupScreen> createState() => _ExerciseSetupScreenState();
}

void add_exercise(String exerciseName, ExerciseDevice chosenDevice, int minRep, int repRange, double weightInc, List<int> muscleGroups) async {
  final box = await Hive.openBox<Exercise>('Exercises');
  int exerciseType = chosenDevice.index;
  List<String> muscleGroupStrings = [""]; // muscleGroups -> vielleicht besser Liste?
  var boxmap = box.values.toList();
  List<String> exerciseList = [];
  for (var e in boxmap) {
    exerciseList.add(e.name);
  }
  // boxmap.values.forEach((v) => print("Value: $v"));

  // var a = boxmap.getAllKeys();
  // log(a);

  if (!exerciseList.contains(exerciseName)) {
    box.add(Exercise(name: exerciseName, type: exerciseType, muscleGroups: muscleGroupStrings, defaultRepBase: minRep, defaultRepMax: repRange, defaultIncrement: weightInc));
  } else {
    box.putAt(exerciseList.indexOf(exerciseName), Exercise(name: exerciseName, type: exerciseType, muscleGroups: muscleGroupStrings, defaultRepBase: minRep, defaultRepMax: repRange, defaultIncrement: weightInc));

  }

}


class _ExerciseSetupScreenState extends State<ExerciseSetupScreen> {
  ExerciseDevice chosenDevice = ExerciseDevice.free;
  double boxSpace = 10;
  double minRep = 10;
  double repRange = 15;
  double weightInc = 2.5;
  List<int> muscleGroups = [1];
  final exerciseTitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const title = 'New Exercise';
    return MaterialApp(
        title: title,
        home: Scaffold(
            appBar: AppBar(
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black54,
                ),
              ),
              title: SizedBox(
                width: 300,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: exerciseTitleController,
                  obscureText: false,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'GiveMeName',
                    //alignLabelWithHint: true
                  ),
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // SizedBox(height: boxSpace),
                  // const SizedBox(
                  //   width: 250,
                  //   child: TextField(
                  //         textAlign: TextAlign.left,
                  //         //TODO: Fonz Size
                  //         obscureText: false,
                  //         decoration: InputDecoration(
                  //           border: UnderlineInputBorder(),
                  //           labelText: 'GiveMeName',
                  //         ),
                  //       ),
                  // ),
                  SizedBox(height: boxSpace),
                  SegmentedButton<ExerciseDevice>(
                      segments: const <ButtonSegment<ExerciseDevice>>[
                        ButtonSegment<ExerciseDevice>(
                            value: ExerciseDevice.free,
                            label: Text('Free'),
                            icon: Icon(Icons.sports_tennis)),
                        ButtonSegment<ExerciseDevice>(
                            value: ExerciseDevice.machine,
                            label: Text('Machine'),
                            icon: Icon(Icons.agriculture_outlined)),
                        ButtonSegment<ExerciseDevice>(
                            value: ExerciseDevice.cable,
                            label: Text('Cable'),
                            icon: Icon(Icons.cable)),
                        ButtonSegment<ExerciseDevice>(
                            value: ExerciseDevice.body,
                            label: Text('Body'),
                            icon: Icon(Icons.sports_martial_arts)),
                      ],
                      selected: <ExerciseDevice>{
                        chosenDevice
                      },
                      onSelectionChanged: (Set<ExerciseDevice> newSelection) {
                        setState(() {
                          chosenDevice = newSelection.first;
                        });
                      }),
                  SizedBox(height: boxSpace),
                  const HeadCard(headline: "Minimum Repetitions"),
                  Slider(
                    value: minRep,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: minRep.toString(),
                    onChanged: (double value) {
                      setState(() {
                        minRep = value;
                      });
                    },
                  ),
                  SizedBox(height: boxSpace),
                  const HeadCard(headline: "Repetition Range"),
                  Slider(
                    value: repRange,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: repRange.toString(),
                    onChanged: (double value) {
                      setState(() {
                        repRange = value;
                      });
                    },
                  ),
                  SizedBox(height: boxSpace),
                  const HeadCard(headline: "Weight Increments"),
                  Slider(
                    value: weightInc,
                    min: 1,
                    max: 10,
                    divisions: 18,
                    label: weightInc.toString(),
                    onChanged: (double value) {
                      setState(() {
                        weightInc = value;
                      });
                    },
                  ),

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
                          duration: const Duration(milliseconds: 300),
                          reverseDuration: const Duration(milliseconds: 300),
                        ),
                        builder: (BuildContext context) {
                          return const BottomSheet();
                        },
                      );
                    },
                  ),
                  SizedBox(height: boxSpace),
                  IconButton(
                    icon: const Icon(Icons.check),
                    iconSize: 40,
                    tooltip: 'Confirm',
                    onPressed: () {
                      add_exercise(exerciseTitleController.text, chosenDevice, minRep.toInt(), repRange.toInt(), weightInc, muscleGroups);
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            )));
  }
}

class BottomSheet extends StatelessWidget {
  const BottomSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            //const Text('Bottom sheet'),
            ElevatedButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
            const Image(image: AssetImage('images/MuscleTemp.jpeg')),
          ],
        ),
      ),
    );
  }
}

class HeadCard extends StatelessWidget {
  const HeadCard({
    super.key,
    required this.headline,
  });
  final String headline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          headline,
          style: style,
        ),
      ),
    );
  }
}

class ObscuredTextFieldSample extends StatelessWidget {
  const ObscuredTextFieldSample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 250,
      child: TextField(
        obscureText: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'GiveMeName',
        ),
      ),
    );
  }
}
