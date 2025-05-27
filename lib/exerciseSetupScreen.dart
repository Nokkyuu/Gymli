/// Exercise Setup Screen - Exercise Configuration Interface
///
/// This screen provides a comprehensive interface for creating, editing, and
/// configuring exercises within the workout application. It handles exercise
/// metadata, muscle group assignments, and equipment specifications.
///
/// Key features:
/// - Exercise creation and editing capabilities
/// - Equipment type selection (free weights, machines, cables, bodyweight)
/// - Muscle group activation mapping and visualization
/// - Exercise name management and validation
/// - Primary and secondary muscle group assignments
/// - Visual muscle group selection interface
/// - Integration with global exercise database
/// - Real-time exercise data persistence
///
/// The screen enables users to customize their exercise library and ensure
/// proper muscle group tracking for comprehensive workout analysis.
library;

// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'globals.dart' as globals;
import 'user_service.dart';
import 'api_models.dart';

enum ExerciseDevice { free, machine, cable, body }

final exerciseMap = [
  ExerciseDevice.free,
  ExerciseDevice.machine,
  ExerciseDevice.cable,
  ExerciseDevice.body
];

// ignore: must_be_immutable
class ExerciseSetupScreen extends StatefulWidget {
  String exerciseName;
  ExerciseSetupScreen(this.exerciseName, {super.key});

  @override
  State<ExerciseSetupScreen> createState() => _ExerciseSetupScreenState();
}

void get_exercise_list() async {
  try {
    final userService = UserService();
    final exercises = await userService.getExercises();
    List<String> exerciseList = [];
    for (var e in exercises) {
      exerciseList.add(e['name']);
    }
    globals.exerciseList = exerciseList;
  } catch (e) {
    print('Error loading exercise list: $e');
    globals.exerciseList = [];
  }
}

void add_exercise(String exerciseName, ExerciseDevice chosenDevice, int minRep,
    int maxRep, double weightInc) async {
  try {
    final userService = UserService();
    int exerciseType = chosenDevice.index;

    // Get muscle group intensities
    final muscleIntensities = <double>[];
    for (var m in muscleGroupNames) {
      muscleIntensities.add(globals.muscle_val[m] ?? 0.0);
    }

    // Pad or trim to match expected muscle groups (14 total)
    while (muscleIntensities.length < 14) {
      muscleIntensities.add(0.0);
    }

    await userService.createExercise(
      name: exerciseName,
      type: exerciseType,
      defaultRepBase: minRep,
      defaultRepMax: maxRep,
      defaultIncrement: weightInc,
      pectoralisMajor:
          muscleIntensities.isNotEmpty ? muscleIntensities[0] : 0.0,
      trapezius: muscleIntensities.length > 1 ? muscleIntensities[1] : 0.0,
      biceps: muscleIntensities.length > 2 ? muscleIntensities[2] : 0.0,
      abdominals: muscleIntensities.length > 3 ? muscleIntensities[3] : 0.0,
      frontDelts: muscleIntensities.length > 4 ? muscleIntensities[4] : 0.0,
      deltoids: muscleIntensities.length > 5 ? muscleIntensities[5] : 0.0,
      backDelts: muscleIntensities.length > 6 ? muscleIntensities[6] : 0.0,
      latissimusDorsi:
          muscleIntensities.length > 7 ? muscleIntensities[7] : 0.0,
      triceps: muscleIntensities.length > 8 ? muscleIntensities[8] : 0.0,
      gluteusMaximus: muscleIntensities.length > 9 ? muscleIntensities[9] : 0.0,
      hamstrings: muscleIntensities.length > 10 ? muscleIntensities[10] : 0.0,
      quadriceps: muscleIntensities.length > 11 ? muscleIntensities[11] : 0.0,
      forearms: muscleIntensities.length > 12 ? muscleIntensities[12] : 0.0,
      calves: muscleIntensities.length > 13 ? muscleIntensities[13] : 0.0,
    );
  } catch (e) {
    print('Error adding exercise: $e');
  }
}

class _ExerciseSetupScreenState extends State<ExerciseSetupScreen> {
  ExerciseDevice chosenDevice = ExerciseDevice.free;
  double boxSpace = 20;
  double minRep = 10;
  double maxRep = 15;
  RangeValues repRange = const RangeValues(10, 20);
  double weightInc = 2.5;
  List<String> muscleGroups = [];
  List<double> muscleIntensities = [];
  final exerciseTitleController = TextEditingController();
  ApiExercise? currentExercise;
  final userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  void _loadExerciseData() async {
    if (widget.exerciseName.isEmpty) return;

    try {
      final exercises = await userService.getExercises();
      final exerciseData = exercises.firstWhere(
        (item) => item['name'] == widget.exerciseName,
        orElse: () => null,
      );

      if (exerciseData != null) {
        final exercise = ApiExercise.fromJson(exerciseData);
        setState(() {
          currentExercise = exercise;
          exerciseTitleController.text = exercise.name;
          chosenDevice = ExerciseDevice.values[exercise.type];
          minRep = exercise.defaultRepBase.toDouble();
          maxRep = exercise.defaultRepMax.toDouble();
          repRange = RangeValues(minRep, maxRep);
          weightInc = exercise.defaultIncrement;

          // Reset all muscle values
          for (var m in muscleGroupNames) {
            globals.muscle_val[m] = 0.0;
          }

          // Set muscle intensities
          final intensities = exercise.muscleIntensities;
          for (int i = 0;
              i < muscleGroupNames.length && i < intensities.length;
              i++) {
            globals.muscle_val[muscleGroupNames[i]] = intensities[i];
          }
        });
      }
    } catch (e) {
      print('Error loading exercise data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          title: const Text("Exercise Setup"),
          actions: [
            IconButton(
                onPressed: () async {
                  if (currentExercise != null && currentExercise!.id != null) {
                    try {
                      // Delete the exercise via API
                      await userService.deleteExercise(currentExercise!.id!);

                      // Delete all training sets for this exercise
                      final trainingSets = await userService.getTrainingSets();
                      for (var set in trainingSets) {
                        if (set['exercise_id'] == currentExercise!.id) {
                          await userService.deleteTrainingSet(set['id']);
                        }
                      }

                      int count = 0;
                      Navigator.of(context).popUntil((_) => count++ >= 2);
                    } catch (e) {
                      print('Error deleting exercise: $e');
                      // Show error to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting exercise: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete))
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: exerciseTitleController,
                  obscureText: false,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Exercise Name',
                    //alignLabelWithHint: true
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
                        //label: Text('Free'),

                        icon: FaIcon(FontAwesomeIcons.dumbbell)),
                    ButtonSegment<ExerciseDevice>(
                        value: ExerciseDevice.machine,
                        //label: Text('Machine',softWrap: false, overflow: TextOverflow.fade),
                        icon: Icon(Icons.forklift)),
                    ButtonSegment<ExerciseDevice>(
                        value: ExerciseDevice.cable,
                        //label: Text('Cable'),
                        icon: Icon(Icons.cable)),
                    ButtonSegment<ExerciseDevice>(
                        value: ExerciseDevice.body,
                        //label: Text('Body'),
                        icon: Icon(Icons.sports_martial_arts)),
                  ],
                  selected: <ExerciseDevice>{chosenDevice},
                  onSelectionChanged: (Set<ExerciseDevice> newSelection) {
                    setState(() {
                      chosenDevice = newSelection.first;
                    });
                  }),
              SizedBox(height: boxSpace),
              SizedBox(height: boxSpace),
              SizedBox(height: boxSpace),
              const Text("Repetition Range"),
              SizedBox(height: boxSpace),
              RangeSlider(
                values: repRange,
                max: 30,
                min: 1,
                divisions: 29,
                labels: RangeLabels(
                  repRange.start.round().toString(),
                  repRange.end.round().toString(),
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    RangeValues newValues = RangeValues(
                        values.start,
                        values.start == values.end
                            ? values.end + 1
                            : values.end);
                    repRange = newValues;
                    minRep = newValues.start;
                    maxRep = newValues.end;
                  });
                },
              ),
              SizedBox(height: boxSpace),
              const Text("Weight Increase Increments"),
              SizedBox(height: boxSpace),
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
                      duration: const Duration(milliseconds: 600),
                      reverseDuration: const Duration(milliseconds: 600),
                    ),
                    builder: (BuildContext context) {
                      return const BottomSheet();
                    },
                  );
                },
              ),
              SizedBox(height: boxSpace),
              ConfirmButton(context),
            ],
          ),
        ));
  }

  IconButton ConfirmButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.check),
      iconSize: 40,
      tooltip: 'Confirm',
      onPressed: () => showDialog<String>(
        context: context,
        builder: (BuildContext context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                () {
                  if (!globals.exerciseList
                      .contains(exerciseTitleController.text)) {
                    get_exercise_list(); //important redundancy if you dont leave the screen after saving
                    return Text(
                      'Save Exercise:\n',
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                  }
                  return Text('Attention! \nOverwriting Exercise:\n',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge);
                }(),
                Card(
                    elevation: 5.0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${exerciseTitleController.text}\n',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(chosenDevice.name),
                          Text(
                              '${minRep.toInt()} to ${minRep.toInt() + maxRep.toInt()} reps'),
                          Text('$weightInc kg increments'),
                        ],
                      ),
                    )),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        add_exercise(exerciseTitleController.text, chosenDevice,
                            minRep.toInt(), maxRep.toInt(), weightInc);
                        setState(() {});
                        int count = 0;
                        Navigator.of(context).popUntil((_) => count++ >= 2);
                      },
                      child: const Text('Confirm'),
                    ),
                    TextButton(
                      onPressed: () {
                        int count = 0;
                        Navigator.of(context).popUntil((_) => count++ >= 2);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )

      // add_exercise(
      //     exerciseTitleController.text,
      //     chosenDevice,
      //     minRep.toInt(),
      //     maxRep.toInt(),
      //     weightInc,
      //     muscleGroups);
      // setState(() {});
      // Navigator.pop(context);
      ,
    );
  }
}

class BottomSheet extends StatefulWidget {
  const BottomSheet({
    super.key,
  });

  @override
  State<BottomSheet> createState() => _BottomSheetState();
}

class _BottomSheetState extends State<BottomSheet> {
  final List<List<String>> frontImages = [
    ['images/muscles/Front_biceps.png', 'Biceps'],
    ['images/muscles/Front_calves.png', 'Calves'],
    ['images/muscles/Front_Front_delts.png', 'Front Delts'],
    ['images/muscles/Front_forearms.png', 'Forearms'],
    ['images/muscles/Front_pecs.png', 'Pectoralis major'],
    ['images/muscles/Front_quads.png', 'Quadriceps'],
    ['images/muscles/Front_sideabs.png', 'Abdominals'],
    ['images/muscles/Front_abs.png', 'Abdominals'],
    ['images/muscles/Front_trapz.png', 'Trapezius'],
    ['images/muscles/Front_abs.png', 'Abdominals']
  ];
  final List<List<String>> backImages = [
    ['images/muscles/Back_calves.png', 'Calves'],
    ['images/muscles/Back_Back_delts.png', 'Back Delts'],
    ['images/muscles/Back_Back_delts2.png', 'Back Delts'],
    ['images/muscles/Back_Front_delts.png', 'Front Delts'],
    ['images/muscles/Back_Side_delts.png', 'Deltoids'],
    ['images/muscles/Back_forearms.png', 'Forearms'],
    ['images/muscles/Back_glutes.png', 'Gluteus maximus'],
    ['images/muscles/Back_hamstrings.png', 'Hamstrings'],
    ['images/muscles/Back_lats.png', 'Latissimus dorsi'],
    ['images/muscles/Back_trapz.png', 'Trapezius'],
    ['images/muscles/Back_triceps.png', 'Triceps'],
  ];
  final List<List> frontButtons = [
    [0.35, 0.4, 'Biceps'], //Biceps
    [0.46, 0.4, 'Forearms'], //Forearms
    [0.25, 0.4, 'Front Delts'], //Front Delts
    [0.28, 0.7, 'Pectoralis major'], // Pectoralis major
    [0.4, 0.7, 'Abdominals'], //abdominals
    [0.2, 0.7, 'Trapezius'], //Trapezius
    [0.6, 0.62, 'Quadriceps'], //Quadriceps
    [0.8, 0.58, 'Calves'], //Calves
  ];
  final List<List> backButtons = [
    [0.82, 0.6, 'Calves'], //Calves
    [0.2, 0.45, 'Deltoids'], //Side Delts
    [0.26, 0.38, 'Back Delts'], // Back Delts
    [0.5, 0.4, 'Forearms'], // Forearms
    [0.55, 0.7, 'Gluteus maximus'], // Gluteus
    [0.68, 0.6, 'Hamstrings'], // Hamstrings
    [0.4, 0.7, 'Latissimus dorsi'], //Latissimus dorsi
    [0.2, 0.7, 'Trapezius'], // Trapezius
    [0.35, 0.4, 'Triceps'], //Triceps
  ];

  opacity_change(double op) {
    if (op >= 1.0) {
      op = 0.0;
    } else {
      op += 1 / 4;
    }
    return op;
  }

  Key parent = const Key("parent");
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: parent,
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
            LayoutBuilder(builder: (context, constraints) {
              return Stack(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth / 2,
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Transform.scale(
                          scaleX: -1,
                          child: Stack(children: [
                            Image(
                              width: constraints.maxWidth / 3,
                              fit: BoxFit.fill,
                              image: const AssetImage(
                                  'images/muscles/Front_bg.png'),
                            ),
                            for (var i in frontImages)
                              Image(
                                fit: BoxFit.fill,
                                width: constraints.maxWidth / 3,
                                image: AssetImage(i[0]),
                                opacity: AlwaysStoppedAnimation(
                                    globals.muscle_val[i[1]]!),
                              ),
                            for (var i in frontButtons)
                              FractionallySizedBox(
                                  alignment: Alignment.bottomRight,
                                  heightFactor: i[0],
                                  widthFactor: i[1],
                                  child: Stack(
                                    alignment: AlignmentDirectional.bottomEnd,
                                    children: [
                                      TextButton(
                                          onPressed: () => setState(() {
                                                globals.muscle_val[i[2]] =
                                                    opacity_change(globals
                                                        .muscle_val[i[2]]!);
                                              }),
                                          child: Transform.scale(
                                              scaleX: -1,
                                              child: Text(
                                                ("${(globals.muscle_val[i[2]]! * 100).round()}%"),
                                                maxLines: 1,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge,
                                                overflow: TextOverflow.visible,
                                              )))
                                    ],
                                  )),
                          ])),
                    ),
                    SizedBox(
                        width: constraints.maxWidth / 2,
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Stack(children: [
                          Image(
                              fit: BoxFit.fill,
                              width: constraints.maxWidth / 3,
                              image: const AssetImage(
                                  'images/muscles/Back_bg.png')),
                          for (var i in backImages)
                            Image(
                              fit: BoxFit.fill,
                              width: constraints.maxWidth / 3,
                              image: AssetImage(i[0]),
                              opacity: AlwaysStoppedAnimation(
                                  globals.muscle_val[i[1]]!),
                            ),
                          for (var i in backButtons)
                            FractionallySizedBox(
                                alignment: Alignment.bottomRight,
                                heightFactor: i[0],
                                widthFactor: i[1],
                                child: Stack(
                                  alignment: AlignmentDirectional.bottomEnd,
                                  children: [
                                    TextButton(
                                        onPressed: () => setState(() {
                                              globals.muscle_val[i[2]] =
                                                  opacity_change(globals
                                                      .muscle_val[i[2]]!);
                                            }),
                                        child: Text(
                                          ("${(globals.muscle_val[i[2]]! * 100).round()}%"),
                                          maxLines: 1,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          overflow: TextOverflow.visible,
                                        ))
                                  ],
                                )),
                        ]))
                  ],
                ),
                //             Positioned(
                //   left: constraints.maxWidth/3,
                //   child: Image(
                //                 width: constraints.maxWidth/3,
                //                 fit: BoxFit.fill,
                //                 image: const AssetImage('images/muscles/sideview.png'),
                //               ),
                // ),
              ]);
            }),
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
    final style = theme.textTheme.bodyMedium!.copyWith();

    return Card(
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
