/// Statistics Screen - Workout Analytics and Progress Visualization
///
/// This screen provides comprehensive workout analytics and progress tracking
/// through various charts, graphs, and statistical visualizations using fl_chart.
///
/// Key features:
/// - Muscle group activation bar charts and heatmaps
/// - Training volume analysis over time
/// - One Rep Max (1RM) progression tracking
/// - Exercise-specific performance metrics
/// - Weekly/monthly workout frequency analysis
/// - Visual progress indicators and trend analysis
/// - Customizable date ranges for data analysis
/// - Interactive charts with detailed data points
/// - Muscle group balance assessment
/// - Training load distribution visualization
///
/// The screen helps users understand their training patterns, identify
/// imbalances, track progress, and make data-driven decisions about their
/// fitness routines through comprehensive visual analytics.
library;

// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:file_picker/file_picker.dart';
import 'globals.dart' as globals;
import 'package:time_machine/time_machine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tuple/tuple.dart';
import 'dart:math';
import 'user_service.dart';
import 'api_models.dart';
import 'responsive_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreen();
}

const List<String> barChartMuscleNames = [
  "Pecs",
  "Trapz",
  "Biceps",
  "Abs",
  "Front-D",
  "Delts",
  "Back-D",
  "Lats",
  "Triceps",
  "Glutes",
  "Hams",
  "Quads",
  "Arms",
  "Calves",
];

const List<Color> barChartMuscleColors = [
  Color.fromARGB(255, 166, 206, 227),
  Color.fromARGB(255, 202, 178, 214),
  Color.fromARGB(255, 178, 223, 138),
  Color.fromARGB(255, 51, 160, 44),
  Color.fromARGB(255, 251, 154, 153),
  Color.fromARGB(255, 251, 154, 153),
  Color.fromARGB(255, 251, 154, 153),
  Color.fromARGB(255, 31, 120, 180),
  Color.fromARGB(255, 227, 26, 28),
  Color.fromARGB(255, 255, 127, 0),
  Color.fromARGB(255, 253, 191, 111),
  Color.fromARGB(255, 106, 61, 154),
  Color.fromARGB(255, 255, 255, 153),
  Color.fromARGB(255, 177, 89, 40),
];

TextStyle subStyle =
    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0);

class _StatisticsScreen extends State<StatisticsScreen> {
  // overall variables
  int numberOfTrainingDays = 0;
  String trainingDuration = "";
  List<String> trainingDates = [];
  List<LineChartBarData> trainingsPerWeekChart = [];
  List<BarChartGroupData> barChartStatistics = [];
  List<Text> exerciseDetails = [];
  String? startingDate;
  String? endingDate;
  // Add temporary variables for the selected dates before confirmation
  String? _tempStartingDate;
  String? _tempEndingDate;
  List<double> heatMapMulti = [];
  bool isLoading = true;
  // ignore: non_constant_identifier_names
  final TextEditingController MuscleController = TextEditingController();
  final UserService userService = UserService();

  // Caching variables to prevent redundant API calls
  // This solves the issue of thousands of "Enriched training set" debug messages
  // when adjusting date intervals by avoiding repeated API calls for the same data
  List<Map<String, dynamic>>? _cachedTrainingSets;
  List<ApiExercise>? _cachedExercises;
  bool _dataCacheValid = false;
  DateTime? _lastCacheTime;
  List<List<double>> heatMapCood = [
    [0.25, 0.73], //pectoralis
    [0.75, 0.80], // trapezius
    [0.37, 0.68], // biceps
    [0.25, 0.59], // abs
    [0.36, 0.79], //Front delts
    [0.64, 0.85], //Side Delts
    [0.64, 0.75], //Back Delts
    [0.74, 0.65], //latiss
    [0.61, 0.68], //tri
    [0.74, 0.50], //glut
    [0.71, 0.40], //ham
    [0.29, 0.41], //quad
    [0.4, 0.57], //fore
    [0.31, 0.20], //calv
  ];

  void updateView() {}

  // Cache invalidation method
  void _invalidateCache() {
    _cachedTrainingSets = null;
    _cachedExercises = null;
    _dataCacheValid = false;
    _lastCacheTime = null;
    print('Data cache invalidated');
  }

  // Check if cache is expired (5 minutes for freshness)
  bool _isCacheExpired() {
    if (_lastCacheTime == null) return true;
    return DateTime.now().difference(_lastCacheTime!).inMinutes > 5;
  }

  // Smart data loading with caching
  Future<List<Map<String, dynamic>>> _getTrainingSetsWithCache() async {
    if (_cachedTrainingSets == null || !_dataCacheValid || _isCacheExpired()) {
      print('Loading training sets from API...');
      final rawData = await userService.getTrainingSets();
      _cachedTrainingSets = rawData.cast<Map<String, dynamic>>();
      _dataCacheValid = true;
      _lastCacheTime = DateTime.now();
    } else {
      print('Using cached training sets');
    }
    return _cachedTrainingSets!;
  }

  Future<List<ApiExercise>> _getExercisesWithCache() async {
    if (_cachedExercises == null || !_dataCacheValid || _isCacheExpired()) {
      print('Loading exercises from API...');
      final exercisesData = await userService.getExercises();
      _cachedExercises =
          exercisesData.map((e) => ApiExercise.fromJson(e)).toList();
      _dataCacheValid = true;
      _lastCacheTime = DateTime.now();
    } else {
      print('Using cached exercises');
    }
    return _cachedExercises!;
  }

  int weekNumber(DateTime date) {
    // Use a more reliable week number calculation
    // This calculates the ISO week number (week 1 is the first week with Thursday)
    DateTime jan1 = DateTime(date.year, 1, 1);
    int dayOfYear = date.difference(jan1).inDays + 1;
    int weekDay = jan1.weekday;

    // Adjust for ISO week calculation
    int week = ((dayOfYear - date.weekday + 10) / 7).floor();

    // Handle edge cases for year boundaries
    if (week < 1) {
      return weekNumber(DateTime(date.year - 1, 12, 31));
    } else if (week > 52) {
      DateTime dec31 = DateTime(date.year, 12, 31);
      if (dec31.weekday < 4) {
        return 1; // This week belongs to next year
      }
    }

    return week;
  }

  BarChartGroupData generateBars(
      int x, List<double> rations, List<Color> colors) {
    List<BarChartRodData> bars = [];
    for (var i = 0; i < rations.length - 1; ++i) {
      bars.add(BarChartRodData(
          fromY: rations[i],
          toY: rations[i + 1],
          color: colors[i],
          borderRadius: const BorderRadius.horizontal()));
    }
    return BarChartGroupData(x: x, groupVertically: true, barRods: bars);
  }

  // Add a new variable to track whether to use default filtering
  bool _useDefaultDateFilter = true;

  // Modify the _loadStatistics method
  Future<void> _loadStatistics() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get all training sets from UserService with caching
      final allTrainingSets = await _getTrainingSetsWithCache();

      // Check if we have any training sets at all
      if (allTrainingSets.isEmpty) {
        setState(() {
          isLoading = false;
          numberOfTrainingDays = 0;
          trainingDuration = "No training data available";
          trainingDates.clear();
          trainingsPerWeekChart.clear();
          barChartStatistics.clear();
          heatMapMulti.clear();
        });
        return;
      }

      // Extract unique training dates
      Set<DateTime> uniqueDates = {};
      for (var trainingSet in allTrainingSets) {
        try {
          final date = DateTime.parse(trainingSet['date']);
          // Only count work sets (set_type > 0), not warmups
          if (trainingSet['set_type'] > 0) {
            uniqueDates.add(DateTime(date.year, date.month, date.day));
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
      }

      List<DateTime> _trainingDates = uniqueDates.toList()..sort();

      // Set all training dates for dropdown menus (not filtered)
      trainingDates.clear();
      for (var d in _trainingDates) {
        trainingDates.add(DateFormat('dd-MM-yyyy').format(d));
      }

      // Apply date filtering to training dates for calculations
      List<DateTime> filteredTrainingDates = List.from(_trainingDates);

      // Track original length for snackbar message
      int originalLength = filteredTrainingDates.length;

      // If no custom dates are set and we should use default filter, use last 30 training dates
      if (_useDefaultDateFilter && startingDate == null && endingDate == null) {
        if (filteredTrainingDates.length > 30) {
          filteredTrainingDates =
              filteredTrainingDates.sublist(filteredTrainingDates.length - 30);

          // Show snackbar informing user about the 30-day limit
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Showing last 30 training days (${originalLength} total available)'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.blue.shade600,
                ),
              );
            });
          }
        } else {
          // Show snackbar informing user about all days being loaded
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Showing all ${originalLength} training days'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            });
          }
        }
      } else {
        // Apply custom date filtering
        if (startingDate != null) {
          var tokens = startingDate!.split("-");
          String startingDateString =
              "${tokens[2]}-${tokens[1]}-${tokens[0]}T00:00:00";
          DateTime start = DateTime.parse(startingDateString);
          filteredTrainingDates = filteredTrainingDates
              .where((d) => d.isAfter(start) || d.isAtSameMomentAs(start))
              .toList();
        }
        if (endingDate != null) {
          var tokens = endingDate!.split("-");
          String endingDateString =
              "${tokens[2]}-${tokens[1]}-${tokens[0]}T00:00:00";
          DateTime end = DateTime.parse(endingDateString);
          filteredTrainingDates = filteredTrainingDates
              .where((d) => d.isBefore(end) || d.isAtSameMomentAs(end))
              .toList();
        }
      }

      // Use filtered dates for calculations
      numberOfTrainingDays = filteredTrainingDates.length;
      if (numberOfTrainingDays == 0) {
        setState(() {
          isLoading = false;
          trainingDuration = "No work sets found in selected date range";
          trainingsPerWeekChart.clear();
          barChartStatistics.clear();
          heatMapMulti.clear();
        });
        return;
      }

      Period diff = LocalDate.dateTime(filteredTrainingDates.last)
          .periodSince(LocalDate.dateTime(filteredTrainingDates.first));
      trainingDuration =
          "Over the period of ${diff.months} month and ${diff.days} days";

      // Create a map to count trainings per week using filtered dates
      Map<int, int> trainingsPerWeekMap = {};

      for (var date in filteredTrainingDates) {
        int week = weekNumber(date);
        int year = date.year;
        // Create a unique key combining year and week to handle year boundaries
        int weekKey = year * 100 + week;

        trainingsPerWeekMap[weekKey] = (trainingsPerWeekMap[weekKey] ?? 0) + 1;
      }

      // Sort week keys and create continuous data
      List<int> sortedWeekKeys = trainingsPerWeekMap.keys.toList()..sort();

      if (sortedWeekKeys.isEmpty) {
        setState(() {
          isLoading = false;
          trainingsPerWeekChart.clear();
        });
        return;
      }

      // Create spots for the line chart
      List<FlSpot> spots = [];
      for (int i = 0; i < sortedWeekKeys.length; i++) {
        int weekKey = sortedWeekKeys[i];
        int count = trainingsPerWeekMap[weekKey] ?? 0;
        spots.add(FlSpot(i.toDouble(), count.toDouble()));
      }

      trainingsPerWeekChart.clear();
      trainingsPerWeekChart.add(LineChartBarData(
        spots: spots,
        isCurved: false,
        color: Colors.blue,
        barWidth: 2,
        isStrokeCapRound: true,
        belowBarData: BarAreaData(show: false),
        dotData: const FlDotData(show: true),
      ));

      await updateBarStatistics();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        isLoading = false;
        numberOfTrainingDays = 0;
        trainingDuration = "Error loading data";
        trainingDates.clear();
        trainingsPerWeekChart.clear();
        barChartStatistics.clear();
        heatMapMulti.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  // Modify the updateBarStatistics method to use the same filtering logic
  Future<void> updateBarStatistics() async {
    // determine mapping of muscle groups to scores
    Map<String, int> muscleMapping = {
      "Pectoralis major": 0,
      "Trapezius": 1,
      "Biceps": 2,
      "Abdominals": 3,
      "Front Delts": 4,
      "Deltoids": 5,
      "Back Delts": 6,
      "Latissimus dorsi": 7,
      "Triceps": 8,
      "Gluteus maximus": 9,
      "Hamstrings": 10,
      "Quadriceps": 11,
      "Forearms": 12,
      "Calves": 13,
    };

    try {
      // Use cached data to prevent redundant API calls
      final exercises = await _getExercisesWithCache();

      Map<String, List<Tuple2<int, double>>> exerciseMapping = {};
      for (var e in exercises) {
        List<Tuple2<int, double>> intermediateMap = [];
        for (int i = 0; i < e.muscleGroups.length; ++i) {
          String which = e.muscleGroups[i];
          var val = muscleMapping[which];
          if (val != null) {
            intermediateMap
                .add(Tuple2<int, double>(val, e.muscleIntensities[i]));
          }
        }
        exerciseMapping[e.name] = intermediateMap;
      }

      // Get all training sets instead of using db functions
      final allTrainingSets = await _getTrainingSetsWithCache();

      // Extract unique training dates
      Set<DateTime> uniqueDates = {};
      for (var trainingSet in allTrainingSets) {
        try {
          final date = DateTime.parse(trainingSet['date']);
          // Only count work sets (set_type > 0), not warmups
          if (trainingSet['set_type'] > 0) {
            uniqueDates.add(DateTime(date.year, date.month, date.day));
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
      }

      List<DateTime> allTrainingDates = uniqueDates.toList()..sort();

      // Apply the same filtering logic as in _loadStatistics
      List<DateTime> filteredTrainingDates = List.from(allTrainingDates);

      // If no custom dates are set and we should use default filter, use last 30 training dates
      if (_useDefaultDateFilter && startingDate == null && endingDate == null) {
        if (filteredTrainingDates.length > 30) {
          filteredTrainingDates =
              filteredTrainingDates.sublist(filteredTrainingDates.length - 30);
        }
      } else {
        // Apply custom date filtering
        if (startingDate != null) {
          var tokens = startingDate!.split("-");
          String startingDateString =
              "${tokens[2]}-${tokens[1]}-${tokens[0]}T00:00:00";
          DateTime start = DateTime.parse(startingDateString);
          filteredTrainingDates = filteredTrainingDates
              .where((d) => d.isAfter(start) || d.isAtSameMomentAs(start))
              .toList();
        }
        if (endingDate != null) {
          var tokens = endingDate!.split("-");
          String endingDateString =
              "${tokens[2]}-${tokens[1]}-${tokens[0]}T00:00:00";
          DateTime end = DateTime.parse(endingDateString);
          filteredTrainingDates = filteredTrainingDates
              .where((d) => d.isBefore(end) || d.isAtSameMomentAs(end))
              .toList();
        }
      }

      // Use filtered dates for calculations
      List<List<double>> muscleHistoryScore = [];
      for (var day in filteredTrainingDates) {
        // Filter training sets for this specific day
        var dayTrainingSets = allTrainingSets.where((trainingSet) {
          try {
            final date = DateTime.parse(trainingSet['date']);
            return date.year == day.year &&
                date.month == day.month &&
                date.day == day.day &&
                trainingSet['set_type'] > 0; // Only count work sets
          } catch (e) {
            return false;
          }
        }).toList();

        List<double> dailyMuscleScores = List.filled(14, 0.0);

        for (var trainingSet in dayTrainingSets) {
          // Use exercise_name from the enriched training set
          String? exerciseName = trainingSet['exercise_name'];
          if (exerciseName != null) {
            List<Tuple2<int, double>>? muscleInvolved =
                exerciseMapping[exerciseName];
            if (muscleInvolved != null) {
              for (Tuple2<int, double> pair in muscleInvolved) {
                if (pair.item1 < dailyMuscleScores.length) {
                  dailyMuscleScores[pair.item1] += pair.item2;
                }
              }
            }
          }
        }
        muscleHistoryScore.add(dailyMuscleScores);
      }

      // Clear and rebuild chart data
      barChartStatistics.clear();
      for (var i = 0; i < muscleHistoryScore.length; ++i) {
        var currentScore = muscleHistoryScore[i];
        List<double> accumulatedScore = [0.0];
        for (var d in currentScore) {
          accumulatedScore.add(accumulatedScore.last + d);
        }
        barChartStatistics
            .add(generateBars(i, accumulatedScore, barChartMuscleColors));
      }
      globals.muscleHistoryScore = muscleHistoryScore;

      // Trigger UI update
      if (mounted) {
        setState(() {
          // Data has been updated
        });
      }
    } catch (e) {
      print('Error updating bar statistics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating statistics: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStatistics();

    // Listen for route changes to refresh data when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Add a listener to refresh when data might have changed
        userService.authStateNotifier.addListener(_onDataChanged);
      }
    });
  }

  @override
  void dispose() {
    userService.authStateNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      // Invalidate cache when data changes externally (e.g., new workouts added)
      _invalidateCache();
      _loadStatistics();
    }
  }

  // Add this variable to track if it's the first time didChangeDependencies is called
  bool _isFirstDidChangeDependencies = true;

  // Add this method to be called when navigating back to the screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Skip the first call since initState already loads the data
    if (_isFirstDidChangeDependencies) {
      _isFirstDidChangeDependencies = false;
      return;
    }

    // Only invalidate cache and refresh data when navigating back from other screens
    if (mounted) {
      _invalidateCache();
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios,
            ),
          ),
          title: const Text("Statistics"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Handle empty data case
    if (numberOfTrainingDays == 0) {
      return Scaffold(
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios,
            ),
          ),
          title: const Text("Statistics"),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                "No training data available",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                "Start adding workouts to see your statistics",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    List<List> muscleHistoryScore = globals.muscleHistoryScore;

    List<double> muscleHistoryScoreCum = [];
    if (muscleHistoryScore.isNotEmpty && muscleHistoryScore[0].isNotEmpty) {
      for (int i = 0; i < muscleHistoryScore[0].length; i++) {
        double item = 0;
        for (int j = 0; j < muscleHistoryScore.length; j++) {
          if (i < muscleHistoryScore[j].length) {
            item = item + muscleHistoryScore[j][i];
          }
        }
        muscleHistoryScoreCum.add(item);
      }

      if (muscleHistoryScoreCum.isNotEmpty) {
        var highestValue = muscleHistoryScoreCum.reduce(max);
        heatMapMulti = [];
        for (int i = 0; i < muscleHistoryScoreCum.length; i++) {
          heatMapMulti.add(
              highestValue > 0 ? muscleHistoryScoreCum[i] / highestValue : 0.0);
        }
      }
    } else {
      // Initialize empty heatmap data
      heatMapMulti = List.filled(14, 0.0);
    }

    //print(highestValue);
    //print(globals.muscleHistoryScore);
    //print(heatMapCood);
    //print(heatMapMulti);
    return Scaffold(
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios,
            ),
          ),
          title: const Text("Statistics"),
        ),
        body: ResponsiveHelper.isMobile(context)
            ? MobileStatisticsLayout(context)
            : DesktopStatisticsLayout(context));
  }

  ListView MobileStatisticsLayout(BuildContext context) {
    return ListView(children: <Widget>[
      Text(
        "Selected Training Interval",
        style: subStyle,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 5),
      DatePicker(),
      const SizedBox(height: 20),
      StatisticTexts(),
      const Divider(),
      Text(
        "Number of Trainings per Week",
        style: subStyle,
        textAlign: TextAlign.center,
      ),
      SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.15,
          child: Padding(
            padding: const EdgeInsets.only(
                right: 10.0,
                top: 15.0,
                left: 0.0), // Hier das Padding rechts hinzufügen
            child: TrainingsPerWeekChart(),
          )),
      const SizedBox(height: 20),
      Text(
        "Muscle usage per Exercise",
        style: subStyle,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 5),
      MusclesPerExerciseChart(context),
      const SizedBox(
        height: 20,
      ),
      Text(
        "Heatmap: relative to most used muscle",
        style: subStyle,
        textAlign: TextAlign.center,
      ),
      const SizedBox(
        height: 20,
      ),
      MuscleHeatMap(context, (MediaQuery.of(context).size.width * 0.8),
          (MediaQuery.of(context).size.height)),
    ]);
  }

  Widget DesktopStatisticsLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - 1/3 of screen width
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DatePicker at the top
                Text(
                  "Selected Training Interval",
                  style: subStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                DatePicker(),
                const SizedBox(height: 20),
                const Divider(),

                // List of selectable widgets
                Text(
                  "Statistics Views",
                  style: subStyle,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      _buildListTile("Statistics Overview", 0),
                      _buildListTile("Trainings per Week", 1),
                      _buildListTile("Muscle Usage per Exercise", 2),
                      _buildListTile("Muscle Heatmap", 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right side - 2/3 of screen width
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: _buildSelectedWidget(),
          ),
        ),
      ],
    );
  }

  // Add this new variable to track selected widget
  int _selectedWidgetIndex = 0;

  // Add this method to build list tiles
  Widget _buildListTile(String title, int index) {
    return ListTile(
      title: Text(title),
      selected: _selectedWidgetIndex == index,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedWidgetIndex = index;
        });
      },
      trailing: _selectedWidgetIndex == index
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
    );
  }

  // Add this method to build the selected widget
  Widget _buildSelectedWidget() {
    switch (_selectedWidgetIndex) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Statistics Overview",
              style: subStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            StatisticTexts(),
          ],
        );
      case 1:
        return Column(
          children: [
            Text(
              "Number of Trainings per Week",
              style: subStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(right: 10.0, top: 15.0, left: 0.0),
                child: TrainingsPerWeekChart(),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            Text(
              "Muscle usage per Exercise",
              style: subStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: MusclesPerExerciseChart(context),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Text(
              "Heatmap: relative to most used muscle",
              style: subStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: MuscleHeatMap(context, 400, 600),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  Center MuscleHeatMap(BuildContext context, double width, double height) {
    return Center(
      child: SizedBox(
        width: width, height: height, // Adjust size as needed
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use the available space from the parent container
            double availableHeight = constraints.maxHeight;
            double availableWidth = constraints.maxWidth;
            print(availableHeight);
            print(availableWidth);
            // Calculate appropriate dimensions while maintaining aspect ratio
            double imageWidth = availableWidth * 0.5;
            double imageHeight = availableHeight;
            double totalImageWidth = imageWidth * 2; // Two images side by side

            // Ensure we don't exceed available space
            if (totalImageWidth > availableWidth * 0.8) {
              imageWidth = (availableWidth * 0.8) / 2;
            }

            return Stack(
              //fit: StackFit.expand,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scaleX: -1,
                      child: Image(
                        fit: BoxFit.fill,
                        width: imageWidth,
                        height: imageHeight,
                        image: const AssetImage('images/muscles/Front_bg.png'),
                      ),
                    ),
                    Image(
                      fit: BoxFit.fill,
                      width: imageWidth,
                      height: imageHeight,
                      image: const AssetImage('images/muscles/Back_bg.png'),
                    ),
                  ],
                ),
                for (int i = 0; i < heatMapMulti.length; i++)
                  heatDot(
                    text: "${(heatMapMulti[i] * 100).round()}%",
                    x: (availableWidth * heatMapCood[i][0]) -
                        ((30 + (50 * heatMapMulti[i])) / 2),
                    y: (availableHeight * heatMapCood[i][1]) -
                        ((30 + (50 * heatMapMulti[i])) / 2),
                    dia: 30 + (50 * heatMapMulti[i]),
                    opa: heatMapMulti[i] == 0 ? 0 : 200,
                    lerp: heatMapMulti[i],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Column MusclesPerExerciseChart(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: (() {
            List<Widget> widgets = [];
            for (int i = 0; i < barChartMuscleColors.length / 2; i++) {
              widgets.add(Wrap(children: [
                Container(
                    width: 14.0, height: 14.0, color: barChartMuscleColors[i]),
                Text(" ${barChartMuscleNames[i]}",
                    style: const TextStyle(fontSize: 10.0))
              ]));
              // widgets.add(Text(barChartMuscleNames[i]));
            }
            return widgets;
          })(),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: (() {
            List<Widget> widgets = [];
            for (int i = barChartMuscleColors.length ~/ 2;
                i < barChartMuscleColors.length;
                i++) {
              widgets.add(Wrap(children: [
                Container(
                    width: 14.0, height: 14.0, color: barChartMuscleColors[i]),
                Text(" ${barChartMuscleNames[i]}",
                    style: const TextStyle(fontSize: 10.0))
              ]));
              // widgets.add(Text(barChartMuscleNames[i]));
            }
            return widgets;
          })(),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: ResponsiveHelper.isMobile(context)
              ? MediaQuery.of(context).size.height * 0.25
              : MediaQuery.of(context).size.height * 0.65,
          child: Padding(
            padding: const EdgeInsets.only(
                right: 10.0,
                top: 5.0,
                left: 10.0), // Hier das Padding rechts hinzufügen
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                titlesData: const FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  // bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: barChartStatistics,
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: (() {
            List<Widget> widgets = [];
            for (var d in exerciseDetails) {
              widgets.add(d);
            }
            return widgets;
          })(),
        ),
      ],
    );
  }

  LineChart TrainingsPerWeekChart() {
    return LineChart(LineChartData(
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
          )),
        ),
        lineBarsData: trainingsPerWeekChart,
        maxY: 7,
        minY: 0));
  }

  Column StatisticTexts() {
    return Column(
      children: [
        Text("Number of training days: $numberOfTrainingDays",
            style: subStyle, textAlign: TextAlign.center),
        Text(trainingDuration, style: subStyle, textAlign: TextAlign.center),
      ],
    );
  }

  // Modify the Confirm button in DatePicker to disable default filtering
  Row DatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 16),
        // Left side - dropdowns with constraints
        Flexible(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 250,
              maxWidth: 400,
            ),
            child: Column(
              children: [
                DropdownMenu<String>(
                  label: const Text("Start Date"),
                  onSelected: (String? date) {
                    _tempStartingDate = date;
                  },
                  dropdownMenuEntries: trainingDates
                      .map<DropdownMenuEntry<String>>((String name) {
                    return DropdownMenuEntry<String>(value: name, label: name);
                  }).toList(),
                  menuHeight: 200,
                  inputDecorationTheme: InputDecorationTheme(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    constraints:
                        BoxConstraints.tight(const Size.fromHeight(40)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownMenu<String>(
                  label: const Text("End Date"),
                  onSelected: (String? date) {
                    _tempEndingDate = date;
                  },
                  dropdownMenuEntries: trainingDates
                      .map<DropdownMenuEntry<String>>((String name) {
                    return DropdownMenuEntry<String>(value: name, label: name);
                  }).toList(),
                  menuHeight: 200,
                  inputDecorationTheme: InputDecorationTheme(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    constraints:
                        BoxConstraints.tight(const Size.fromHeight(40)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Right side - button with constraints
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 80,
            maxWidth: 120,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 25),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  startingDate = _tempStartingDate;
                  endingDate = _tempEndingDate;
                  // Disable default filtering when user selects custom dates
                  _useDefaultDateFilter = false;
                });
                // Call _loadStatistics() instead of just updateBarStatistics()
                // This will update both the line chart and bar chart with the new date filters
                _loadStatistics();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Confirm"),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

// ignore: camel_case_types
class heatDot extends StatelessWidget {
  const heatDot({
    super.key,
    required this.y,
    required this.x,
    required this.dia,
    required this.opa,
    required this.lerp,
    required this.text,
  });

  final double y;
  final double x;
  final double dia;
  final int opa;
  final double lerp;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: y,
      left: x,
      child: Container(
        width: dia,
        height: dia,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(Color.fromARGB(opa, 255, 200, 50),
                Color.fromARGB(opa, 255, 30, 50), lerp)),
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
