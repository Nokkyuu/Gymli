// ignore: file_names
// ignore_for_file: file_names, duplicate_ignore, constant_identifier_names, non_constant_identifier_names

//import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:Gymli/exerciseScreen.dart';
import 'package:Gymli/DataModels.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Gymli/workoutSetupScreen.dart';
import 'database.dart' as db;


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
  State<LandingScreen> createState() {
    return _LandingScreenState();
  }
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController WorkoutController = TextEditingController();
  final TextEditingController MuscleController = TextEditingController();

  Workout? selectedWorkout;
  MuscleList? selectedMuscle;
  var box = Hive.box<Exercise>('Exercises');
  List<Exercise> allExercises = Hive.box<Exercise>('Exercises').values.toList();

  var availableWorkouts = Hive.box<Workout>('Workouts').values.toList();

  //List<Exercise> filteredExercises = Hive.box<Exercise>('Exercises').values.toList();
  ValueNotifier<bool> filterApplied = ValueNotifier<bool>(true);
  List<Exercise> filteredExercises = Hive.box<Exercise>('Exercises').values.toList();
  List<String> metainfo = [];

  void updateAllExercises() {
      allExercises = Hive.box<Exercise>('Exercises').values.toList();
      allExercises.sort((a, b) => a.name.compareTo(b.name));
      filterApplied.value = !filterApplied.value;
  }

  void workoutFilterList(Workout workout) {
    var filterMask = [];
    for (var e in workout.units) {
      filterMask.add(e.exercise);
    }
    filteredExercises = [];
    metainfo = [];
    filteredExercises.sort((a, b) => a.name.compareTo(b.name));
    for (var ex in allExercises) {
      if (filterMask.contains(ex.name)) {
        filteredExercises.add(ex);
      }
    }
    for (var e in workout.units) {
      metainfo.add('Warm: ${e.warmups}, Work: ${e.worksets}, Drop: ${e.dropsets}');
    }
    filterApplied.value = !filterApplied.value;
  }

  void showAllExercises() {
    filteredExercises = allExercises;
    filteredExercises.sort((a, b) => a.name.compareTo(b.name));
    metainfo = [];
    for (var ex in filteredExercises) {
      var lastTraining = db.getLastTrainingDay(ex.name);
      var dayDiff = DateTime.now().difference(lastTraining).inDays;
      String dayInfo =  dayDiff > 0 ? "$dayDiff days ago" : "today";
      metainfo.add('${ex.defaultRepBase}-${ex.defaultRepMax} Reps @ ${ex.defaultIncrement}kg - $dayInfo');
    }
    filterApplied.value = !filterApplied.value;
  }

  void muscleFilterList(MuscleList muscleName) {
    var muscle = muscleName.muscleName;
    filteredExercises = [];
    metainfo = [];
    for (var ex in allExercises) {
      if (ex.muscleGroups.contains(muscle)) {
        filteredExercises.add(ex);
      }
    }
    for (var ex in filteredExercises) {
      metainfo.add('Reps: ${ex.defaultRepBase} to ${ex.defaultRepMax} Weight Incr.: ${ex.defaultIncrement}');
    }
    filterApplied.value = !filterApplied.value;
  }

  Future<void> _reload(var value) async {
    setState(() {
      availableWorkouts = Hive.box<Workout>('Workouts').values.toList();
    });
  }
  @override
  void initState() {
    super.initState();
    updateAllExercises();
    setState(() {
      MuscleController.value = TextEditingValue.empty;
      WorkoutController.value = TextEditingValue.empty;
      showAllExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(),
              DropdownMenu<Workout>(
                width: MediaQuery.of(context).size.width * 0.45,
                enabled: true,
                key: UniqueKey(),
                //initialSelection: WorkoutList.Push,
                controller: WorkoutController,
                requestFocusOnTap: false,
                label: const Text('Workouts'),
                onSelected: (Workout? workout) {
                  workoutFilterList(workout!);
                  setState(() {
                    MuscleController.value = TextEditingValue.empty;
                    selectedWorkout = workout;
                  });
                },
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: BoxConstraints.tight(const Size.fromHeight(40)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownMenuEntries: availableWorkouts
                    .map<DropdownMenuEntry<Workout>>((Workout workout) {
                  return DropdownMenuEntry<Workout>(
                    value: workout,
                    label: workout.name,
                    trailingIcon: IconButton(
                        onPressed: () => {
                          Navigator.push( context, MaterialPageRoute(builder: (context) => WorkoutSetupScreen(workout.name))).then((value) => _reload(value))
                        },
                        icon: const Icon(Icons.edit)),
                  );
                }).toList(),
              ),
              const Spacer(),
              DropdownMenu<MuscleList>(
                width: MediaQuery.of(context).size.width * 0.45,
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
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: BoxConstraints.tight(const Size.fromHeight(40)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownMenuEntries: MuscleList.values
                    .map<DropdownMenuEntry<MuscleList>>((MuscleList name) {
                  return DropdownMenuEntry<MuscleList>(
                    value: name,
                    label: name.muscleName,
                  );
                }).toList(),
              ),
              const Spacer(),
            ],
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder(
                valueListenable: filterApplied,
                builder: (context, bool filterApplied, _) {
                  var items = filteredExercises;
                  if (items.isNotEmpty) {
                    return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final currentData = items[index];
                          final meta = metainfo[index];
                          String description = "";
                          if (meta.split(":")[0] == "Warm") {
                            description = meta;
                          }
                          final exerciseType = currentData.type;
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
                              dense: true,
                              title: Text(currentData.name),

                              subtitle: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [Text(meta)]),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ExerciseScreen(currentData.name, description))).then((value) => _reload(value));
                              });
                        });
                  } else {
                    //Hive.box<Exercise>('Exercises').watch();
                    return const Text("No exercises yet");
                  }
                }),
          )
        ]);
  }
}
