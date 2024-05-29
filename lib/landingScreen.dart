// ignore: file_names
// ignore_for_file: file_names, duplicate_ignore, constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yafa_app/exerciseScreen.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum WorkoutList {
  abcd('abcd', [
    "ab",
    "cd"
  ], [
    [1, 2, 1],
    [0, 3, 3]
  ]),
  ab('ab', [
    "ab"
  ], [
    [2, 2, 2]
  ]),
  cd('cd', [
    "cd"
  ], [
    [0, 3, 0]
  ]);

  const WorkoutList(this.workoutName, this.workoutEx, this.setChoice);
  final String workoutName;
  final List<String> workoutEx;
  final List<List<int>> setChoice;
}

enum MuscleList {
  Pectoralis_major("Pectoralis major"),
  Trapezius("Trapezius"),
  Biceps("Biceps"),
  Abdominals("Abdominals"),
  Delts("Deltoids"),
  Latissimus_dorsi("Latissimus dorsi"),
  Triceps("Triceps"),
  Gluteus_maximus("Gluteus maximus"),
  Hamstrings("Hamstrings"),
  Quadriceps("Quadriceps"),
  Forearms("Forearms"),
  Calves("Calves");

  const MuscleList(this.muscleName);
  final String muscleName;
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController WorkoutController = TextEditingController();
  final TextEditingController MuscleController = TextEditingController();

  WorkoutList? selectedWorkout;
  MuscleList? selectedMuscle;
  var box = Hive.box<Exercise>('Exercises');
  List<Exercise> allExercises = Hive.box<Exercise>('Exercises').values.toList();
  //List<Exercise> filteredExercises = Hive.box<Exercise>('Exercises').values.toList();
  ValueNotifier<bool> filterApplied = ValueNotifier<bool>(true);
  List<Exercise> filteredExercises =
      Hive.box<Exercise>('Exercises').values.toList();
  List<String> metainfo = [];

  void updateAllExercises() async {
    allExercises = Hive.box<Exercise>('Exercises').values.toList();
    filterApplied.value = !filterApplied.value;
  }

  void workoutFilterList(WorkoutList Workoutname) {
    var filterMask = Workoutname.workoutEx;
    filteredExercises = [];
    metainfo = [];
    for (var ex in allExercises) {
      if (filterMask.contains(ex.name)) {
        filteredExercises.add(ex);
      }
    }
    for (var sets in Workoutname.setChoice) {
      metainfo.add('Warm: ${sets[0]}, Work: ${sets[1]}, Drop: ${sets[2]}');
    }
    //print(Workoutname);
    filterApplied.value = !filterApplied.value;
  }

  void showAllExercises() {
    filteredExercises = allExercises;
    metainfo = [];
    for (var ex in filteredExercises) {
      metainfo.add(
          'Reps: ${ex.defaultRepBase} to ${ex.defaultRepBase + ex.defaultRepMax} Weight Incr.: ${ex.defaultIncrement}');
    }
    filterApplied.value = !filterApplied.value;
  }

  void muscleFilterList(MuscleList muscleName) {
    var muscle = muscleName.muscleName;
    filteredExercises = [];
    metainfo = [];
    //print(muscle);
    for (var ex in allExercises) {
      //print(ex.muscleGroups);
      if (ex.muscleGroups.contains(muscle)) {
        filteredExercises.add(ex);
      }
    }
    for (var ex in filteredExercises) {
      metainfo.add(
          'Reps: ${ex.defaultRepBase} to ${ex.defaultRepBase + ex.defaultRepMax} Weight Incr.: ${ex.defaultIncrement}');
    }

    filterApplied.value = !filterApplied.value;
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      MuscleController.value = TextEditingValue.empty;
      WorkoutController.value = TextEditingValue.empty;
      showAllExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    updateAllExercises();
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Filter by or "),
              TextButton.icon(
                onPressed: () => setState(() {
                  showAllExercises();
                  WorkoutController.value = TextEditingValue.empty;
                  MuscleController.value = TextEditingValue.empty;
                }),
                label: const Text("Show All"),
                icon: const Icon(Icons.search),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownMenu<WorkoutList>(
                width: MediaQuery.of(context).size.width * 0.5,
                enabled: true,
                //initialSelection: WorkoutList.Push,
                controller: WorkoutController,
                requestFocusOnTap: false,
                label: const Text('Workouts'),
                onSelected: (WorkoutList? name) {
                  workoutFilterList(name!);
                  setState(() {
                    MuscleController.value = TextEditingValue.empty;
                    selectedWorkout = name;
                  });
                },
                dropdownMenuEntries: WorkoutList.values
                    .map<DropdownMenuEntry<WorkoutList>>((WorkoutList name) {
                  return DropdownMenuEntry<WorkoutList>(
                    value: name,
                    label: name.workoutName,
                    trailingIcon: IconButton(
                        onPressed: () => print(
                            "edit workout"), //TODO: go to workout setup to edit the selected workout
                        icon: const Icon(Icons.edit)),
                  );
                }).toList(),
              ),
              DropdownMenu<MuscleList>(
                width: MediaQuery.of(context).size.width * 0.5,
                enabled: true,
                //initialSelection: MuscleList.Pectoralis_major,
                controller: MuscleController,
                requestFocusOnTap: false,

                label: const Text('Muscles'),
                onSelected: (MuscleList? name) {
                  muscleFilterList(name!);
                  setState(() {
                    WorkoutController.value = TextEditingValue.empty;
                    selectedMuscle = name;
                  });
                },
                dropdownMenuEntries: MuscleList.values
                    .map<DropdownMenuEntry<MuscleList>>((MuscleList name) {
                  return DropdownMenuEntry<MuscleList>(
                    value: name,
                    label: name.muscleName,
                  );
                }).toList(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder(
                valueListenable: filterApplied,
                builder: (context, bool filterApplied, _) {
                  //var box = Hive.box<Exercise>('Exercises');
                  var items = filteredExercises;
                  if (items.isNotEmpty) {
                    return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final currentData = items[index];
                          final meta = metainfo[index];
                          final exerciseType = currentData.type;
                          //final repBase = currentData.defaultRepBase;
                          //final repMax = currentData.defaultRepMax;
                          //final increment = currentData.defaultIncrement;
                          final itemList = [
                            FontAwesomeIcons.dumbbell,
                            Icons.forklift,
                            Icons.cable,
                            Icons.sports_martial_arts
                          ];
                          final currentIcon = itemList[exerciseType];
                          return ListTile(
                              leading: CircleAvatar(
                                radius: 17.5,
                                child: FaIcon(currentIcon),
                              ),
                              trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) => Dialog(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  const Text(
                                                      'Confirm Deletion:'),
                                                  const SizedBox(height: 15),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      box.delete(item.key);
                                                      Box setbox =
                                                          Hive.box<TrainingSet>(
                                                              'TrainingSets');
                                                      var items = setbox.values
                                                          .toList();
                                                      items = setbox.values
                                                          .where((item) =>
                                                              item.exercise ==
                                                              currentData.name)
                                                          .toList();
                                                      for (var item in items) {
                                                        setbox.delete(item.key);
                                                        updateAllExercises();
                                                      }
                                                    },
                                                    child:
                                                        const Text('Confirm'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ))),
                              title: Text(currentData.name),
                              subtitle: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [Text(meta)]),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ExerciseScreen(currentData.name)));
                              });
                        });
                  } else {
                    Hive.box<Exercise>('Exercises').watch();
                    return const Text("No exercises yet");
                  }
                }),
          )
        ]);
  }
}
