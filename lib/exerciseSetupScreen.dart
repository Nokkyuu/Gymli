// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:hive/hive.dart';
import 'globals.dart' as globals;

enum ExerciseDevice { free, machine, cable, body }
final exerciseMap = [ExerciseDevice.free, ExerciseDevice.machine, ExerciseDevice.cable, ExerciseDevice.body];

class ExerciseSetupScreen extends StatefulWidget {
  String exerciseName;
  ExerciseSetupScreen(this.exerciseName, {super.key});

  @override
  State<ExerciseSetupScreen> createState() => _ExerciseSetupScreenState();
}

void get_exercise_list() async {
  final box = await Hive.openBox<Exercise>('Exercises');
  var boxmap = box.values.toList();
  List<String> exerciseList = [];
  for (var e in boxmap) {
    exerciseList.add(e.name);
  }
  globals.exerciseList = exerciseList;
}

void add_exercise(String exerciseName, ExerciseDevice chosenDevice, int minRep,
    int repRange, double weightInc, List<String> muscleGroups, List<double> muscleIntensities) async {
  final box = await Hive.openBox<Exercise>('Exercises');
  int exerciseType = chosenDevice.index;
  var boxmap = box.values.toList();
  List<String> exerciseList = [];
  for (var e in boxmap) {
    exerciseList.add(e.name);
  }
  // boxmap.values.forEach((v) => print("Value: $v"));

  // var a = boxmap.getAllKeys();
  // log(a);

  if (!exerciseList.contains(exerciseName)) {
    box.add(Exercise(
        name: exerciseName,
        type: exerciseType,
        muscleGroups: muscleGroups,
        defaultRepBase: minRep,
        defaultRepMax: repRange,
        defaultIncrement: weightInc,
        muscleIntensities: muscleIntensities));
  } else {
    box.putAt(
        exerciseList.indexOf(exerciseName),
        Exercise(
            name: exerciseName,
            type: exerciseType,
            muscleGroups: muscleGroups,
            defaultRepBase: minRep,
            defaultRepMax: repRange,
            defaultIncrement: weightInc,
            muscleIntensities: muscleIntensities));
  }
}

class _ExerciseSetupScreenState extends State<ExerciseSetupScreen> {
  ExerciseDevice chosenDevice = ExerciseDevice.free;
  double boxSpace = 10;
  double minRep = 10;
  double repRange = 15;
  double weightInc = 2.5;
  List<String> muscleGroups = [];
  List<double> muscleIntensities = [];
  final exerciseTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    var box = Hive.box<Exercise>('Exercises');
    var exerciseFilter = box.values.toList().where((item) => item.name == widget.exerciseName);
    if (exerciseFilter.isEmpty) { return; }
    var exercise = exerciseFilter.first;
    exerciseTitleController.text = exercise.name;
    this.setState(() {
      chosenDevice = exerciseMap[exercise.type];
      minRep = exercise.defaultRepBase.toDouble();
      repRange = exercise.defaultRepMax.toDouble();
      weightInc = exercise.defaultIncrement;
      muscleGroups = exercise.muscleGroups;
      muscleIntensities = exercise.muscleIntensities;
      // muscleIntensities = exercise.muscleIntensities;
      for (var i = 0; i < muscleGroups.length; i++) {
        globals.muscle_val[muscleGroups[i]] = muscleIntensities[i];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios,
            ),
          ),
          title: const Text("Exercise Setup"),
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
              const HeadCard(headline: "Exercise Utility"),
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
              const HeadCard(headline: "Minimum Repetitions To Achieve"),
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
              const HeadCard(headline: "Reps To Add Till Weight Increase"),
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
              const HeadCard(headline: "Weight Increase Increments"),
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
              IconButton(
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
                              return Text('Save Exercise:\n', style: Theme.of(context).textTheme.titleLarge,);
                            }
                            return Text(
                              'Attention! \nOverwriting Exercise:\n',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                            );
                          }(),
                          Card(elevation: 5.0,child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${exerciseTitleController.text}\n',style: Theme.of(context).textTheme.titleMedium),
                                Text(chosenDevice.name),
                            Text('${minRep.toInt()} to ${minRep.toInt() + repRange.toInt()} reps'),
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
                                  add_exercise(
                                      exerciseTitleController.text,
                                      chosenDevice,
                                      minRep.toInt(),
                                      repRange.toInt(),
                                      weightInc,
                                      muscleGroups,muscleIntensities);
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: const Text('Confirm'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
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
                //     repRange.toInt(),
                //     weightInc,
                //     muscleGroups);
                // setState(() {});
                // Navigator.pop(context);
                ,
              ),
            ],
          ),
        ));
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
  opacity_change(double op) {
    if (op >= 1.0) {
      op = 0.0;
    } else {
      op += 0.5;
    }
    return op;
  }

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
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Transform.scale(
                      scaleX: -1,
                      child: Stack(children: [
                        const Image(
                          fit: BoxFit.scaleDown,
                          image: AssetImage('images/muscles/Front_bg.png'),
                        ),
                        Image(
                          fit: BoxFit.scaleDown,
                          image: const AssetImage(
                              'images/muscles/Front_biceps.png'),
                          opacity: AlwaysStoppedAnimation(
                              globals.muscle_val["Biceps"]!),
                        ),
                        Image(
                          fit: BoxFit.scaleDown,
                          image: const AssetImage(
                              'images/muscles/Front_calves.png'),
                          opacity: AlwaysStoppedAnimation(
                              globals.muscle_val["Calves"]!),
                        ),
                        Image(
                          fit: BoxFit.scaleDown,
                          image: const AssetImage(
                              'images/muscles/Front_delts.png'),
                          opacity: AlwaysStoppedAnimation(
                              globals.muscle_val["Deltoids"]!),
                        ),
                        Image(
                          fit: BoxFit.scaleDown,
                          image: const AssetImage(
                              'images/muscles/Front_forearms.png'),
                          opacity: AlwaysStoppedAnimation(
                              globals.muscle_val[ "Forearms"]!),
                        ),
                        Image(
                          fit: BoxFit.scaleDown,
                          image:
                              const AssetImage('images/muscles/Front_pecs.png'),
                          opacity: AlwaysStoppedAnimation(
                              globals.muscle_val["Pectoralis major"]!),
                        ),
                        Image(
                          fit: BoxFit.scaleDown,
                          image: const AssetImage(
                              'images/muscles/Front_quads.png'),
                          opacity: AlwaysStoppedAnimation(
                              globals.muscle_val["Quadriceps"]!),
                        ),
                        Image(
                          fit: BoxFit.scaleDown,
                          image: const AssetImage(
                              'images/muscles/Front_sideabs.png'),
                          opacity: AlwaysStoppedAnimation(
                              globals.muscle_val["Abdominals"]!),
                        ),
                        Image(
                          fit: BoxFit.scaleDown,
                          image: const AssetImage(
                              'images/muscles/Front_trapz.png'),
                          opacity: AlwaysStoppedAnimation(
                              globals.muscle_val["Trapezius"]!),
                        ),
                        Image(
                          fit: BoxFit.scaleDown,
                          image:
                              const AssetImage('images/muscles/Front_abs.png'),
                          opacity: AlwaysStoppedAnimation(
                              globals.muscle_val["Abdominals"]!),
                        ),
                        FractionallySizedBox(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.35,
                            widthFactor: 0.4,
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                TextButton(
                                    onPressed: () => setState(() {
                                          globals.muscle_val["Biceps"] =
                                              opacity_change(globals
                                                  .muscle_val["Biceps"]!);
                                        }),
                                    child: Transform.scale(
                                        scaleX: -1,
                                        child: const Text("Biceps")))
                              ],
                            )),
                        FractionallySizedBox(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.46,
                            widthFactor: 0.4,
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                TextButton(
                                    onPressed: () => setState(() {
                                          globals.muscle_val[ "Forearms"] =
                                              opacity_change(
                                                  globals.muscle_val[ "Forearms"]!);
                                        }),
                                    child: Transform.scale(
                                        scaleX: -1,
                                        child: const Text("forearm")))
                              ],
                            )),
                        FractionallySizedBox(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.25,
                            widthFactor: 0.4,
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                TextButton(
                                    onPressed: () => setState(() {
                                          globals.muscle_val["Deltoids"] =
                                              opacity_change(
                                                  globals.muscle_val["Deltoids"]!);
                                        }),
                                    child: Transform.scale(
                                        scaleX: -1, child: const Text("  ")))
                              ],
                            )),
                        FractionallySizedBox(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.28,
                            widthFactor: 0.7,
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                TextButton(
                                    onPressed: () => setState(() {
                                          globals.muscle_val["Pectoralis major"] =
                                              opacity_change(
                                                  globals.muscle_val["Pectoralis major"]!);
                                        }),
                                    child: Transform.scale(
                                        scaleX: -1, child: const Text("Pectoralis major")))
                              ],
                            )),
                        FractionallySizedBox(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.4,
                            widthFactor: 0.7,
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                TextButton(
                                    onPressed: () => setState(() {
                                          globals.muscle_val["Abdominals"] =
                                              opacity_change(
                                                  globals.muscle_val["Abdominals"]!);
                                        }),
                                    child: Transform.scale(
                                        scaleX: -1, child: const Text("Abdominals")))
                              ],
                            )),
                        FractionallySizedBox(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.2,
                            widthFactor: 0.7,
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                TextButton(
                                    onPressed: () => setState(() {
                                          globals.muscle_val["Trapezius"] =
                                              opacity_change(
                                                  globals.muscle_val["Trapezius"]!);
                                        }),
                                    child: Transform.scale(
                                        scaleX: -1, child: const Text("  ")))
                              ],
                            )),
                        FractionallySizedBox(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.6,
                            widthFactor: 0.62,
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                TextButton(
                                    onPressed: () => setState(() {
                                          globals.muscle_val["Quadriceps"] =
                                              opacity_change(
                                                  globals.muscle_val["Quadriceps"]!);
                                        }),
                                    child: Transform.scale(
                                        scaleX: -1, child: const Text("Quadriceps")))
                              ],
                            )),
                        FractionallySizedBox(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.8,
                            widthFactor: 0.58,
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                TextButton(
                                    onPressed: () => setState(() {
                                          globals.muscle_val["Calves"] =
                                              opacity_change(globals
                                                  .muscle_val["Calves"]!);
                                        }),
                                    child: Transform.scale(
                                        scaleX: -1, child: const Text("   ")))
                              ],
                            )),
                      ])),
                ),
                SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Stack(children: [
                      const Image(
                          fit: BoxFit.scaleDown,
                          image: AssetImage('images/muscles/Back_bg.png')),
                      Image(
                        fit: BoxFit.scaleDown,
                        image:
                            const AssetImage('images/muscles/Back_calves.png'),
                        opacity: AlwaysStoppedAnimation(
                            globals.muscle_val["Calves"]!),
                      ),
                      Image(
                        fit: BoxFit.scaleDown,
                        image: const AssetImage(
                            'images/muscles/Back_forearms.png'),
                        opacity:
                            AlwaysStoppedAnimation(globals.muscle_val[ "Forearms"]!),
                      ),
                      Image(
                        fit: BoxFit.scaleDown,
                        image:
                            const AssetImage('images/muscles/Back_delts.png'),
                        opacity: AlwaysStoppedAnimation(
                            globals.muscle_val["Deltoids"]!),
                      ),
                      Image(
                        fit: BoxFit.scaleDown,
                        image:
                            const AssetImage('images/muscles/Back_glutes.png'),
                        opacity: AlwaysStoppedAnimation(
                            globals.muscle_val["Gluteus maximus"]!),
                      ),
                      Image(
                        fit: BoxFit.scaleDown,
                        image: const AssetImage(
                            'images/muscles/Back_hamstrings.png'),
                        opacity:
                            AlwaysStoppedAnimation(globals.muscle_val["Hamstrings"]!),
                      ),
                      Image(
                        fit: BoxFit.scaleDown,
                        image: const AssetImage('images/muscles/Back_lats.png'),
                        opacity:
                            AlwaysStoppedAnimation(globals.muscle_val["Latissimus dorsi"]!),
                      ),
                      Image(
                        fit: BoxFit.scaleDown,
                        image:
                            const AssetImage('images/muscles/Back_trapz.png'),
                        opacity: AlwaysStoppedAnimation(
                            globals.muscle_val["Trapezius"]!),
                      ),
                      Image(
                        fit: BoxFit.scaleDown,
                        image:
                            const AssetImage('images/muscles/Back_triceps.png'),
                        opacity: AlwaysStoppedAnimation(
                            globals.muscle_val["Triceps"]!),
                      ),
                      FractionallySizedBox(
                          alignment: Alignment.bottomRight,
                          heightFactor: 0.35,
                          widthFactor: 0.4,
                          child: Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              TextButton(
                                  onPressed: () => setState(() {
                                        globals.muscle_val["Triceps"] =
                                            opacity_change(
                                                globals.muscle_val["Triceps"]!);
                                      }),
                                  child: const Text("Triceps"))
                            ],
                          )),
                      FractionallySizedBox(
                          alignment: Alignment.bottomRight,
                          heightFactor: 0.5,
                          widthFactor: 0.4,
                          child: Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              TextButton(
                                  onPressed: () => setState(() {
                                        globals.muscle_val[ "Forearms"] =
                                            opacity_change(
                                                globals.muscle_val[ "Forearms"]!);
                                      }),
                                  child: const Text("  "))
                            ],
                          )),
                      FractionallySizedBox(
                          alignment: Alignment.bottomRight,
                          heightFactor: 0.25,
                          widthFactor: 0.4,
                          child: Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              TextButton(
                                  onPressed: () => setState(() {
                                        globals.muscle_val["Deltoids"] =
                                            opacity_change(
                                                globals.muscle_val["Deltoids"]!);
                                      }),
                                  child: const Text("Deltoids"))
                            ],
                          )),
                      FractionallySizedBox(
                          alignment: Alignment.bottomRight,
                          heightFactor: 0.2,
                          widthFactor: 0.7,
                          child: Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              TextButton(
                                  onPressed: () => setState(() {
                                        globals.muscle_val["Trapezius"] =
                                            opacity_change(
                                                globals.muscle_val["Trapezius"]!);
                                      }),
                                  child: const Text("Trapezius"))
                            ],
                          )),
                      FractionallySizedBox(
                          alignment: Alignment.bottomRight,
                          heightFactor: 0.4,
                          widthFactor: 0.7,
                          child: Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              TextButton(
                                  onPressed: () => setState(() {
                                        globals.muscle_val["Latissimus dorsi"] =
                                            opacity_change(
                                                globals.muscle_val["Latissimus dorsi"]!);
                                      }),
                                  child: const Text("Latissimus dorsi"))
                            ],
                          )),
                      FractionallySizedBox(
                          alignment: Alignment.bottomRight,
                          heightFactor: 0.55,
                          widthFactor: 0.7,
                          child: Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              TextButton(
                                  onPressed: () => setState(() {
                                        globals.muscle_val["Gluteus maximus"] =
                                            opacity_change(
                                                globals.muscle_val["Gluteus maximus"]!);
                                      }),
                                  child: const Text("Gluteus maximus"))
                            ],
                          )),
                      FractionallySizedBox(
                          alignment: Alignment.bottomRight,
                          heightFactor: 0.68,
                          widthFactor: 0.6,
                          child: Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              TextButton(
                                  onPressed: () => setState(() {
                                        globals.muscle_val["Hamstrings"] =
                                            opacity_change(
                                                globals.muscle_val["Hamstrings"]!);
                                      }),
                                  child: const Text("Hamstrings"))
                            ],
                          )),
                      FractionallySizedBox(
                          alignment: Alignment.bottomRight,
                          heightFactor: 0.82,
                          widthFactor: 0.6,
                          child: Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              TextButton(
                                  onPressed: () => setState(() {
                                        globals.muscle_val["Calves"] =
                                            opacity_change(
                                                globals.muscle_val["Calves"]!);
                                      }),
                                  child: const Text("Calves"))
                            ],
                          )),
                    ]))
              ],
            ),
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

// class ObscuredTextFieldSample extends StatelessWidget {
//   const ObscuredTextFieldSample({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox(
//       width: 250,
//       child: TextField(
//         obscureText: true,
//         decoration: InputDecoration(
//           border: OutlineInputBorder(),
//           labelText: 'GiveMeName',
//         ),
//       ),
//     );
//   }
// }
