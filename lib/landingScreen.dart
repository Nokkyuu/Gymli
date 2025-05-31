/// Landing Screen - Main Application Dashboard
///
/// This is the primary dashboard screen of the Gymli fitness application,
/// providing quick access to workouts, exercise browsing, and muscle group
/// specific training programs.
///
/// Key features:
/// - Exercise browse functionality with muscle group filtering
/// - Quick workout access and recent exercise display
/// - Muscle group specific workout recommendations
/// - Exercise search and filtering capabilities
/// - Recent training history overview
/// - Navigation hub to other application sections
/// - Real-time exercise data loading and display
/// - Integration with workout setup and exercise screens
///
/// The screen serves as the main entry point for users to access all
/// fitness tracking and workout management features of the application.
library;

import 'package:flutter/material.dart';
import 'package:Gymli/exerciseScreen.dart';
import 'user_service.dart';
import 'api_models.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Gymli/workoutSetupScreen.dart';
import 'database.dart' as db;
import 'responsive_helper.dart';

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
    // Remove this line - sorting is done in ValueListenableBuilder
    // filteredExercises.sort((a, b) => a.name.compareTo(b.name));

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
    // Remove this line - sorting is done in ValueListenableBuilder
    // filteredExercises.sort((a, b) => a.name.compareTo(b.name));
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

  Future<void> muscleFilterList(MuscleList muscleName) async {
    var muscle = muscleName.muscleName;
    filteredExercises = [];
    metainfo = [];

    // Filter exercises by muscle group with 0.75+ intensity
    for (var ex in allExercises) {
      if (ex.primaryMuscleGroups.contains(muscle)) {
        filteredExercises.add(ex);
      }
    }

    // Remove this line - sorting is done in ValueListenableBuilder
    // filteredExercises.sort((a, b) => a.name.compareTo(b.name));

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

      // Build metainfo for each exercise (same format as showAllExercises)
      for (var ex in filteredExercises) {
        final lastTraining = lastTrainingDays[ex.name] ?? DateTime.now();
        final dayDiff = DateTime.now().difference(lastTraining).inDays;
        String dayInfo = dayDiff > 0 ? "$dayDiff days ago" : "today";
        metainfo.add(
            '${ex.defaultRepBase}-${ex.defaultRepMax} Reps @ ${ex.defaultIncrement}kg - $dayInfo');
      }
    } catch (e) {
      print('Error in muscleFilterList: $e');
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
        await muscleFilterList(selectedMuscle!);
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
        // Sort workouts alphabetically by name
        availableWorkouts.sort((a, b) => a.name.compareTo(b.name));
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

    return Stack(
      children: [
        Column(
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
                  controller: WorkoutController,
                  requestFocusOnTap: false,
                  label: const Text('Workouts'),
                  onSelected: (ApiWorkout? workout) {
                    workoutFilterList(workout!);
                    setState(() {
                      MuscleController.value = TextEditingValue.empty;
                      selectedWorkout = workout;
                      selectedMuscle = null;
                    });
                  },
                  inputDecorationTheme: InputDecorationTheme(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    constraints:
                        BoxConstraints.tight(const Size.fromHeight(40)),
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
                                                WorkoutSetupScreen(
                                                    workout.name)))
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
                  controller: MuscleController,
                  requestFocusOnTap: false,
                  label: const Text('Muscles'),
                  onSelected: (MuscleList? name) async {
                    await muscleFilterList(name!);
                    setState(() {
                      WorkoutController.value = TextEditingValue.empty;
                      selectedMuscle = name;
                      selectedWorkout = null;
                    });
                  },
                  inputDecorationTheme: InputDecorationTheme(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    constraints:
                        BoxConstraints.tight(const Size.fromHeight(40)),
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
                    var items = filteredExercises
                        .toList(); // Ensure we always work with a fresh list
                    // Sort alphabetically with case-insensitive comparison and trimmed names
                    items.sort((a, b) => a.name
                        .trim()
                        .toLowerCase()
                        .compareTo(b.name.trim().toLowerCase()));
                    //print(filteredExercises.map((e) => e.name).toList());
                    if (items.isNotEmpty) {
                      return ResponsiveHelper.isMobile(context)
                          ? _buildMobileListView(items)
                          : _buildDesktopGridView(items);
                    } else {
                      return const Text("No exercises yet");
                    }
                  }),
            )
          ],
        ),
        // Demo mode watermark
        if (!userService.isLoggedIn)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: -0.3, // Slight rotation for watermark effect
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DEMO MODE\nNo data will be saved\nplease log in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.withValues(alpha: 0.4),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileListView(List<ApiExercise> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => _buildExerciseListTile(items, index),
    );
  }

  Widget _buildDesktopGridView(List<ApiExercise> items) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 4 columns for non-mobile devices
        childAspectRatio: 4.0,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          child: _buildExerciseListTile(items, index),
        );
      },
    );
  }

  Widget _buildExerciseListTile(List<ApiExercise> items, int index) {
    final currentData = items[index];
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
      title: Text(
        currentData.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        meta,
        overflow: TextOverflow.ellipsis,
        maxLines: ResponsiveHelper.isMobile(context) ? 2 : 1,
      ),
      onTap: () {
        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ExerciseScreen(currentData.name, description)))
            .then((value) => _reload(value));
      },
    );
  }
}
