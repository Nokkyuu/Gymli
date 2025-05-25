import 'package:flutter/material.dart';
import 'package:Gymli/exerciseScreen.dart';
import 'user_service.dart';
import 'api_models.dart';
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

  ApiWorkout? selectedWorkout;
  MuscleList? selectedMuscle;
  final UserService userService = UserService();
  List<ApiExercise> allExercises = [];
  List<ApiWorkout> availableWorkouts = [];
  List<ApiExercise> filteredExercises = [];
  ValueNotifier<bool> filterApplied = ValueNotifier<bool>(true);
  List<String> metainfo = [];
  bool _isLoading = true;

  Future<void> updateAllExercises() async {
    try {
      final exercises = await userService.getExercises();
      allExercises = exercises.map((e) => ApiExercise.fromJson(e)).toList();
      allExercises.sort((a, b) => a.name.compareTo(b.name));
      filterApplied.value = !filterApplied.value;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exercises: $e')),
        );
      }
    }
  }

  void workoutFilterList(ApiWorkout workout) {
    var filterMask = [];
    for (var e in workout.units) {
      filterMask.add(e.exerciseName);
    }
    filteredExercises = [];
    filteredExercises.sort((a, b) => a.name.compareTo(b.name));
    for (var ex in allExercises) {
      if (filterMask.contains(ex.name)) {
        filteredExercises.add(ex);
      }
    }
    metainfo = List.filled(allExercises.length, "");
    for (var e in workout.units) {
      for (int i = 0; i < filteredExercises.length; ++i) {
        if (filteredExercises[i].name == e.exerciseName) {
          metainfo[i] =
              'Warm: ${e.warmups}, Work: ${e.worksets}, Drop: ${e.dropsets}';
        }
      }
    }
    filterApplied.value = !filterApplied.value;
  }

  Future<void> showAllExercises() async {
    filteredExercises = allExercises;
    // filteredExercises.sort((a, b) => a.name.compareTo(b.name));
    metainfo = [];
    for (var ex in filteredExercises) {
      var lastTraining = await db.getLastTrainingDay(ex.name);
      var dayDiff = DateTime.now().difference(lastTraining).inDays;
      String dayInfo = dayDiff > 0 ? "$dayDiff days ago" : "today";
      metainfo.add(
          '${ex.defaultRepBase}-${ex.defaultRepMax} Reps @ ${ex.defaultIncrement}kg - $dayInfo');
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
      metainfo.add(
          'Reps: ${ex.defaultRepBase} to ${ex.defaultRepMax} Weight Incr.: ${ex.defaultIncrement}');
    }
    filterApplied.value = !filterApplied.value;
  }

  Future<void> _reload(var value) async {
    try {
      final workouts = await userService.getWorkouts();
      setState(() {
        availableWorkouts =
            workouts.map((w) => ApiWorkout.fromJson(w)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workouts: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();

    // Listen to authentication state changes
    userService.authStateNotifier.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    userService.authStateNotifier.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    // Reload data when authentication state changes
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show current user info while loading
      print('Loading data for user: ${userService.userName}');

      await updateAllExercises();
      await _reload(null);

      setState(() {
        MuscleController.value = TextEditingValue.empty;
        WorkoutController.value = TextEditingValue.empty;
        _isLoading = false;
      });

      await showAllExercises();

      // Show success message after login
      if (mounted && userService.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Welcome ${userService.userName}! Your data has been loaded.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Filter by or "),
              TextButton.icon(
                onPressed: () async {
                  setState(() {
                    WorkoutController.value = TextEditingValue.empty;
                    MuscleController.value = TextEditingValue.empty;
                  });
                  await showAllExercises();
                },
                label: const Text("Show All"),
                icon: const Icon(Icons.search),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(),
              DropdownMenu<ApiWorkout>(
                width: MediaQuery.of(context).size.width * 0.45,
                enabled: true,
                key: UniqueKey(),
                //initialSelection: WorkoutList.Push,
                controller: WorkoutController,
                requestFocusOnTap: false,
                label: const Text('Workouts'),
                onSelected: (ApiWorkout? workout) {
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
                    .map<DropdownMenuEntry<ApiWorkout>>((ApiWorkout workout) {
                  return DropdownMenuEntry<ApiWorkout>(
                    value: workout,
                    label: workout.name,
                    trailingIcon: IconButton(
                        onPressed: () => {
                              Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              WorkoutSetupScreen(workout.name)))
                                  .then((value) => _reload(value))
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
                                                ExerciseScreen(currentData.name,
                                                    description)))
                                    .then((value) => _reload(value));
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
