// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tuple/tuple.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:hive/hive.dart';
import 'package:yafa_app/landingScreen.dart';
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
    int repRange, double weightInc) async {
  final box = await Hive.openBox<Exercise>('Exercises');
  int exerciseType = chosenDevice.index;
  var boxmap = box.values.toList();
  List<String> exerciseList = [];
  for (var e in boxmap) {
    exerciseList.add(e.name);
  }
  List<String> muscleGroups = [];
  List<double> muscleIntensities = [];
  for (var m in muscleGroupNames) {
    if (globals.muscle_val[m]! > 0.0) {
      muscleGroups.add(m);
      muscleIntensities.add(globals.muscle_val[m]!);
    }
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
  Exercise? currentExercise;

  @override
  void initState() {
    super.initState();
    var box = Hive.box<Exercise>('Exercises');
    var exerciseFilter = box.values.toList().where((item) => item.name == widget.exerciseName);
    if (exerciseFilter.isEmpty) { return; }
    currentExercise = exerciseFilter.first;
    exerciseTitleController.text = currentExercise!.name;
    this.setState(() {
      chosenDevice = exerciseMap[currentExercise!.type];
      minRep = currentExercise!.defaultRepBase.toDouble();
      repRange = currentExercise!.defaultRepMax.toDouble();
      weightInc = currentExercise!.defaultIncrement;
      for (var m in muscleGroupNames) {
        globals.muscle_val[m] = 0.0;
      }
      muscleGroups = currentExercise!.muscleGroups;
      muscleIntensities = currentExercise!.muscleIntensities;
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
            onTap: () { Navigator.pop(context); },
            child: const Icon( Icons.arrow_back_ios ),
          ),
          title: const Text("Exercise Setup"),
          actions:[
              IconButton(
                onPressed: () {
                  var box = Hive.box<Exercise>("Exercises");
                  box.delete(currentExercise!.key);
                  Box setbox = Hive.box<TrainingSet>('TrainingSets');
                  var items = setbox.values.toList();
                  items = setbox.values.where((item) => item.exercise == currentExercise!.name).toList();
                  for (var item in items) {
                    setbox.delete(item.key);
                    
                  }
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
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
                                      weightInc);
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
  final List<List<String>> frontImages = 
  [['images/muscles/Front_biceps.png', 'Biceps'],
  ['images/muscles/Front_calves.png', 'Calves' ], 
  ['images/muscles/Front_delts.png', 'Deltoids'], 
  ['images/muscles/Front_forearms.png', 'Forearms'], 
  ['images/muscles/Front_pecs.png', 'Pectoralis major'], 
  ['images/muscles/Front_quads.png', 'Quadriceps'], 
  ['images/muscles/Front_sideabs.png', 'Abdominals'],
  ['images/muscles/Front_abs.png', 'Abdominals'],
  ['images/muscles/Front_trapz.png', 'Trapezius'], 
  ['images/muscles/Front_abs.png', 'Trapezius']];
  final List<List<String>> backImages = 
  [['images/muscles/Back_calves.png', 'Calves'],
  ['images/muscles/Back_delts.png', 'Deltoids' ], 
  ['images/muscles/Back_forearms.png', 'Forearms'], 
  ['images/muscles/Back_glutes.png', 'Gluteus maximus'], 
  ['images/muscles/Back_hamstrings.png', 'Hamstrings'], 
  ['images/muscles/Back_lats.png', 'Latissimus dorsi'], 
  ['images/muscles/Back_trapz.png', 'Trapezius'],
  ['images/muscles/Back_triceps.png', 'Triceps'],
];
  final List<List> frontButtons = [
    [0.35,0.4,'Biceps'],
    [0.46,0.4,'Forearms'],
    [0.25,0.4,'Deltoids'],
    [0.28,0.7,'Pectoralis major'],
    [0.4,0.7,'Abdominals'],
    [0.2,0.7,'Trapezius'],
    [0.6,0.62,'Quadriceps'],
    [0.8,0.58, 'Calves'],
  ];
    final List<List> backButtons = [
    [0.82,0.6,'Calves'],
    [0.25,0.4,'Deltoids'],
    [0.5,0.4,'Forearms'],
    [0.55,0.7,'Gluteus maximus'],
    [0.68,0.6,'Hamstrings'],
    [0.4,0.7,'Latissimus dorsi'],
    [0.2,0.7,'Trapezius'],
    [0.35,0.4, 'Triceps'],
  ];

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
                        
                        for (var i in frontImages)
                        Image(
                          fit: BoxFit.scaleDown,
                          image: AssetImage(
                              i[0]),
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
                                        child:Text(i[2])))
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
                          for (var i in backImages)
                      Image(
                        fit: BoxFit.scaleDown,
                        image:
                            AssetImage(i[0]),
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
                                  child: Text(i[2]))
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
