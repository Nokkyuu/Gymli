// ignore_for_file: file_names, constant_identifier_names
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:Gymli/api_models.dart';
import 'package:Gymli/user_service.dart';

// enum ExerciseList {
//   Benchpress('Benchpress', 2, 3, 1),
//   Squat('Squat', 2, 2, 1),
//   Deadlift('Deadlift', 2, 3, 2),
//   Benchpress2('Benchpress2', 2, 3, 1),
//   Squat2('Squat2', 2, 2, 1),
//   Deadlift2('Deadlift2', 2, 3, 2);

//   const ExerciseList(this.exerciseName, this.warmUpS,this.workS, this.dropS);
//   final String exerciseName;
//   final int warmUpS;
//   final int workS;
//   final int dropS;
// }

class WorkoutSetupScreen extends StatefulWidget {
  final String workoutName;
  const WorkoutSetupScreen(this.workoutName, {super.key});

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  final TextEditingController exerciseController = TextEditingController();
  ApiExercise? selectedExercise;
  ValueNotifier<bool> addRemEx = ValueNotifier<bool>(true);
  int warmUpS = 0;
  int workS = 1;
  int dropS = 0;
  ApiWorkout? currentWorkout;
  TextEditingController workoutNameController = TextEditingController();
  List<ApiExercise> allExercises = [];
  List<ApiWorkoutUnit> addedExercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load all exercises
      final userService = UserService();
      final exerciseData = await userService.getExercises();
      allExercises =
          exerciseData.map((item) => ApiExercise.fromJson(item)).toList();

      if (widget.workoutName.isNotEmpty) {
        workoutNameController.text = widget.workoutName;
        final workoutData = await userService.getWorkouts();
        final workouts =
            workoutData.map((item) => ApiWorkout.fromJson(item)).toList();

        currentWorkout = workouts.firstWhere(
          (workout) => workout.name == widget.workoutName,
          orElse: () => ApiWorkout(
              id: 0,
              userName: "DefaultUser",
              name: widget.workoutName,
              units: []),
        );
        if (currentWorkout != null) {
          addedExercises = List.from(currentWorkout!.units);
        }
      } else {
        workoutNameController.text = "";
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addWorkout(String name, List<ApiWorkoutUnit> units) async {
    try {
      final userService = UserService();
      if (currentWorkout != null &&
          currentWorkout!.id != null &&
          currentWorkout!.id! > 0) {
        // Update existing workout
        await userService.updateWorkout(
          currentWorkout!.id!,
          {
            'name': name,
            'units': units.map((unit) => unit.toJson()).toList(),
          },
        );
      } else {
        // Create new workout
        await userService.createWorkout(
          name: name,
          units: units.map((unit) => unit.toJson()).toList(),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      print('Error saving workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving workout: $e')),
      );
    }
  }

  final itemList = [
    FontAwesomeIcons.dumbbell,
    Icons.forklift,
    Icons.cable,
    Icons.sports_martial_arts
  ];

  remExercise(ApiWorkoutUnit exerciseRem) {
    addedExercises.remove(exerciseRem);
    addRemEx.value = !addRemEx.value;
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Workout Editor';

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          title: const Text(title),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          title: const Text(title),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () async {
                  if (currentWorkout != null &&
                      currentWorkout!.id != null &&
                      currentWorkout!.id! > 0) {
                    final userService = UserService();
                    await userService.deleteWorkout(currentWorkout!.id!);
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete))
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                textAlign: TextAlign.center,
                controller: workoutNameController,
                obscureText: false,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Workout Name',
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Workout"),
              onPressed: () {
                addWorkout(workoutNameController.text, addedExercises);
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Warm Ups'),
                    NumberPicker(
                      decoration: BoxDecoration(border: Border.all()),
                      value: warmUpS,
                      minValue: 0,
                      maxValue: 10,
                      onChanged: (value) => setState(() => warmUpS = value),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Work Sets'),
                    NumberPicker(
                      decoration: BoxDecoration(border: Border.all()),
                      value: workS,
                      minValue: 0,
                      maxValue: 10,
                      onChanged: (value) => setState(() => workS = value),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Drop Sets'),
                    NumberPicker(
                      decoration: BoxDecoration(border: Border.all()),
                      value: dropS,
                      minValue: 0,
                      maxValue: 10,
                      onChanged: (value) => setState(() => dropS = value),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 20),
            DropdownMenu<ApiExercise>(
              width: MediaQuery.of(context).size.width * 0.7,
              //initialSelection: ExerciseList.Benchpress,
              controller: exerciseController,
              menuHeight: 500,
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                constraints: BoxConstraints.tight(const Size.fromHeight(40)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              requestFocusOnTap: false,
              label: const Text('Exercises'),
              onSelected: (selectExercises) {
                setState(() {
                  selectedExercise = selectExercises;
                });
              },
              dropdownMenuEntries: allExercises
                  .map<DropdownMenuEntry<ApiExercise>>((ApiExercise exercise) {
                return DropdownMenuEntry<ApiExercise>(
                    value: exercise,
                    label: exercise.name,
                    leadingIcon: FaIcon(itemList[exercise.type])
                    //enabled: color.label != 'Grey',
                    //style: MenuItemButton.styleFrom(
                    //  foregroundColor: color.color,
                    //),
                    );
              }).toList(),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Exercise"),
              onPressed: () {
                setState(() {
                  if (selectedExercise != null) {
                    for (int i = 0; i < addedExercises.length; ++i) {
                      if (addedExercises[i].exerciseName ==
                          selectedExercise!.name) {
                        return;
                      }
                    }
                    addedExercises.add(ApiWorkoutUnit(
                        id: 0,
                        userName: "DefaultUser",
                        workoutId: 0,
                        exerciseId: selectedExercise!.id ?? 0,
                        exerciseName: selectedExercise!.name,
                        warmups: warmUpS,
                        worksets: workS,
                        dropsets: dropS,
                        type: selectedExercise!.type));
                    addRemEx.value = !addRemEx.value;
                  } else {
                    return;
                  }
                });
              },
            ),
            const Divider(),
            Expanded(
              child: ValueListenableBuilder(
                  valueListenable: addRemEx,
                  builder: (context, bool addRemEx, _) {
                    var items = addedExercises;
                    if (items.isNotEmpty) {
                      return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final exerciseType = item.type;
                            final currentIcon = itemList[exerciseType];
                            return ExerciseTile(
                                exerciseName: item.exerciseName,
                                warmUpS: item.warmups,
                                workS: item.worksets,
                                dropS: item.dropsets,
                                icon: currentIcon,
                                remo: remExercise,
                                item: item);
                          });
                    } else {
                      return const Text("No exercises yet");
                    }
                  }),
            ),
          ],
        ));
  }
}

class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exerciseName,
    required this.warmUpS,
    required this.workS,
    required this.dropS,
    required this.icon,
    required this.remo,
    required this.item,
  });

  final String exerciseName;
  final int warmUpS;
  final int workS;
  final int dropS;
  final IconData icon;
  final Function remo;
  final ApiWorkoutUnit item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: true,
      leading: FaIcon(icon),
      title: Text(exerciseName),
      subtitle:
          Text('Warm Ups: $warmUpS, Work Sets: $workS, Drop Sets: $dropS'),
      trailing: IconButton(
          icon: const Icon(Icons.delete), onPressed: () => remo(item)),
    );
  }
}
