/**
 * Landing Screen - Main Application Dashboard
 * 
 * This is the primary dashboard screen of the Gymli fitness application,
 * providing quick access to workouts, exercise browsing, and muscle group
 * specific training programs.
 * 
 * Key features:
 * - Exercise browse functionality with muscle group filtering
 * - Quick workout access and recent exercise display
 * - Muscle group specific workout recommendations
 * - Exercise search and filtering capabilities
 * - Recent training history overview
 * - Navigation hub to other application sections
 * - Real-time exercise data loading and display
 * - Integration with workout setup and exercise screens
 * 
 * The screen serves as the main entry point for users to access all
 * fitness tracking and workout management features of the application.
 */

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
  DateTime? _lastDataLoad; // Cache timestamp

  Future<void> updateAllExercises({bool forceReload = false}) async {
    try {
      // Only reload if data is stale (older than 30 seconds) or empty, unless force reload is requested
      final now = DateTime.now();
      if (!forceReload &&
          _lastDataLoad != null &&
          allExercises.isNotEmpty &&
          now.difference(_lastDataLoad!).inSeconds < 30) {
        return; // Use cached data
      }

      final exercises = await userService.getExercises();
      allExercises = exercises.map((e) => ApiExercise.fromJson(e)).toList();
      allExercises.sort((a, b) => a.name.compareTo(b.name));
      _lastDataLoad = now;
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
    for (var ex in allExercises) {
      if (filterMask.contains(ex.name)) {
        filteredExercises.add(ex);
      }
    }
    // Sort AFTER adding exercises to the list
    filteredExercises.sort((a, b) => a.name.compareTo(b.name));

    // Initialize metainfo array with default values
    metainfo = List.filled(filteredExercises.length, "");

    // Fill in workout-specific information
    for (var e in workout.units) {
      for (int i = 0; i < filteredExercises.length; ++i) {
        if (filteredExercises[i].name == e.exerciseName) {
          metainfo[i] = 'Warm: ${e.warmups}, Work: ${e.worksets}';
        }
      }
    }

    // Fill any remaining empty entries with default exercise info
    for (int i = 0; i < metainfo.length; i++) {
      if (metainfo[i].isEmpty) {
        final ex = filteredExercises[i];
        metainfo[i] =
            '${ex.defaultRepBase}-${ex.defaultRepMax} Reps @ ${ex.defaultIncrement}kg';
      }
    }

    filterApplied.value = !filterApplied.value;
  }

  Future<void> showAllExercises() async {
    filteredExercises = allExercises;
    metainfo = [];

    if (filteredExercises.isEmpty) {
      filterApplied.value = !filterApplied.value;
      return;
    }

    try {
      // Get exercise names for batch processing
      final exerciseNames = filteredExercises.map((ex) => ex.name).toList();

      // Fetch last training days for all exercises in one batch call
      final lastTrainingDays =
          await db.getLastTrainingDaysForExercises(exerciseNames);

      // Build metainfo for each exercise
      for (var ex in filteredExercises) {
        final lastTraining = lastTrainingDays[ex.name] ?? DateTime.now();
        final dayDiff = DateTime.now().difference(lastTraining).inDays;
        String dayInfo = dayDiff > 0 ? "$dayDiff days ago" : "today";
        metainfo.add(
            '${ex.defaultRepBase}-${ex.defaultRepMax} Reps @ ${ex.defaultIncrement}kg - $dayInfo');
      }
    } catch (e) {
      print('Error in showAllExercises: $e');
      // Fallback metainfo without training dates - ensure same length as filteredExercises
      metainfo.clear();
      for (var ex in filteredExercises) {
        metainfo.add(
            '${ex.defaultRepBase}-${ex.defaultRepMax} Reps @ ${ex.defaultIncrement}kg');
      }
    }

    // Ensure metainfo and filteredExercises are the same length
    while (metainfo.length < filteredExercises.length) {
      final ex = filteredExercises[metainfo.length];
      metainfo.add(
          '${ex.defaultRepBase}-${ex.defaultRepMax} Reps @ ${ex.defaultIncrement}kg');
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

    // Build metainfo to match filteredExercises length
    for (var ex in filteredExercises) {
      metainfo.add(
          'Reps: ${ex.defaultRepBase} to ${ex.defaultRepMax} Weight Incr.: ${ex.defaultIncrement}');
    }

    // Safety check to ensure lists are the same length
    while (metainfo.length < filteredExercises.length) {
      final ex = filteredExercises[metainfo.length];
      metainfo.add(
          'Reps: ${ex.defaultRepBase} to ${ex.defaultRepMax} Weight Incr.: ${ex.defaultIncrement}');
    }

    filterApplied.value = !filterApplied.value;
  }

  Future<void> _reload(var value) async {
    try {
      // Load both workouts and exercises when navigating back from other screens
      await Future.wait([
        _loadWorkouts(),
        updateAllExercises(forceReload: true), // Force reload to get fresh data
      ]);

      // Preserve the current filter state when returning from other screens
      if (selectedWorkout != null) {
        // Re-apply workout filter if a workout was selected
        workoutFilterList(selectedWorkout!);
        // Update the controller to show the selected workout name
        setState(() {
          WorkoutController.text = selectedWorkout!.name;
          MuscleController.value = TextEditingValue.empty;
        });
      } else if (selectedMuscle != null) {
        // Re-apply muscle filter if a muscle group was selected
        muscleFilterList(selectedMuscle!);
        // Update the controller to show the selected muscle name
        setState(() {
          MuscleController.text = selectedMuscle!.muscleName;
          WorkoutController.value = TextEditingValue.empty;
        });
      } else {
        // Show all exercises if no filter was applied
        await showAllExercises();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reloading data: $e')),
        );
      }
    }
  }

  Future<void> _loadWorkouts() async {
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
    // Force reload data when authentication state changes (ignore cache)
    _loadData(forceReload: true);
  }

  Future<void> _loadData({bool forceReload = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show current user info while loading
      print('Loading data for user: ${userService.userName}');

      // Load exercises and workouts in parallel for faster loading
      await Future.wait([
        updateAllExercises(forceReload: forceReload),
        _loadWorkouts(),
      ]);

      setState(() {
        MuscleController.value = TextEditingValue.empty;
        WorkoutController.value = TextEditingValue.empty;
        _isLoading = false;
      });

      // Load exercise details after UI is responsive
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your fitness data...'),
          ],
        ),
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
                    selectedWorkout = null;
                    selectedMuscle = null;
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
                    selectedMuscle = null; // Clear muscle selection
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
                    selectedWorkout = null; // Clear workout selection
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
                          // Safety check to prevent index out of range errors
                          final meta = index < metainfo.length
                              ? metainfo[index]
                              : '${currentData.defaultRepBase}-${currentData.defaultRepMax} Reps @ ${currentData.defaultIncrement}kg';
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
