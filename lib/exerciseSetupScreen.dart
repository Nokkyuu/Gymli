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
import 'utils/globals.dart' as globals;
import 'utils/user_service.dart';
import 'utils/api_models.dart';
import 'utils/responsive_helper.dart';
import 'info.dart';

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

    // Check if exercise exists
    final exercises = await userService.getExercises();
    final existing = exercises.firstWhere(
      (e) => e['name'] == exerciseName,
      orElse: () => null,
    );

    if (existing != null && existing['id'] != null) {
      // Update existing exercise
      await userService.updateExercise(existing['id'], {
        'user_name': userService.userName,
        'name': exerciseName,
        'type': exerciseType,
        'default_rep_base': minRep,
        'default_rep_max': maxRep,
        'default_increment': weightInc,
        'pectoralis_major': muscleIntensities[0],
        'trapezius': muscleIntensities[1],
        'biceps': muscleIntensities[2],
        'abdominals': muscleIntensities[3],
        'front_delts': muscleIntensities[4],
        'deltoids': muscleIntensities[5],
        'back_delts': muscleIntensities[6],
        'latissimus_dorsi': muscleIntensities[7],
        'triceps': muscleIntensities[8],
        'gluteus_maximus': muscleIntensities[9],
        'hamstrings': muscleIntensities[10],
        'quadriceps': muscleIntensities[11],
        'forearms': muscleIntensities[12],
        'calves': muscleIntensities[13],
      });
    } else {
      // Create new exercise
      await userService.createExercise(
        name: exerciseName,
        type: exerciseType,
        defaultRepBase: minRep,
        defaultRepMax: maxRep,
        defaultIncrement: weightInc,
        pectoralisMajor: muscleIntensities[0],
        trapezius: muscleIntensities[1],
        biceps: muscleIntensities[2],
        abdominals: muscleIntensities[3],
        frontDelts: muscleIntensities[4],
        deltoids: muscleIntensities[5],
        backDelts: muscleIntensities[6],
        latissimusDorsi: muscleIntensities[7],
        triceps: muscleIntensities[8],
        gluteusMaximus: muscleIntensities[9],
        hamstrings: muscleIntensities[10],
        quadriceps: muscleIntensities[11],
        forearms: muscleIntensities[12],
        calves: muscleIntensities[13],
      );
    }
    // Notify that data has changed
    UserService().notifyDataChanged();
  } catch (e) {
    print('Error adding/updating exercise: $e');
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
    final isMobileWeb = ResponsiveHelper.isWebMobile(context);

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
          buildInfoButton('Exercise Setup Info', context,
              () => showInfoDialogExerciseSetup(context)),
          IconButton(
              onPressed: () async {
                if (currentExercise != null && currentExercise!.id != null) {
                  final exerciseId = currentExercise!.id!;

                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete "${currentExercise!.name}"?'),
                      content: const Text(
                          'This will permanently delete the exercise and ALL training history. This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  try {
                    // CORRECT ORDER: Delete dependent records FIRST
                    print('Deleting training sets for exercise $exerciseId');
                    final trainingSets = await userService.getTrainingSets();
                    for (var set in trainingSets) {
                      if (set['exercise_id'] == exerciseId) {
                        await userService.deleteTrainingSet(set['id']);
                      }
                    }

                    // THEN delete the exercise (no more foreign key violations)
                    print('Deleting exercise $exerciseId');
                    await userService.deleteExercise(exerciseId);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Exercise deleted successfully')),
                    );

                    int count = 0;
                    Navigator.of(context).popUntil((_) => count++ >= 2);
                  } catch (e) {
                    print('Error deleting exercise: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting exercise: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: isMobileWeb
          ? _buildMobileWebLayout(context)
          : _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileWebLayout(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildExerciseForm(context),
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
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
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
                _buildExerciseFormDesktop(context),
                SizedBox(height: boxSpace),
                ConfirmButton(context),
                Text("Confirm")
              ],
            ),
          ),
        ),
        // Right side - Muscle selection (always visible)
        SizedBox(
          //flex: 1,
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
            child: MuscleSelectionWidget(
                key: ValueKey(exerciseTitleController.text +
                    globals.muscle_val.values.join(','))),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseForm(BuildContext context) {
    return Column(
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
                  value: ExerciseDevice.machine, icon: Icon(Icons.forklift)),
              ButtonSegment<ExerciseDevice>(
                  value: ExerciseDevice.cable, icon: Icon(Icons.cable)),
              ButtonSegment<ExerciseDevice>(
                  value: ExerciseDevice.body,
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
              RangeValues newValues = RangeValues(values.start,
                  values.start == values.end ? values.end + 1 : values.end);
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
      ],
    );
  }

  Widget _buildExerciseFormDesktop(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: SizedBox(
            width: 300,
            child: TextField(
              textAlign: TextAlign.center,
              controller: exerciseTitleController,
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
                      SizedBox(
                        width: 30,
                      ),
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
                    groupValue: chosenDevice,
                    onChanged: (ExerciseDevice? value) {
                      setState(() {
                        chosenDevice = value!;
                      });
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
                    groupValue: chosenDevice,
                    onChanged: (ExerciseDevice? value) {
                      setState(() {
                        chosenDevice = value!;
                      });
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
                    groupValue: chosenDevice,
                    onChanged: (ExerciseDevice? value) {
                      setState(() {
                        chosenDevice = value!;
                      });
                    },
                  ),
                  RadioListTile<ExerciseDevice>(
                    title: const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 30, child: Icon(Icons.sports_martial_arts)),
                        SizedBox(width: 8),
                        Text('Bodyweight'),
                      ],
                    ),
                    value: ExerciseDevice.body,
                    groupValue: chosenDevice,
                    onChanged: (ExerciseDevice? value) {
                      setState(() {
                        chosenDevice = value!;
                      });
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
                ),
                Text("$weightInc kg"),
              ],
            ),
            SizedBox(width: boxSpace),
            SizedBox(width: boxSpace),
          ],
        )
      ],
    );
  }

  IconButton ConfirmButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.check),
      iconSize: 40,
      tooltip: 'Confirm',
      onPressed: () => showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  globals.exerciseList.contains(exerciseTitleController.text)
                      ? Icons.edit
                      : Icons.add_circle,
                  size: 48,
                  color: globals.exerciseList
                          .contains(exerciseTitleController.text)
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  globals.exerciseList.contains(exerciseTitleController.text)
                      ? 'Update Exercise'
                      : 'Create New Exercise',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (globals.exerciseList.contains(exerciseTitleController.text))
                  const Text(
                    'This will update the existing exercise configuration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fitness_center, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                exerciseTitleController.text,
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.category, size: 16),
                            const SizedBox(width: 4),
                            Text('Equipment: ${_getDeviceName(chosenDevice)}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.repeat, size: 16),
                            const SizedBox(width: 4),
                            Text('Reps: ${minRep.toInt()} - ${maxRep.toInt()}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.add, size: 16),
                            const SizedBox(width: 4),
                            Text('Weight increments: $weightInc kg'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Active muscle groups: ${_getActiveMuscleGroups()}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        add_exercise(
                          exerciseTitleController.text,
                          chosenDevice,
                          minRep.toInt(),
                          maxRep.toInt(),
                          weightInc,
                        );
                        setState(() {});
                        int count = 0;
                        Navigator.of(context).popUntil((_) => count++ >= 2);
                      },
                      child: Text(
                        globals.exerciseList
                                .contains(exerciseTitleController.text)
                            ? 'Update Exercise'
                            : 'Create Exercise',
                      ),
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
    [0.35, 0.4, 'Biceps'],
    [0.46, 0.4, 'Forearms'], // <-- fix here
    [0.25, 0.4, 'Front Delts'],
    [0.28, 0.7, 'Pectoralis major'],
    [0.4, 0.7, 'Abdominals'],
    [0.2, 0.7, 'Trapezius'],
    [0.6, 0.62, 'Quadriceps'],
    [0.8, 0.58, 'Calves'],
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

  double opacity_change(double op) {
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

class MuscleSelectionWidget extends StatefulWidget {
  const MuscleSelectionWidget({super.key});

  @override
  State<MuscleSelectionWidget> createState() => _MuscleSelectionWidgetState();
}

class _MuscleSelectionWidgetState extends State<MuscleSelectionWidget> {
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
    [0.35, 0.4, 'Biceps'],
    [0.46, 0.4, 'Forearms'],
    [0.25, 0.4, 'Front Delts'],
    [0.28, 0.7, 'Pectoralis major'],
    [0.4, 0.7, 'Abdominals'],
    [0.2, 0.7, 'Trapezius'],
    [0.6, 0.62, 'Quadriceps'],
    [0.8, 0.58, 'Calves'],
  ];

  final List<List> backButtons = [
    [0.82, 0.6, 'Calves'],
    [0.2, 0.45, 'Deltoids'],
    [0.26, 0.38, 'Back Delts'],
    [0.5, 0.4, 'Forearms'],
    [0.55, 0.7, 'Gluteus maximus'],
    [0.68, 0.6, 'Hamstrings'],
    [0.4, 0.7, 'Latissimus dorsi'],
    [0.2, 0.7, 'Trapezius'],
    [0.35, 0.4, 'Triceps'],
  ];

  double opacity_change(double op) {
    if (op >= 1.0) {
      op = 0.0;
    } else {
      op += 1 / 4;
    }
    return op;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Muscle Groups',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            return Stack(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: constraints.maxWidth / 2,
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Transform.scale(
                        scaleX: -1,
                        child: Stack(children: [
                          Image(
                            width: constraints.maxWidth / 3,
                            fit: BoxFit.fill,
                            image:
                                const AssetImage('images/muscles/Front_bg.png'),
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
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Stack(children: [
                        Image(
                            fit: BoxFit.fill,
                            width: constraints.maxWidth / 3,
                            image:
                                const AssetImage('images/muscles/Back_bg.png')),
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
                                                opacity_change(
                                                    globals.muscle_val[i[2]]!);
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
            ]);
          }),
        ],
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

String _getDeviceName(ExerciseDevice device) {
  switch (device) {
    case ExerciseDevice.free:
      return 'Free Weights';
    case ExerciseDevice.machine:
      return 'Machine';
    case ExerciseDevice.cable:
      return 'Cable';
    case ExerciseDevice.body:
      return 'Bodyweight';
  }
}

String _getActiveMuscleGroups() {
  final activeMuscles = <String>[];
  for (var entry in globals.muscle_val.entries) {
    if (entry.value > 0) {
      activeMuscles.add('${entry.key} (${(entry.value * 100).round()}%)');
    }
  }
  return activeMuscles.isEmpty ? 'None selected' : activeMuscles.join(', ');
}
