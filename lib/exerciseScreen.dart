/// Exercise Screen - Main Workout Interface
///
/// This is the primary workout interface where users perform exercises and
/// log their training sets. It provides comprehensive workout management
/// with real-time progress tracking and interactive controls.
///
/// Key features:
/// - Interactive exercise performance logging (weight, reps, RPE)
/// - Real-time progress visualization with fl_chart graphs
/// - Exercise history display and comparison
/// - Timer functionality for rest periods
/// - Set management (warmup vs work sets)
/// - One Rep Max (1RM) calculations and tracking
/// - Exercise configuration and setup options
/// - Visual feedback with color-coded performance indicators
/// - Integration with global muscle activation tracking
///
/// The screen serves as the core workout experience, combining data entry,
/// progress visualization, and workout guidance in a single interface.
library;

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
import 'responsive_helper.dart';

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
  final Map<int, Color> _colorMap = {};
  var maxScore = 0.0;
  double maxHistoryDistance =
      90.0; // Default to 90 days, will be updated based on actual data
  DateTime?
      mostRecentTrainingDate; // Store the most recent training date for proper x-axis labeling
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

  // Persistent text controllers to prevent deselection on setState
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  Future<void> _deleteTrainingSet(ApiTrainingSet trainingSet) async {
    try {
      final userService = UserService();
      await userService.deleteTrainingSet(trainingSet.id!);

      // Update cached data immediately
      _cachedTodaysTrainingSetsForExercise
          .removeWhere((set) => set.id == trainingSet.id);
      _todaysTrainingSets.removeWhere((set) => set.id == trainingSet.id);

      // Update graph and UI in parallel for better performance
      await Future.wait([
        _updateGraphFromCachedTrainingSets(),
        Future(() => setState(() {
              // UI will reflect the updated _todaysTrainingSets
            })),
      ]);
    } catch (e) {
      print('Error deleting training set: $e');
    }
  }

  Future<int> addSet(String exerciseName, double weight, int repetitions,
      int setType, String when) async {
    try {
      print(
          'Adding set: exercise=$exerciseName, weight=$weight, reps=$repetitions, setType=$setType, when=$when');

      // Use cached exercise data instead of API call
      if (_currentExercise == null || _currentExercise!.name != exerciseName) {
        print('Error: Exercise data not cached properly');
        return -1;
      }

      final userService = UserService();
      final createdSetData = await userService.createTrainingSet(
        exerciseId: _currentExercise!.id!,
        date: when,
        weight: weight,
        repetitions: repetitions,
        setType: setType,
        baseReps: _currentExercise!.defaultRepBase,
        maxReps: _currentExercise!.defaultRepMax,
        increment: _currentExercise!.defaultIncrement,
        machineName: "",
      );

      // Only update cache AFTER successful API call
      final newSet = ApiTrainingSet(
        id: createdSetData?['id'],
        userName: _currentExercise!.userName,
        exerciseId: _currentExercise!.id!,
        exerciseName: exerciseName,
        date: DateTime.parse(when),
        weight: weight,
        repetitions: repetitions,
        setType: setType,
        baseReps: _currentExercise!.defaultRepBase,
        maxReps: _currentExercise!.defaultRepMax,
        increment: _currentExercise!.defaultIncrement,
      );

      _cachedTodaysTrainingSetsForExercise.add(newSet);
      _todaysTrainingSets.add(newSet);

      // Update graph and UI in parallel for better performance
      await Future.wait([
        _updateGraphFromCachedTrainingSets(),
        Future(() => setState(() {
              // UI will reflect the updated _todaysTrainingSets
            })),
      ]);

      return 0;
    } catch (e) {
      print('Error adding training set: $e');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save training set: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
          .where((t) => t.exerciseName == widget.exerciseName && t.setType > 0)
          .toList();

      if (trainings.isNotEmpty) {
        // Find the most recent training date
        trainings.sort((a, b) => b.date.compareTo(a.date));
        final mostRecentDate = trainings.first.date;

        // Filter based on most recent training date (use global day range setting)
        trainings = trainings
            .where((t) =>
                mostRecentDate.difference(t.date).inDays <
                globals.graphNumberOfDays)
            .toList();

        for (var t in trainings) {
          int diff = mostRecentDate.difference(t.date).inDays;
          if (!data.containsKey(diff)) {
            data[diff] = [];
          }
          data[diff]!.add(t);
        }
      }

      return data;
    } catch (e) {
      print('Error getting training sets: $e');
      return {};
    }
  }

  void updateGraph() async {
    // Always use API call to ensure complete historical data for graphs
    // The cached data only contains today's sets, which is insufficient for graph display
    await _updateGraphFromAPI();
  }

  Future<void> _updateGraphFromCachedTrainingSets() async {
    for (var t in trainingGraphs) {
      t.clear();
    }

    try {
      // Filter cached training sets for graph display (exclude warmups)
      final workoutSets = _cachedTodaysTrainingSetsForExercise
          .where((t) => t.setType > 0) // Exclude warmup sets (setType 0)
          .toList();

      // Group training sets by calendar day (not by days difference)
      Map<String, List<ApiTrainingSet>> dataByDate = {};
      for (var t in workoutSets) {
        // Use date string as key (YYYY-MM-DD format)
        String dateKey =
            "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}";
        if (!dataByDate.containsKey(dateKey)) {
          dataByDate[dateKey] = [];
        }
        dataByDate[dateKey]!.add(t);
      }

      // Find best set for each day and create graph points
      List<FlSpot> graphPoints = [];
      Map<double, String> tooltipData = {};

      // Sort dates chronologically
      var sortedDates = dataByDate.keys.toList()..sort();

      // Ensure we have at least 2 days of data for minimum range
      if (sortedDates.isNotEmpty) {
        final earliestDate = DateTime.parse(sortedDates.first);
        final latestDate = DateTime.parse(sortedDates.last);
        mostRecentTrainingDate = latestDate; // Store for x-axis labeling
        final daysDifference = latestDate.difference(earliestDate).inDays;

        // Calculate dynamic range (minimum 2 days, maximum from global setting from most recent training date)
        final maxDaysFromLatest =
            latestDate.subtract(Duration(days: globals.graphNumberOfDays));
        DateTime startDate;
        if (daysDifference < 2) {
          // If we have less than 2 days, show at least 2 days range
          startDate = latestDate.subtract(const Duration(days: 2));
        } else {
          // Use actual earliest date but limit to global setting days from most recent training date
          startDate = earliestDate.isBefore(maxDaysFromLatest)
              ? maxDaysFromLatest
              : earliestDate;
        }

        // Update graph range
        maxHistoryDistance =
            max(2.0, latestDate.difference(startDate).inDays.toDouble());

        for (String dateKey in sortedDates) {
          final date = DateTime.parse(dateKey);
          final sets = dataByDate[dateKey]!;

          // Find best set for this day (highest weight, then most reps for that weight)
          ApiTrainingSet? bestSet;
          for (var set in sets) {
            if (bestSet == null ||
                set.weight > bestSet.weight ||
                (set.weight == bestSet.weight &&
                    set.repetitions > bestSet.repetitions)) {
              bestSet = set;
            }
          }

          if (bestSet != null) {
            // Calculate x-coordinate as days from latest date (negative values)
            double xValue = -latestDate.difference(date).inDays.toDouble();
            double yValue = globals.calculateScore(bestSet);

            graphPoints.add(FlSpot(xValue, yValue));
            tooltipData[xValue] =
                "${bestSet.weight}kg @ ${bestSet.repetitions}reps (${dateKey})";
          }
        }
      }

      // Add points to training graph
      if (graphPoints.isNotEmpty) {
        trainingGraphs[0].addAll(graphPoints);

        // Update tooltip data
        graphToolTip.clear();
        for (var entry in tooltipData.entries) {
          graphToolTip[entry.key.toInt()] = [entry.value];
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
      // Get training sets and extract the most recent date for x-axis labeling
      final userService = UserService();
      final trainingSets = await userService.getTrainingSets();
      List<ApiTrainingSet> trainings = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((t) => t.exerciseName == widget.exerciseName && t.setType > 0)
          .toList();

      if (trainings.isNotEmpty) {
        trainings.sort((a, b) => b.date.compareTo(a.date));
        mostRecentTrainingDate =
            trainings.first.date; // Store for x-axis labeling
      }

      var data = await get_trainingsets();

      if (data.isEmpty) {
        setState(() {
          // No data to display
        });
        return;
      }

      // The get_trainingsets method now returns data keyed by days from most recent date
      // and already applies the 90-day filter, so we can use it directly
      maxHistoryDistance = data.keys.isEmpty
          ? 90.0
          : data.keys.map((k) => k.abs()).reduce(max).toDouble();
      maxHistoryDistance = max(2.0, maxHistoryDistance); // Ensure minimum range

      if (globals.detailedGraph) {
        for (var k in data.keys) {
          List<String> tips = List.filled(groupExercises.length + 6, "");
          for (var i = 0; i < 4; ++i) {
            if (i < data[k]!.length) {
              trainingGraphs[i].add(
                  FlSpot(-k.toDouble(), globals.calculateScore(data[k]![i])));
              tips[i] =
                  "${data[k]![i].weight}kg @ ${data[k]![i].repetitions}reps";
            }
          }
          graphToolTip[-k] = tips;
        }
      } else {
        for (var k in data.keys) {
          double maxScore = 0.0;
          int reps = 0;
          double weight = 0;
          for (var i = 0; i < data[k]!.length; ++i) {
            maxScore = max(maxScore, globals.calculateScore(data[k]![i]));
            reps = data[k]![i].repetitions;
            weight = data[k]![i].weight;
          }
          trainingGraphs[0].add(FlSpot(-k.toDouble(), maxScore));
          graphToolTip[-k] = ["${weight}kg @ ${reps}reps"];
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
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    timer.cancel(); // Cancel the timer when the state is disposed
    _weightController.dispose();
    _repsController.dispose();
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
        orElse: () => <String, dynamic>{},
      );

      if (exerciseData.isNotEmpty) {
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

      // Update text controllers to match the new values
      _weightController.text = weight.toString();
      _repsController.text = reps.toString();
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

    // Initialize text controllers for persistent input fields
    _weightController = TextEditingController();
    _repsController = TextEditingController();

    // Parse workout context and set UI immediately
    _parseWorkoutDescription();

    // Set initial state immediately to avoid UI delays
    setState(() {
      _isLoadingTrainingSets = true;
      // Set reasonable defaults immediately
      weightKg = 40;
      weightDg = 0;
      repetitions = 10;

      // Initialize controllers with default values
      _weightController.text =
          (weightKg.toDouble() + weightDg.toDouble() / 100.0).toString();
      _repsController.text = repetitions.toString();
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
        orElse: () => <String, dynamic>{},
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

      if (exerciseData.isNotEmpty) {
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
      // Convert training sets to ApiTrainingSet objects and filter for this exercise (exclude warmups)
      final exerciseTrainingSets = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((t) =>
              t.exerciseName == widget.exerciseName &&
              t.setType > 0) // Exclude warmup sets
          .toList();

      if (exerciseTrainingSets.isEmpty) {
        setState(() {
          // No data to display
        });
        return;
      }

      // Group training sets by calendar day (consistent with _updateGraphFromCachedTrainingSets)
      Map<String, List<ApiTrainingSet>> dataByDate = {};
      for (var t in exerciseTrainingSets) {
        // Use date string as key (YYYY-MM-DD format)
        String dateKey =
            "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}";
        if (!dataByDate.containsKey(dateKey)) {
          dataByDate[dateKey] = [];
        }
        dataByDate[dateKey]!.add(t);
      }

      // Find best set for each day and create graph points
      List<FlSpot> graphPoints = [];
      Map<double, String> tooltipData = {};

      // Sort dates chronologically
      var sortedDates = dataByDate.keys.toList()..sort();

      // Ensure we have at least 2 days of data for minimum range
      if (sortedDates.isNotEmpty) {
        final earliestDate = DateTime.parse(sortedDates.first);
        final latestDate = DateTime.parse(sortedDates.last);
        mostRecentTrainingDate = latestDate; // Store for x-axis labeling
        final daysDifference = latestDate.difference(earliestDate).inDays;

        // Calculate dynamic range (minimum 2 days, maximum 360 days from most recent training date)
        final threeMonthsAgoFromLatest =
            latestDate.subtract(const Duration(days: 360));
        DateTime startDate;
        if (daysDifference < 2) {
          // If we have less than 2 days, show at least 2 days range
          startDate = latestDate.subtract(const Duration(days: 2));
        } else {
          // Use actual earliest date but limit to 90 days from most recent training date
          startDate = earliestDate.isBefore(threeMonthsAgoFromLatest)
              ? threeMonthsAgoFromLatest
              : earliestDate;
        }

        // Update graph range
        maxHistoryDistance =
            max(2.0, latestDate.difference(startDate).inDays.toDouble());

        for (String dateKey in sortedDates) {
          final date = DateTime.parse(dateKey);
          final sets = dataByDate[dateKey]!;

          // Find best set for this day (highest weight, then most reps for that weight)
          ApiTrainingSet? bestSet;
          for (var set in sets) {
            if (bestSet == null ||
                set.weight > bestSet.weight ||
                (set.weight == bestSet.weight &&
                    set.repetitions > bestSet.repetitions)) {
              bestSet = set;
            }
          }

          if (bestSet != null) {
            // Calculate x-coordinate as days from latest date (negative values)
            double xValue = -latestDate.difference(date).inDays.toDouble();
            double yValue = globals.calculateScore(bestSet);

            graphPoints.add(FlSpot(xValue, yValue));
            tooltipData[xValue] =
                "${bestSet.weight}kg @ ${bestSet.repetitions}reps (${dateKey})";
          }
        }
      }

      // Add points to training graph
      if (graphPoints.isNotEmpty) {
        trainingGraphs[0].addAll(graphPoints);

        // Update tooltip data
        graphToolTip.clear();
        for (var entry in tooltipData.entries) {
          graphToolTip[entry.key.toInt()] = [entry.value];
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
    TextEditingController dateInputController = TextEditingController(
        text: DateTime.now().toIso8601String() // Use ISO format instead
        );

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
      body: ResponsiveHelper.isWebMobile(context)
          ? _buildMobileLayout(dateInputController)
          : _buildDesktopLayout(dateInputController),
    );
  }

  Widget _buildDesktopLayout(TextEditingController dateInputController) {
    return Row(
      children: [
        // Left side - Main workout interface
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildGraphSection(),
              _buildGraphLegend(),
              const Divider(),
              _buildExerciseControlsDesktop(dateInputController),
              const SizedBox(height: 20),
            ],
          ),
        ),
        // Right side - Training sets list
        Container(
          width: 400,
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Colors.grey, width: 1)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Today's Training Sets",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(child: _buildTrainingSetsList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(TextEditingController dateInputController) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildGraphSection(),
        _buildGraphLegend(),
        const Divider(),
        _buildExerciseControls(dateInputController),
        const Divider(),
        Expanded(child: _buildTrainingSetsList()),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGraphSection() {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: ResponsiveHelper.isWebMobile(context)
            ? MediaQuery.of(context).size.height * 0.20
            : MediaQuery.of(context).size.height * 0.50,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Padding(
              padding: const EdgeInsets.only(right: 10.0, top: 10.0, left: 0.0),
              child: LineChart(LineChartData(
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxHistoryDistance > 30
                          ? 14
                          : 7, // Show dates every 7-14 days
                      getTitlesWidget: (double value, TitleMeta meta) {
                        // Convert negative x-value back to actual date using most recent training date
                        if (mostRecentTrainingDate == null)
                          return const Text('');
                        final daysAgo = value.abs().round();
                        final date = mostRecentTrainingDate!
                            .subtract(Duration(days: daysAgo));
                        return Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
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
        ));
  }

  Widget _buildGraphLegend() {
    return Row(
      children: (() {
        var boxdim = 8.0;
        List<Widget> widgets = [
          const SizedBox(width: 20),
          const Text("Sets", style: TextStyle(fontSize: 8.0)),
          const SizedBox(width: 10)
        ];
        for (int i = 0; i < 4; i++) {
          widgets.add(
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            Container(width: boxdim, height: boxdim, color: graphColors[i]),
            Text("  $i", style: const TextStyle(fontSize: 8.0)),
            const SizedBox(width: 10)
          ]));
        }
        for (int i = 0; i < groupExercises.length; ++i) {
          widgets.add(
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            Container(
                width: boxdim, height: boxdim, color: additionalColors[i]),
            Text("  ${groupExercises[i]}",
                style: const TextStyle(fontSize: 8.0)),
            const SizedBox(width: 10)
          ]));
        }
        return widgets;
      })(),
    );
  }

  Widget _buildExerciseControls(TextEditingController dateInputController) {
    return Padding(
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
              SizedBox(
                height: 100,
                width: 100,
                child: ListWheelScrollView.useDelegate(
                  controller:
                      FixedExtentScrollController(initialItem: repetitions - 1),
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
                              color: color, fontSize: 20, fontFamily: 'Roboto'),
                        ),
                      );
                    },
                    childCount: _values.length,
                  ),
                ),
              ),
              const Text("Reps."),
              const Spacer(),
            ]),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                style: const ButtonStyle(),
                label: const Text('Submit'),
                icon: const Icon(Icons.send),
                onPressed: () async {
                  double newWeight =
                      weightKg.toDouble() + weightDg.toDouble() / 100.0;

                  // Show loading indicator
                  setState(() {
                    // You might want to add a loading state
                  });

                  final result = await addSet(
                      widget.exerciseName,
                      newWeight,
                      repetitions,
                      _selected.first.index,
                      dateInputController.text);

                  if (result == 0) {
                    // Success - update UI
                    _updateTextsWithData(_todaysTrainingSets);
                    lastActivity = DateTime.now();

                    // Show success feedback
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Training set saved successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  } else {
                    // Failure was already handled in addSet, but we could add additional handling here
                    print('Submit failed - training set not saved');
                  }
                }),
          ],
        ));
  }

  Widget _buildExerciseControlsDesktop(
      TextEditingController dateInputController) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Vertically aligned warmup/work set radio buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<ExerciseType>(
                    value: ExerciseType.warmup,
                    groupValue: _selected.first,
                    onChanged: (ExerciseType? value) {
                      if (value != null) {
                        setState(() {
                          _selected = {value};
                          _updateWeightFromCachedData();
                        });
                      }
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = {ExerciseType.warmup};
                        _updateWeightFromCachedData();
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                            width: 24,
                            child: Icon(Icons.local_fire_department)),
                        const SizedBox(width: 8),
                        SizedBox(width: 60, child: warmText),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8), // Changed from width to height
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<ExerciseType>(
                    value: ExerciseType.work,
                    groupValue: _selected.first,
                    onChanged: (ExerciseType? value) {
                      if (value != null) {
                        setState(() {
                          _selected = {value};
                          _updateWeightFromCachedData();
                        });
                      }
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = {ExerciseType.work};
                        _updateWeightFromCachedData();
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                            width: 24,
                            child: FaIcon(FontAwesomeIcons.handFist)),
                        const SizedBox(width: 8),
                        SizedBox(width: 60, child: workText),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 40),

          // Weight and reps input fields stacked vertically
          Column(
            children: [
              // Weight input
              SizedBox(
                width: 120,
                child: TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  controller: _weightController,
                  onChanged: (value) {
                    final weight = double.tryParse(value) ?? 0.0;
                    setState(() {
                      weightKg = weight.toInt();
                      weightDg = ((weight - weightKg) * 100).round();
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Reps input
              SizedBox(
                width: 120,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  controller: _repsController,
                  onChanged: (value) {
                    final reps = int.tryParse(value) ?? 10;
                    setState(() {
                      repetitions = reps.clamp(1, 30);
                    });
                  },
                ),
              ),
            ],
          ),

          //const Spacer(),
          const SizedBox(width: 40),
          // Submit button on the right
          SizedBox(
            height: 60,
            child: FilledButton.icon(
              label: const Text('Submit'),
              icon: const Icon(Icons.send),
              onPressed: () async {
                double newWeight =
                    weightKg.toDouble() + weightDg.toDouble() / 100.0;

                setState(() {
                  // Loading state if needed
                });

                final result = await addSet(
                  widget.exerciseName,
                  newWeight,
                  repetitions,
                  _selected.first.index,
                  dateInputController.text,
                );

                if (result == 0) {
                  _updateTextsWithData(_todaysTrainingSets);
                  lastActivity = DateTime.now();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Training set saved successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } else {
                  print('Submit failed - training set not saved');
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrainingSetsList() {
    return _isLoadingTrainingSets
        ? const Center(child: CircularProgressIndicator())
        : _todaysTrainingSets.isNotEmpty
            ? ListView.builder(
                controller: _scrollController,
                itemCount: _todaysTrainingSets.length,
                itemBuilder: (context, index) {
                  final item = _todaysTrainingSets[index];
                  return ListTile(
                    leading: CircleAvatar(
                        radius: 17.5, child: FaIcon(workIcons[item.setType])),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    title:
                        Text("${item.weight}kg for ${item.repetitions} reps"),
                    subtitle: Text(
                        "${item.date.hour}:${item.date.minute}:${item.date.second}"),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          // Delete training set (this already updates cache and graph efficiently)
                          await _deleteTrainingSet(item);
                        }),
                  );
                })
            : ListView(
                controller: _scrollController,
                children: const [
                  ListTile(title: Text("No Training yet.")),
                ],
              );
  }

  // Efficiently update graph with a single new training set
  void _updateGraphFromSingleNewSet(ApiTrainingSet newSet) {
    try {
      // Only update if this is a work set (not warmup)
      if (newSet.setType == 0) return;

      final dateKey =
          "${newSet.date.year}-${newSet.date.month.toString().padLeft(2, '0')}-${newSet.date.day.toString().padLeft(2, '0')}";
      final today = DateTime.now();
      final todayKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // If this is today's set, update the graph
      if (dateKey == todayKey) {
        // Find if we already have a point for today
        final todayIndex = trainingGraphs[0].indexWhere((spot) => spot.x == 0);
        final score = globals.calculateScore(newSet);

        if (todayIndex != -1) {
          // Update existing point if this set is better
          if (score > trainingGraphs[0][todayIndex].y) {
            trainingGraphs[0][todayIndex] = FlSpot(0, score);
            graphToolTip[0] = [
              "${newSet.weight}kg @ ${newSet.repetitions}reps"
            ];
          }
        } else {
          // Add new point for today
          trainingGraphs[0].add(FlSpot(0, score));
          graphToolTip[0] = ["${newSet.weight}kg @ ${newSet.repetitions}reps"];
        }

        // Update bar data and UI
        _updateBarDataFromTrainingGraphs();
        setState(() {
          // Graph updated
        });
      }
    } catch (e) {
      print('Error updating graph with new set: $e');
      // Fallback to full graph update if needed
      updateGraph();
    }
  }
}
