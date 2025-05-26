/**
 * Exercise Screen - Main Workout Interface
 * 
 * This is the primary workout interface where users perform exercises and
 * log their training sets. It provides comprehensive workout management
 * with real-time progress tracking and interactive controls.
 * 
 * Key features:
 * - Interactive exercise performance logging (weight, reps, RPE)
 * - Real-time progress visualization with fl_chart graphs
 * - Exercise history display and comparison
 * - Timer functionality for rest periods
 * - Set management (warmup vs work sets)
 * - One Rep Max (1RM) calculations and tracking
 * - Exercise configuration and setup options
 * - Visual feedback with color-coded performance indicators
 * - Integration with global muscle activation tracking
 * 
 * The screen serves as the core workout experience, combining data entry,
 * progress visualization, and workout guidance in a single interface.
 */

import 'package:flutter/material.dart';
import 'package:Gymli/exerciseListScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:Gymli/exerciseSetupScreen.dart';
import 'globals.dart' as globals;
import 'package:flutter/services.dart';
import 'user_service.dart';
import 'api_models.dart';

enum ExerciseType { warmup, work }

const List<Color> graphColors = [
  Color.fromARGB(255, 0, 109, 44),
  Color.fromARGB(255, 44, 162, 95),
  Color.fromARGB(255, 102, 194, 164),
  Color.fromARGB(255, 153, 216, 201),
];

const List<Color> additionalColors = [
  Color.fromARGB(255, 253, 204, 138),
  Color.fromARGB(255, 252, 141, 89),
  Color.fromARGB(255, 215, 48, 31)
];

final workIcons = [
  FontAwesomeIcons.fire,
  FontAwesomeIcons.handFist,
  FontAwesomeIcons.arrowDown
];

class ExerciseScreen extends StatefulWidget {
  final String exerciseName;
  final String workoutDescription;
  const ExerciseScreen(this.exerciseName, this.workoutDescription, {super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreen();
}

double itemHeight = 35.0;
double itemWidth = 50.0;

class _ExerciseScreen extends State<ExerciseScreen> {
  //final String exerciseName;
  final ScrollController _scrollController = ScrollController();
  int weightKg = 40;
  int weightDg = 0;
  int repetitions = 10;
  var minScore = 1e6;

  final List<int> _values = List<int>.generate(30, (i) => i + 1);
  Map<int, Color> _colorMap = {};
  var maxScore = 0.0;
  double maxHistoryDistance = globals.graphNumberOfDays.toDouble();
  late Timer timer;
  List<LineChartBarData> barData = [];
  Text timerText = const Text("");
  DateTime lastActivity = DateTime.now();
  DateTime workoutStartTime = DateTime.now();

  Text warmText = const Text('Warm');
  Text workText = const Text('Work');
  late int numWarmUps, numWorkSets;

  String hintText = "Only 1 more Rep until weight increase!";

  Set<ExerciseType> _selected = {ExerciseType.work};

  List<List<FlSpot>> trainingGraphs = [[], [], [], []];
  List<List<FlSpot>> additionalGraphs = [];
  // List<LineTooltipItem> graphToolTip = [];
  List<String> groupExercises = [];
  Map<int, List<String>> graphToolTip = {};

  // State variable for training sets to avoid constant reloading
  List<ApiTrainingSet> _todaysTrainingSets = [];
  bool _isLoadingTrainingSets = false;

  // Cache exercise and training data to avoid redundant API calls
  ApiExercise? _currentExercise;
  List<ApiTrainingSet> _cachedTodaysTrainingSetsForExercise = [];
  Future<void> _loadTodaysTrainingSets() async {
    if (_isLoadingTrainingSets) return;

    setState(() {
      _isLoadingTrainingSets = true;
    });

    try {
      final userService = UserService();
      final trainingSets = await userService.getTrainingSets();

      final todaysItems = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((item) =>
              item.exerciseName == widget.exerciseName &&
              item.date.day == DateTime.now().day &&
              item.date.month == DateTime.now().month &&
              item.date.year == DateTime.now().year)
          .toList();

      setState(() {
        _todaysTrainingSets = todaysItems;
        _isLoadingTrainingSets = false;
      });
    } catch (e) {
      print('Error loading today\'s training sets: $e');
      setState(() {
        _isLoadingTrainingSets = false;
      });
    }
  }

  Future<void> _deleteTrainingSet(ApiTrainingSet trainingSet) async {
    try {
      final userService = UserService();
      await userService.deleteTrainingSet(trainingSet.id!);

      // Update cached data
      _cachedTodaysTrainingSetsForExercise
          .removeWhere((set) => set.id == trainingSet.id);
      _todaysTrainingSets.removeWhere((set) => set.id == trainingSet.id);

      // Update graph with current cached data
      await _updateGraphFromCachedTrainingSets();
    } catch (e) {
      print('Error deleting training set: $e');
    }
  }

  Future<int> addSet(String exerciseName, double weight, int repetitions,
      int setType, String when) async {
    try {
      print(
          'Adding set: exercise=$exerciseName, weight=$weight, reps=$repetitions, setType=$setType, when=$when');
      final userService = UserService();
      final exercises = await userService.getExercises();
      final exerciseData = exercises.firstWhere(
        (item) => item['name'] == exerciseName,
        orElse: () => null,
      );

      if (exerciseData != null) {
        final exercise = ApiExercise.fromJson(exerciseData);
        await userService.createTrainingSet(
          exerciseId: exercise.id!,
          date: when,
          weight: weight,
          repetitions: repetitions,
          setType: setType,
          baseReps: exercise.defaultRepBase,
          maxReps: exercise.defaultRepMax,
          increment: exercise.defaultIncrement,
          machineName: "",
        );
        print('Training set created successfully');

        // Update cached data with the new set
        final newSet = ApiTrainingSet(
          userName: exercise.userName,
          exerciseId: exercise.id!,
          exerciseName: exerciseName,
          date: DateTime.parse(when),
          weight: weight,
          repetitions: repetitions,
          setType: setType,
          baseReps: exercise.defaultRepBase,
          maxReps: exercise.defaultRepMax,
          increment: exercise.defaultIncrement,
          machineName: "",
        );
        _cachedTodaysTrainingSetsForExercise.add(newSet);
        _todaysTrainingSets.add(newSet);

        // Update graph with current cached data
        await _updateGraphFromCachedTrainingSets();
      } else {
        print('Exercise not found: $exerciseName');
      }
      return 0;
    } catch (e) {
      print('Error adding training set: $e');
      return -1;
    }
  }

  Future<Map<int, List<ApiTrainingSet>>> get_trainingsets() async {
    try {
      final userService = UserService();
      final trainingSets = await userService.getTrainingSets();

      Map<int, List<ApiTrainingSet>> data = {};
      List<ApiTrainingSet> trainings = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((t) => t.exerciseName == widget.exerciseName)
          .toList();

      trainings = trainings
          .where((t) =>
              DateTime.now().difference(t.date).inDays <
                  globals.graphNumberOfDays &&
              t.setType > 0)
          .toList();

      for (var t in trainings) {
        int diff = DateTime.now().difference(t.date).inDays;
        if (!data.containsKey(diff)) {
          data[diff] = [];
        }
        data[diff]!.add(t);
      }
      return data;
    } catch (e) {
      print('Error getting training sets: $e');
      return {};
    }
  }

  void updateGraph() async {
    // Use cached data if available, otherwise fallback to API call
    if (_cachedTodaysTrainingSetsForExercise.isNotEmpty) {
      await _updateGraphFromCachedTrainingSets();
    } else {
      // Fallback to API call if cache is not available
      await _updateGraphFromAPI();
    }
  }

  Future<void> _updateGraphFromCachedTrainingSets() async {
    for (var t in trainingGraphs) {
      t.clear();
    }

    try {
      // Filter cached training sets for graph display (exclude warmups, limit time range)
      final filteredSets = _cachedTodaysTrainingSetsForExercise
          .where((t) =>
              DateTime.now().difference(t.date).inDays <
                  globals.graphNumberOfDays &&
              t.setType > 0) // Exclude warmup sets (setType 0)
          .toList();

      // Group cached training sets by day
      Map<int, List<ApiTrainingSet>> data = {};
      for (var t in filteredSets) {
        int diff = DateTime.now().difference(t.date).inDays;
        if (!data.containsKey(diff)) {
          data[diff] = [];
        }
        data[diff]!.add(t);
      }

      if (globals.detailedGraph) {
        var ii = data.keys.length;
        for (var k in data.keys) {
          List<String> tips = List.filled(groupExercises.length + 6, "");
          for (var i = 0; i < 4; ++i) {
            if (i < data[k]!.length) {
              trainingGraphs[i].add(
                  FlSpot(-ii.toDouble(), globals.calculateScore(data[k]![i])));
              tips[i] =
                  "${data[k]![i].weight}kg @ ${data[k]![i].repetitions}reps";
            }
          }
          graphToolTip[-ii] = tips;
          ii -= 1;
        }
      } else {
        var ii = data.keys.length;
        for (var k in data.keys) {
          double maxScore = 0.0;
          int reps = 0;
          double weight = 0;
          for (var i = 0; i < data[k]!.length; ++i) {
            maxScore = max(maxScore, globals.calculateScore(data[k]![i]));
            reps = data[k]![i].repetitions;
            weight = data[k]![i].weight;
          }
          trainingGraphs[0].add(FlSpot(-ii.toDouble(), maxScore));
          graphToolTip[-ii] = ["${weight}kg @ ${reps}reps"];
          ii -= 1;
        }
      }

      // Update bar data for chart display
      _updateBarDataFromTrainingGraphs();

      setState(() {
        // Graph data updated
      });
    } catch (e) {
      print('Error updating graph from cached data: $e');
    }
  }

  Future<void> _updateGraphFromAPI() async {
    for (var t in trainingGraphs) {
      t.clear();
    }

    try {
      if (globals.detailedGraph) {
        var data = await get_trainingsets();
        var ii = data.keys.length;
        for (var k in data.keys) {
          List<String> tips = List.filled(groupExercises.length + 6, "");
          for (var i = 0; i < 4; ++i) {
            if (i < data[k]!.length) {
              trainingGraphs[i].add(
                  FlSpot(-ii.toDouble(), globals.calculateScore(data[k]![i])));
              tips[i] =
                  "${data[k]![i].weight}kg @ ${data[k]![i].repetitions}reps";
            }
          }
          graphToolTip[-ii] = tips;
          ii -= 1;
        }
      } else {
        var dat = await get_trainingsets();
        var ii = dat.keys.length;
        for (var k in dat.keys) {
          double maxScore = 0.0;
          int reps = 0;
          double weight = 0;
          for (var i = 0; i < dat[k]!.length; ++i) {
            maxScore = max(maxScore, globals.calculateScore(dat[k]![i]));
            reps = dat[k]![i].repetitions;
            weight = dat[k]![i].weight;
          }
          trainingGraphs[0].add(FlSpot(-ii.toDouble(), maxScore));
          graphToolTip[-ii] = ["${weight}kg @ ${reps}reps"];
          ii -= 1;
        }
      }

      // Update bar data for chart display
      _updateBarDataFromTrainingGraphs();

      setState(() {
        // Graph data updated
      });
    } catch (e) {
      print('Error updating graph from API: $e');
    }
  }

  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  void dispose() {
    timer.cancel(); // Cancel the timer when the state is disposed
    super.dispose();
  }

  void notifyIdle() {
    int numberOfNotifies = 3;
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      HapticFeedback.vibrate();
      if (--numberOfNotifies == 0) {
        timer.cancel();
      }
    });
  }

  void updateLastWeightSetting() async {
    // Use cached data if available, otherwise fall back to API calls
    if (_currentExercise != null &&
        _cachedTodaysTrainingSetsForExercise.isNotEmpty) {
      _updateWeightFromCachedData();
      return;
    }

    // Fallback to API calls if cache is not available (shouldn't happen after initialization)
    try {
      final userService = UserService();
      final exercises = await userService.getExercises();
      final exerciseData = exercises.firstWhere(
        (item) => item['name'] == widget.exerciseName,
        orElse: () => null,
      );

      if (exerciseData != null) {
        final exercise = ApiExercise.fromJson(exerciseData);
        final trainingSets = await userService.getTrainingSets();
        final todaysSets = trainingSets
            .map((item) => ApiTrainingSet.fromJson(item))
            .where((t) => t.exerciseName == widget.exerciseName)
            .toList();

        double weight = exercise.defaultIncrement;
        int reps = exercise.defaultRepBase;

        if (todaysSets.isNotEmpty) {
          final lastSet = todaysSets.last;
          weight = lastSet.weight;
          reps = lastSet.repetitions;
        }

        if (_selected.first == ExerciseType.warmup) {
          weight /= 2.0;
          weight = (weight / exercise.defaultIncrement).round() *
              exercise.defaultIncrement;
        }

        var data = await get_trainingsets();
        if (data.isNotEmpty) {
          var last = data[data.keys.last]!.last;
          for (int i = last.baseReps; i <= last.maxReps; ++i) {
            _colorMap[i] = Colors.red;
          }
        }

        setState(() {
          weightKg = weight.toInt();
          weightDg = (weight * 100.0).toInt() % 100;
          repetitions = reps;
        });
      }
    } catch (e) {
      print('Error updating last weight setting: $e');
    }
  }

  void _updateWeightFromCachedData() {
    if (_currentExercise == null) return;

    double weight = _currentExercise!.defaultIncrement;
    int reps = _currentExercise!.defaultRepBase;

    if (_cachedTodaysTrainingSetsForExercise.isNotEmpty) {
      final lastSet = _cachedTodaysTrainingSetsForExercise.last;
      weight = lastSet.weight;
      reps = lastSet.repetitions;
    }

    if (_selected.first == ExerciseType.warmup) {
      weight /= 2.0;
      weight = (weight / _currentExercise!.defaultIncrement).round() *
          _currentExercise!.defaultIncrement;
    }

    setState(() {
      weightKg = weight.toInt();
      weightDg = (weight * 100.0).toInt() % 100;
      repetitions = reps;
    });
  }

  void _parseWorkoutDescription() {
    // Initialize default values
    numWarmUps = 0;
    numWorkSets = 0;

    // Parse workout description if it contains workout context
    if (widget.workoutDescription.isNotEmpty &&
        widget.workoutDescription.startsWith("Warm:")) {
      try {
        // Expected format: "Warm: X, Work: Y"
        final parts = widget.workoutDescription.split(", ");
        if (parts.length == 2) {
          // Parse warmups
          final warmPart = parts[0]; // "Warm: X"
          if (warmPart.contains(":")) {
            final warmValue = warmPart.split(":")[1].trim();
            numWarmUps = int.tryParse(warmValue) ?? 0;
          }

          // Parse worksets
          final workPart = parts[1]; // "Work: Y"
          if (workPart.contains(":")) {
            final workValue = workPart.split(":")[1].trim();
            numWorkSets = int.tryParse(workValue) ?? 0;
          }
        }
        print(
            'Parsed workout context: Warmups=$numWarmUps, Worksets=$numWorkSets');
      } catch (e) {
        print('Error parsing workout description: $e');
        numWarmUps = 0;
        numWorkSets = 0;
      }
    }

    // Immediately update UI with workout context
    _updateWorkoutTexts();
  }

  void _updateWorkoutTexts() {
    warmText =
        numWarmUps > 0 ? Text("${numWarmUps}x Warm") : const Text("Warm");
    workText =
        numWorkSets > 0 ? Text("${numWorkSets}x Work") : const Text("Work");
  }

  @override
  void initState() {
    super.initState();

    // Parse workout context and set UI immediately
    _parseWorkoutDescription();

    // Set initial state immediately to avoid UI delays
    setState(() {
      _isLoadingTrainingSets = true;
      // Set reasonable defaults immediately
      weightKg = 40;
      weightDg = 0;
      repetitions = 10;
    });

    // Initialize screen data asynchronously
    _initializeScreen();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        var duration = DateTime.now().difference(lastActivity);
        if (duration.inSeconds == globals.idleTimerWakeup) {
          notifyIdle();
        }
        var workoutDuration = DateTime.now().difference(workoutStartTime);
        String workoutString =
            workoutDuration.toString().split(".")[0]; // ewwww, nasty
        workoutString =
            "${workoutString.split(":")[0]}:${workoutString.split(":")[1]}";
        timerText = Text(
            "Working out: $workoutString - Idle: ${duration.toString().split(".")[0]}");
      });
    });
  }

  void _initializeScreen() async {
    try {
      final userService = UserService();

      // Fetch data in parallel for faster loading
      final results = await Future.wait([
        userService.getTrainingSets(),
        userService.getExercises(),
      ]);

      final trainingSets = results[0];
      final exercises = results[1];

      // Process today's training sets for this exercise only
      final todaysTrainingSets = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((t) =>
              t.exerciseName == widget.exerciseName &&
              t.date.day == DateTime.now().day &&
              t.date.month == DateTime.now().month &&
              t.date.year == DateTime.now().year)
          .toList();

      // Find current exercise
      final exerciseData = exercises.firstWhere(
        (item) => item['name'] == widget.exerciseName,
        orElse: () => null,
      );

      // Set workout timing
      if (todaysTrainingSets.isNotEmpty) {
        workoutStartTime = todaysTrainingSets.first.date;
        lastActivity = todaysTrainingSets.last.date;
      }

      // Calculate timer text
      var duration = DateTime.now().difference(lastActivity);
      var workoutDuration = DateTime.now().difference(workoutStartTime);
      timerText = Text(
          "Working out: ${workoutDuration.toString().split(".")[0]} - Idle: ${duration.toString().split(".")[0]}");

      // Prepare weight settings
      double weight = 40.0;
      int reps = 10;

      if (exerciseData != null) {
        final exercise = ApiExercise.fromJson(exerciseData);
        _currentExercise = exercise; // Cache exercise data
        weight = exercise.defaultIncrement;
        reps = exercise.defaultRepBase;

        // Use last set data if available and cache today's sets for this exercise
        final todaysSetsForExercise = trainingSets
            .map((item) => ApiTrainingSet.fromJson(item))
            .where((t) => t.exerciseName == widget.exerciseName)
            .toList();

        _cachedTodaysTrainingSetsForExercise =
            todaysSetsForExercise; // Cache for fast access

        if (todaysSetsForExercise.isNotEmpty) {
          final lastSet = todaysSetsForExercise.last;
          weight = lastSet.weight;
          reps = lastSet.repetitions;
        }

        // Adjust for warmup if selected
        if (_selected.first == ExerciseType.warmup) {
          weight /= 2.0;
          weight = (weight / exercise.defaultIncrement).round() *
              exercise.defaultIncrement;
        }
      }

      // Update workout text counts based on completed sets
      int originalWarmUps = numWarmUps;
      int originalWorkSets = numWorkSets;

      for (var set in todaysTrainingSets) {
        if (set.setType == 0) {
          numWarmUps = (numWarmUps - 1).clamp(0, originalWarmUps);
        } else if (set.setType == 1) {
          numWorkSets = (numWorkSets - 1).clamp(0, originalWorkSets);
        }
      }

      // Update all UI in one setState call
      setState(() {
        _todaysTrainingSets = todaysTrainingSets;
        _isLoadingTrainingSets = false;

        // Set weight and reps
        weightKg = weight.toInt();
        weightDg = (weight * 100.0).toInt() % 100;
        repetitions = reps;

        // Update workout texts
        _updateWorkoutTexts();
      });

      // Initialize remaining components in parallel (non-blocking)
      groupExercises = [];
      additionalGraphs = List.filled(groupExercises.length, []);

      // Update graph in background using already fetched data
      _updateGraphWithCachedData(trainingSets);

      // Update color mapping with cached data
      _updateColorMappingFromCache();
    } catch (e) {
      print('Error initializing screen: $e');
      setState(() {
        _isLoadingTrainingSets = false;
      });
    }
  }

  Future<void> _updateGraphWithCachedData(List<dynamic> trainingSets) async {
    // Clear existing graph data
    for (var t in trainingGraphs) {
      t.clear();
    }

    try {
      // Convert training sets to ApiTrainingSet objects and filter for this exercise
      final exerciseTrainingSets = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((t) => t.exerciseName == widget.exerciseName)
          .toList();

      // Sort by date to create proper time-based grouping
      exerciseTrainingSets.sort((a, b) => a.date.compareTo(b.date));

      // Group by day
      Map<int, List<ApiTrainingSet>> data = {};
      for (var t in exerciseTrainingSets) {
        int diff = DateTime.now().difference(t.date).inDays;
        if (!data.containsKey(diff)) {
          data[diff] = [];
        }
        data[diff]!.add(t);
      }

      if (globals.detailedGraph) {
        var ii = data.keys.length;
        for (var k in data.keys) {
          List<String> tips = List.filled(groupExercises.length + 6, "");
          for (var i = 0; i < 4; ++i) {
            if (i < data[k]!.length) {
              trainingGraphs[i].add(
                  FlSpot(-ii.toDouble(), globals.calculateScore(data[k]![i])));
              tips[i] =
                  "${data[k]![i].weight}kg @ ${data[k]![i].repetitions}reps";
            }
          }
          graphToolTip[-ii] = tips;
          ii -= 1;
        }
      } else {
        var ii = data.keys.length;
        for (var k in data.keys) {
          double maxScore = 0.0;
          int reps = 0;
          double weight = 0;
          for (var i = 0; i < data[k]!.length; ++i) {
            maxScore = max(maxScore, globals.calculateScore(data[k]![i]));
            reps = data[k]![i].repetitions;
            weight = data[k]![i].weight;
          }
          trainingGraphs[0].add(FlSpot(-ii.toDouble(), maxScore));
          graphToolTip[-ii] = ["${weight}kg @ ${reps}reps"];
          ii -= 1;
        }
      }

      // Update bar data for chart display
      _updateBarDataFromTrainingGraphs();

      setState(() {
        // Graph data updated
      });
    } catch (e) {
      print('Error updating graph with cached data: $e');
    }
  }

  void _updateColorMappingFromCache() {
    if (_cachedTodaysTrainingSetsForExercise.isNotEmpty &&
        _currentExercise != null) {
      try {
        for (int i = _currentExercise!.defaultRepBase;
            i <= _currentExercise!.defaultRepMax;
            ++i) {
          _colorMap[i] = Colors.red;
        }
      } catch (e) {
        print('Error updating color mapping: $e');
      }
    }
  }

  void _updateTextsWithData(List<ApiTrainingSet> todaysTrainingSets) {
    try {
      for (var i in todaysTrainingSets) {
        if (i.setType == 0) {
          numWarmUps = (numWarmUps - 1).clamp(0, 999);
        } else if (i.setType == 1) {
          numWorkSets = (numWorkSets - 1).clamp(0, 999);
        }
      }

      setState(() {
        _updateWorkoutTexts();
      });
    } catch (e) {
      print('Error updating texts: $e');
    }
  }

  void _updateBarDataFromTrainingGraphs() {
    barData.clear();

    // Create line chart bars from training graph data
    for (int i = 0; i < trainingGraphs.length; i++) {
      if (trainingGraphs[i].isNotEmpty) {
        barData.add(LineChartBarData(
          spots: trainingGraphs[i],
          isCurved: true,
          color: i < graphColors.length ? graphColors[i] : Colors.grey,
          barWidth: 2,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: true),
        ));
      }
    }

    // Add additional graph data if any
    for (int i = 0; i < additionalGraphs.length; i++) {
      if (additionalGraphs[i].isNotEmpty) {
        barData.add(LineChartBarData(
          spots: additionalGraphs[i],
          isCurved: true,
          color:
              i < additionalColors.length ? additionalColors[i] : Colors.grey,
          barWidth: 2,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: true),
        ));
      }
    }

    // Update min/max scores for proper graph scaling
    double newMinScore = 1e6;
    double newMaxScore = 0.0;

    for (var barDataItem in barData) {
      for (var spot in barDataItem.spots) {
        newMinScore = min(newMinScore, spot.y);
        newMaxScore = max(newMaxScore, spot.y);
      }
    }

    // Set reasonable defaults if no data
    if (barData.isEmpty) {
      newMinScore = 0;
      newMaxScore = 100;
    }

    minScore = newMinScore;
    maxScore = newMaxScore;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    TextEditingController dateInputController =
        TextEditingController(text: DateTime.now().toString());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios,
            ),
          ),
          title: Text(widget.exerciseName),
          bottom: PreferredSize(preferredSize: Size.zero, child: timerText),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ExerciseSetupScreen(widget.exerciseName)));
                },
                icon: const Icon(Icons.edit)),
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ExerciseListScreen(widget.exerciseName)));
                },
                icon: const Icon(Icons.list))
          ]),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.20,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Padding(
                      padding: const EdgeInsets.only(
                          right: 10.0, top: 10.0, left: 0.0),
                      child: LineChart(LineChartData(
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        clipData: const FlClipData.all(),
                        lineBarsData: barData,
                        lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 0.0,
                          showOnTopOfTheChartBoxArea: false,
                          fitInsideVertically: true,
                          tooltipMargin: 0,
                          getTooltipItems: (value) {
                            return value.map((e) {
                              return LineTooltipItem(
                                  graphToolTip[e.x.toInt()]![e.barIndex],
                                  const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ));
                            }).toList();
                          },
                        )),
                        minY: minScore - 5.0,
                        maxY: maxScore + 5.0,
                        minX: -maxHistoryDistance,
                        maxX: 0,
                      ))),
                )),
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: (() {
                var boxdim = 8.0;
                List<Widget> widgets = [
                  const SizedBox(width: 20),
                  const Text("Sets", style: const TextStyle(fontSize: 8.0)),
                  const SizedBox(width: 10)
                ];
                for (int i = 0; i < 4; i++) {
                  widgets.add(Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                            width: boxdim,
                            height: boxdim,
                            color: graphColors[i]),
                        Text("  $i", style: const TextStyle(fontSize: 8.0)),
                        const SizedBox(width: 10)
                      ]));
                }
                for (int i = 0; i < groupExercises.length; ++i) {
                  widgets.add(Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                            width: boxdim,
                            height: boxdim,
                            color: additionalColors[i]),
                        Text("  ${groupExercises[i]}",
                            style: const TextStyle(fontSize: 8.0)),
                        const SizedBox(width: 10)
                      ]));
                }
                return widgets;
              })(),
            ),
            // const Divider(),
            // Row(mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Image.asset('images/fairy.png',
            //       fit: BoxFit.contain,
            //       height: 18,
            //       ),
            //       const SizedBox(width: 10),
            //       Text(hintText),
            //   ],
            // ),
            const Divider(),
            Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    SegmentedButton<ExerciseType>(
                      showSelectedIcon: false,
                      segments: <ButtonSegment<ExerciseType>>[
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.warmup,
                            label: warmText,
                            icon: const Icon(Icons.local_fire_department)),
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.work,
                            label: workText,
                            icon: const FaIcon(FontAwesomeIcons.handFist)),
                      ],
                      selected: _selected,
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          if (_selected.first == ExerciseType.warmup ||
                              newSelection.first == ExerciseType.warmup) {
                            _selected = newSelection;
                            _updateWeightFromCachedData(); // Use cached data instead of API calls
                          }
                          _selected = newSelection;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Spacer(),
                      NumberPicker(
                        //selectedTextStyle: TextStyle(color: Colors.black),
                        value: weightKg,
                        minValue: -70, maxValue: 250,
                        haptics: true,
                        itemHeight: itemHeight, itemWidth: itemWidth,
                        onChanged: (value) => setState(() => weightKg = value),
                      ),
                      const Text(","),
                      NumberPicker(
                        value: weightDg,
                        minValue: 0,
                        maxValue: 75,
                        step: 25,
                        haptics: true,
                        itemHeight: itemHeight,
                        itemWidth: itemWidth,
                        onChanged: (value) => setState(() => weightDg = value),
                      ),
                      const Text("kg"),
                      Container(
                        height: 100,
                        width: 100,
                        child: ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(
                              initialItem: repetitions - 1),
                          itemExtent: 40,
                          physics: const FixedExtentScrollPhysics(),
                          useMagnifier: true,
                          magnification: 1.4,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              repetitions = _values[index];
                              HapticFeedback.selectionClick();
                              // print(_currentValue);
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              final value = _values[index];
                              final color = _colorMap.containsKey(value)
                                  ? _colorMap[value]
                                  : Colors.black;
                              return Center(
                                child: Text(
                                  value.toString(),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 20,
                                      fontFamily: 'Roboto'),
                                ),
                              );
                            },
                            childCount: _values.length,
                          ),
                        ),
                      ),
                      const Text("Reps."),
                      const Spacer(),
                    ])
                  ],
                )),

            ElevatedButton.icon(
                style: const ButtonStyle(),
                label: const Text('Submit'),
                icon: const Icon(Icons.send),
                onPressed: () async {
                  double new_weight =
                      weightKg.toDouble() + weightDg.toDouble() / 100.0;

                  // Add the set
                  await addSet(widget.exerciseName, new_weight, repetitions,
                      _selected.first.index, dateInputController.text);

                  // Reload training sets after adding and update cache
                  await _loadTodaysTrainingSets();

                  // Update cache for this exercise specifically
                  if (_currentExercise != null) {
                    _cachedTodaysTrainingSetsForExercise = _todaysTrainingSets
                        .where((t) => t.exerciseName == widget.exerciseName)
                        .toList();
                  }

                  // Update texts with the new data
                  _updateTextsWithData(_todaysTrainingSets);

                  // Update graph using cached data
                  updateGraph();

                  lastActivity = DateTime.now();
                }),
            const Divider(),
            Expanded(
                child: _isLoadingTrainingSets
                    ? const Center(child: CircularProgressIndicator())
                    : _todaysTrainingSets.isNotEmpty
                        ? ListView.builder(
                            controller: _scrollController,
                            itemCount: _todaysTrainingSets.length,
                            itemBuilder: (context, index) {
                              final item = _todaysTrainingSets[index];
                              return ListTile(
                                leading: CircleAvatar(
                                    radius: 17.5,
                                    child: FaIcon(workIcons[item.setType])),
                                dense: true,
                                visualDensity:
                                    const VisualDensity(vertical: -3),
                                title: Text(
                                    "${item.weight}kg for ${item.repetitions} reps"),
                                subtitle: Text(
                                    "${item.date.hour}:${item.date.minute}:${item.date.second}"),
                                trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await _deleteTrainingSet(item);
                                      await _loadTodaysTrainingSets(); // Reload after deletion

                                      // Update cache for this exercise specifically
                                      if (_currentExercise != null) {
                                        _cachedTodaysTrainingSetsForExercise =
                                            _todaysTrainingSets
                                                .where((t) =>
                                                    t.exerciseName ==
                                                    widget.exerciseName)
                                                .toList();
                                      }

                                      updateGraph();
                                    }),
                              );
                            })
                        : ListView(
                            controller: _scrollController,
                            children: const [
                              ListTile(title: Text("No Training yet.")),
                            ],
                          )),
            const SizedBox(height: 20),
          ]),
    );
  }
}
