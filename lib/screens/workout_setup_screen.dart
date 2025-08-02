///Workout Setup Screen, accessed via the navigation bar or directly from a Workout
///create or edit Workouts by adding or removing Workout Units (Exercises with a set amound of warmup and work sets)

// ignore_for_file: file_names, constant_identifier_names
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:Gymli/utils/api/api_models.dart';
import 'package:Gymli/utils/services/service_container.dart';
import '../utils/themes/responsive_helper.dart';
import '../utils/info_dialogues.dart';

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
  //int dropS = 0;
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
      final container = ServiceContainer();
      final exerciseData = await container.exerciseService.getExercises();
      allExercises =
          exerciseData.map((item) => ApiExercise.fromJson(item)).toList();

      if (widget.workoutName.isNotEmpty) {
        workoutNameController.text = widget.workoutName;
        final workoutData = await container.workoutService.getWorkouts();
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
      if (kDebugMode) print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addWorkout(String name, List<ApiWorkoutUnit> units) async {
    try {
      final container = ServiceContainer();
      if (currentWorkout != null &&
          currentWorkout!.id != null &&
          currentWorkout!.id! > 0) {
        // Delete existing workout (this should also delete associated workout units)
        await container.workoutService.deleteWorkout(currentWorkout!.id!);

        // Create new workout with the updated data
        await container.workoutService.createWorkout(
          name: name,
          units: units.map((unit) => unit.toJson()).toList(),
        );

        // Reset currentWorkout since we've created a new one
        currentWorkout = null;
      } else {
        // Create new workout
        await container.workoutService.createWorkout(
          name: name,
          units: units.map((unit) => unit.toJson()).toList(),
        );
      }
      // Notify that data has changed
      container.notifyDataChanged();
      Navigator.pop(context);
    } catch (e) {
      if (kDebugMode) print('Error saving workout: $e');
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

    final mainContent = ControlUI(context); //TODO: never used?

    final exerciseList = exerciseListUI(); //TODO: never used?

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
          buildInfoButton('Workout Setup Info', context,
              () => showInfoDialogWorkoutSetup(context)),
          IconButton(
              onPressed: () async {
                if (currentWorkout != null &&
                    currentWorkout!.id != null &&
                    currentWorkout!.id! > 0) {
                  final container = ServiceContainer();
                  await container.workoutService
                      .deleteWorkout(currentWorkout!.id!);
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: ResponsiveHelper.isWebMobile(context)
          ? IsMobileWebLayout()
          : IsNotMobileWebLayout(),
    );
  }

  Expanded exerciseListUI() {
    return Expanded(
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
                      icon: currentIcon,
                      remo: remExercise,
                      item: item);
                });
          } else {
            return const Center(child: Text("No exercises yet"));
          }
        },
      ),
    );
  }

  Column ControlUI(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
        ResponsiveHelper.isWebMobile(context)
            ? Column(children: [
                SetNumberPickerMobile(),
                ExerciseChoiceMobile(context),
                AddExerciseMobile(),
              ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 60),
                ExerciseChoiceDesktop(context),
                SizedBox(width: 20),
                SetNumberPickerDesktop(),
                SizedBox(width: 20),
                AddExercise(),
                SizedBox(width: 20),
              ]),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget AddExercise() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: SizedBox(
        width: 100,
        height: 200,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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
                    type: selectedExercise!.type));
                addRemEx.value = !addRemEx.value;
              } else {
                return;
              }
            });
          },
          child: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }

  Widget AddExerciseMobile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: SizedBox(
        width: 100,
        //height: 200,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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
                    type: selectedExercise!.type));
                addRemEx.value = !addRemEx.value;
              } else {
                return;
              }
            });
          },
          child: const Icon(Icons.arrow_downward),
        ),
      ),
    );
  }

  DropdownMenu<ApiExercise> ExerciseChoiceMobile(BuildContext context) {
    return DropdownMenu<ApiExercise>(
      width: MediaQuery.of(context).size.width * 0.7,
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
            leadingIcon: FaIcon(itemList[exercise.type]));
      }).toList(),
    );
  }

  Widget ExerciseChoiceDesktop(BuildContext context) {
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height * 0.6,
      //decoration: BoxDecoration(
      //border: Border(
      //top: BorderSide(color: Colors.grey),
      //bottom: BorderSide(color: Colors.grey),
      //),
      //borderRadius: BorderRadius.circular(8),
      //),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              //color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            width: double.infinity,
            child: const Text(
              'Select Exercise',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allExercises.length,
              itemBuilder: (context, index) {
                final exercise = allExercises[index];
                final isSelected = selectedExercise?.id == exercise.id;

                return ListTile(
                  selected: isSelected,
                  leading: FaIcon(
                    itemList[exercise.type],
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(
                    exercise.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      selectedExercise = exercise;
                      exerciseController.text = exercise.name;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Row SetNumberPickerMobile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(width: 20),
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
        const Divider(),
      ],
    );
  }

  Row SetNumberPickerDesktop() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 20),
        Column(
          children: [
            const Text('Warm Ups'),
            SizedBox(
              width: 80,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                controller: TextEditingController(text: warmUpS.toString()),
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? 0;
                  if (intValue >= 0 && intValue <= 10) {
                    setState(() => warmUpS = intValue);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 80,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                controller: TextEditingController(text: workS.toString()),
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? 1;
                  if (intValue >= 0 && intValue <= 10) {
                    setState(() => workS = intValue);
                  }
                },
              ),
            ),
            const Text('Work Sets'),
          ],
        ),
      ],
    );
  }

  Row IsNotMobileWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Main content takes 2/3 of the width
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: ControlUI(context),
          ),
        ),
        // Vertical divider line
        Container(
          width: 1,
          color: Colors.black,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 16.0),
            child: _exerciseListContent(),
          ),
        ),
      ],
    );
  }

  Widget _exerciseListContent() {
    return ValueListenableBuilder(
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
                    icon: currentIcon,
                    remo: remExercise,
                    item: item);
              });
        } else {
          return const Center(child: Text("No exercises yet"));
        }
      },
    );
  }

  Column IsMobileWebLayout() {
    return Column(
      children: [
        ControlUI(context),
        const Divider(),
        exerciseListUI(),
      ],
    );
  }
}

class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exerciseName,
    required this.warmUpS,
    required this.workS,
    //required this.dropS,
    required this.icon,
    required this.remo,
    required this.item,
  });

  final String exerciseName;
  final int warmUpS;
  final int workS;
  //final int dropS;
  final IconData icon;
  final Function remo;
  final ApiWorkoutUnit item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: true,
      leading: FaIcon(icon),
      title: Text(exerciseName),
      subtitle: Text('Warm Ups: $warmUpS, Work Sets: $workS'),
      trailing: IconButton(
          icon: const Icon(Icons.delete), onPressed: () => remo(item)),
    );
  }
}
