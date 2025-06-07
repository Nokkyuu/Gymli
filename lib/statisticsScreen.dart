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
import 'package:time_machine/time_machine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'user_service.dart';
import 'api_models.dart';
import 'responsive_helper.dart';
//import 'screens/statistics/constants/muscle_constants.dart';
//import 'screens/statistics/constants/chart_constants.dart';
import 'screens/statistics/services/statistics_data_service.dart';
import 'screens/statistics/services/statistics_filter_service.dart';
import 'screens/statistics/services/statistics_calculation_service.dart';
import 'screens/statistics/services/statistics_coordinator.dart';
import 'screens/statistics/widgets/food.dart';
import 'screens/statistics/widgets/calorie_balance.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreen();
}

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
  List<List<double>> _muscleHistoryScore = [];
  bool isLoading = true;
  // ignore: non_constant_identifier_names
  final TextEditingController MuscleController = TextEditingController();
  final UserService userService = UserService();

  // Service instances for data management and calculations
  late final StatisticsDataService _dataService;
  late final StatisticsFilterService _filterService;
  late final StatisticsCalculationService _calculationService;
  late final StatisticsCoordinator _coordinator;

  // Equipment usage count variables
  int _freeWeightsCount = 0;
  int _machinesCount = 0;
  int _cablesCount = 0;
  int _bodyweightCount = 0;

  // Activity-related variables for _buildActivitiesView
  Map<String, dynamic> _activityStats = {};
  List<FlSpot> _caloriesTrendData = [];
  List<FlSpot> _durationTrendData = [];
  bool _isLoadingActivityData = false;
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

  // Method to calculate equipment usage counts from training sets
  Future<void> _calculateEquipmentUsage() async {
    try {
      final result = await _coordinator.getEquipmentUsage(
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: _useDefaultDateFilter,
      );

      setState(() {
        _freeWeightsCount = result['freeWeights'] ?? 0;
        _machinesCount = result['machines'] ?? 0;
        _cablesCount = result['cables'] ?? 0;
        _bodyweightCount = result['bodyweight'] ?? 0;
      });

      print(
          'Equipment usage calculated: Free: $_freeWeightsCount, Machine: $_machinesCount, Cable: $_cablesCount, Bodyweight: $_bodyweightCount');
    } catch (e) {
      print('Error calculating equipment usage: $e');
      setState(() {
        _freeWeightsCount = 0;
        _machinesCount = 0;
        _cablesCount = 0;
        _bodyweightCount = 0;
      });
    }
  }

  int weekNumber(DateTime date) {
    // Use a more reliable week number calculation
    // This calculates the ISO week number (week 1 is the first week with Thursday)
    DateTime jan1 = DateTime(date.year, 1, 1);
    int dayOfYear = date.difference(jan1).inDays + 1;

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

  // Exercise graph variables
  List<ApiExercise> _availableExercises = [];
  String? _selectedExerciseForGraph;
  List<LineChartBarData> _exerciseGraphData = [];
  Map<int, List<String>> _exerciseGraphTooltip = {};
  double _exerciseGraphMinScore = 0;
  double _exerciseGraphMaxScore = 100;
  double _exerciseGraphMaxHistoryDistance = 90;
  DateTime? _exerciseGraphMostRecentDate;

  // Load all statistics data using the extracted services
  Future<void> _loadStatistics() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get all training sets from data service
      final allTrainingSets = await _dataService.getTrainingSets();

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
          _muscleHistoryScore.clear();
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

      // Create the filter and apply using FilterService
      final filteredTrainingDates = _filterService.filterTrainingDates(
        trainingDates: _trainingDates,
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: _useDefaultDateFilter,
      );

      // Show snackbar if default filter was applied
      if (_filterService.shouldShowFilterNotification(
            originalCount: _trainingDates.length,
            filteredCount: filteredTrainingDates.length,
            useDefaultFilter: _useDefaultDateFilter,
            startingDate: startingDate,
            endingDate: endingDate,
          ) &&
          mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_filterService.getFilterNotificationMessage(
                filteredCount: filteredTrainingDates.length,
                originalCount: _trainingDates.length,
              )),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.blue.shade600,
            ),
          );
        });
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
      DateTime startDate;
      DateTime endDate;
      if (_useDefaultDateFilter) {
        // Use the default 3-month range
        endDate = DateTime.now();
        startDate = endDate.subtract(const Duration(days: 90));
      } else {
        // Use the selected dates from date picker
        startDate = startingDate != null
            ? _parseDate(startingDate!)
            : DateTime.now().subtract(const Duration(days: 90));
        endDate = endingDate != null ? _parseDate(endingDate!) : DateTime.now();
      }

      Period diff = LocalDate.dateTime(endDate!)
          .periodSince(LocalDate.dateTime(startDate!));
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

      await _updateBarStatisticsFromCoordinator();

      // Load activity data with the same date filters
      await _loadActivityDataFromCoordinator();

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

  // Helper method to update bar statistics using coordinator
  Future<void> _updateBarStatisticsFromCoordinator() async {
    try {
      final result = await _coordinator.calculateBarStatistics(
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: _useDefaultDateFilter,
      );

      // Update class members with the results
      _muscleHistoryScore = result.muscleHistoryScore;
      barChartStatistics = result.barChartStatistics.isEmpty
          ? []
          : result.barChartStatistics.last;
      heatMapMulti = result.heatMapData;

      // Calculate equipment usage counts
      await _calculateEquipmentUsage();

      // Trigger UI update
      if (mounted) {
        setState(() {
          // Data has been updated
        });
      }
    } catch (e) {
      print('Error updating bar statistics from coordinator: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating statistics: $e')),
        );
      }
    }
  }

  // Helper method to load activity data using coordinator
  Future<void> _loadActivityDataFromCoordinator() async {
    setState(() {
      _isLoadingActivityData = true;
    });

    try {
      final result = await _coordinator.loadActivityData(
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: _useDefaultDateFilter,
      );

      setState(() {
        _activityStats = result.activityStats;
        _caloriesTrendData = result.caloriesTrendData;
        _durationTrendData = result.durationTrendData;
        _isLoadingActivityData = false;
      });
    } catch (e) {
      print('Error loading activity data from coordinator: $e');
      setState(() {
        _activityStats = {};
        _caloriesTrendData = [];
        _durationTrendData = [];
        _isLoadingActivityData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activity data: $e')),
        );
      }
    }
  }

  // Helper method to load exercise graph data using coordinator
  Future<void> _loadExerciseGraphDataFromCoordinator(
      String exerciseName) async {
    try {
      final result = await _coordinator.loadExerciseGraphData(
        exerciseName: exerciseName,
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: _useDefaultDateFilter,
      );

      setState(() {
        _exerciseGraphData = result.graphData;
        _exerciseGraphTooltip = result.tooltipData;
        _exerciseGraphMinScore = result.minScore;
        _exerciseGraphMaxScore = result.maxScore;
        _exerciseGraphMaxHistoryDistance = result.maxHistoryDistance;
        _exerciseGraphMostRecentDate = result.mostRecentDate;
      });
    } catch (e) {
      print('Error loading exercise graph data from coordinator: $e');
      setState(() {
        _exerciseGraphData = [];
        _exerciseGraphTooltip = {};
        _exerciseGraphMinScore = 0;
        _exerciseGraphMaxScore = 100;
        _exerciseGraphMaxHistoryDistance = 90;
        _exerciseGraphMostRecentDate = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exercise graph data: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize services
    _dataService = StatisticsDataService(userService);
    _filterService = StatisticsFilterService();
    _calculationService = StatisticsCalculationService();
    _coordinator = StatisticsCoordinator(
      dataService: _dataService,
      calculationService: _calculationService,
      filterService: _filterService,
    );

    // Initialize date picker with default 3-month range when using default filter
    if (_useDefaultDateFilter) {
      final now = DateTime.now();
      final threeMonthsAgo = now.subtract(const Duration(days: 90));
      _tempStartingDate = DateFormat('dd-MM-yyyy').format(threeMonthsAgo);
      _tempEndingDate = DateFormat('dd-MM-yyyy').format(now);
    }

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
      _dataService.invalidateCache();
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
      _dataService.invalidateCache();
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
        style: ThemeData().textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 5),
      DatePicker(),
      const SizedBox(height: 20),
      StatisticTexts(),
      const Divider(),
      Text(
        "Number of Trainings per Week",
        style: ThemeData().textTheme.bodyMedium,
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
      // Text(
      //   "Muscle usage per Exercise",
      //   style: ThemeData().textTheme.bodyMedium,),
      //   textAlign: TextAlign.center,
      // ),
      const SizedBox(height: 5),
      // MusclesPerExerciseChart(context),
      const SizedBox(
        height: 20,
      ),
      Text(
        "Heatmap: relative to most used muscle",
        style: ThemeData().textTheme.bodyMedium,
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
                  style: ThemeData().textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                DatePicker(),
                const SizedBox(height: 20),
                const Divider(),

                // List of selectable widgets
                Text(
                  "Statistics Views",
                  style: ThemeData().textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      _buildListTile("Statistics Overview", 0),
                      _buildListTile("Trainings per Week", 1),
                      //_buildListTile("Muscle Usage per Exercise", 2),
                      _buildListTile("Muscle Heatmap", 3),
                      _buildListTile("Exercise Progress", 4),
                      _buildListTile("Activities", 5),
                      _buildListTile("Nutrition", 6),
                      _buildListTile("Calorie Balance", 7),
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
          // Load exercises when Exercise Progress is selected
          if (index == 4) {
            _loadAvailableExercises();
          }
          // Load activity data when Activities is selected
          if (index == 5) {
            _loadActivityDataFromCoordinator();
          }
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
              style: ThemeData().textTheme.bodyMedium,
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
              style: ThemeData().textTheme.bodyMedium,
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
      // case 2:
      //   return Column(
      //     children: [
      //       Text(
      //         "Muscle usage per Exercise",
      //         style: ThemeData().textTheme.bodyMedium,),
      //         textAlign: TextAlign.center,
      //       ),
      //       const SizedBox(height: 20),
      //       Expanded(
      //         child: MusclesPerExerciseChart(context),
      //       ),
      //     ],
      //   );
      case 3:
        return Column(
          children: [
            Text(
              "Heatmap: relative to most used muscle",
              style: ThemeData().textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: MuscleHeatMap(context, 400, 600),
            ),
          ],
        );
      case 4:
        return _buildExerciseProgressView();
      case 5:
        return _buildActivitiesView();
      case 6:
        return FoodStatsScreen(
          key: ValueKey('${startingDate}_${endingDate}_$_useDefaultDateFilter'),
          startingDate: startingDate,
          endingDate: endingDate,
          useDefaultDateFilter: _useDefaultDateFilter,
        );
      case 7:
        return CalorieBalanceScreen(
          key: ValueKey('${startingDate}_${endingDate}_$_useDefaultDateFilter'),
          startingDate: startingDate,
          endingDate: endingDate,
          useDefaultDateFilter: _useDefaultDateFilter,
        );
      default:
        return Container();
    }
  }

  // Add this new method for Activities view
  Widget _buildActivitiesView() {
    if (_isLoadingActivityData) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Activities Overview",
            style: ThemeData().textTheme.bodyMedium,
          ),

          const SizedBox(height: 10),
          // Activity statistics cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActivityStatCard("Total Sessions",
                  _activityStats['total_sessions']?.toString() ?? "0"),
              _buildActivityStatCard(
                  "Total Calories", _getCaloriesDisplayValue()),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Trends",
            style: ThemeData().textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          // Calories trend chart
          Text("Calories Burned Over Time"),
          const SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 20, bottom: 20, top: 10),
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: _caloriesTrendData.length > 10
                            ? (_caloriesTrendData.last.x -
                                    _caloriesTrendData.first.x) /
                                5
                            : 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (_caloriesTrendData.isEmpty) return const Text('');

                          // Find the earliest date from the activity logs
                          final dayIndex = value.round();
                          if (dayIndex < 0 ||
                              dayIndex >= _caloriesTrendData.length) {
                            return const Text('');
                          }

                          // Calculate the actual date
                          final DateTime baseDate = DateTime.now().subtract(
                              Duration(
                                  days: (_caloriesTrendData.last.x - value)
                                      .round()));

                          return Transform.rotate(
                            angle: -0.3,
                            child: Text(
                              '${baseDate.day}/${baseDate.month}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: _caloriesTrendData.isNotEmpty
                            ? (_caloriesTrendData.map((e) => e.y).reduce(max) /
                                4)
                            : 50,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _caloriesTrendData,
                      isCurved: false,
                      color: Colors.red,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minX: _caloriesTrendData.isNotEmpty
                      ? _caloriesTrendData.first.x
                      : 0,
                  maxX: _caloriesTrendData.isNotEmpty
                      ? _caloriesTrendData.last.x
                      : 0,
                  minY: 0,
                  maxY: _caloriesTrendData.isNotEmpty
                      ? (_caloriesTrendData.map((e) => e.y).reduce(max) * 1.1)
                      : 100,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Duration trend chart
          Text("Activity Duration Over Time"),
          const SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 20, bottom: 20, top: 10),
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: _durationTrendData.length > 10
                            ? (_durationTrendData.last.x -
                                    _durationTrendData.first.x) /
                                5
                            : 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (_durationTrendData.isEmpty) return const Text('');

                          // Find the earliest date from the activity logs
                          final dayIndex = value.round();
                          if (dayIndex < 0 ||
                              dayIndex >= _durationTrendData.length) {
                            return const Text('');
                          }

                          // Calculate the actual date
                          final DateTime baseDate = DateTime.now().subtract(
                              Duration(
                                  days: (_durationTrendData.last.x - value)
                                      .round()));

                          return Transform.rotate(
                            angle: -0.3,
                            child: Text(
                              '${baseDate.day}/${baseDate.month}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: _durationTrendData.isNotEmpty
                            ? (_durationTrendData.map((e) => e.y).reduce(max) /
                                4)
                            : 20,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '${value.toInt()}m',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _durationTrendData,
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minX: _durationTrendData.isNotEmpty
                      ? _durationTrendData.first.x
                      : 0,
                  maxX: _durationTrendData.isNotEmpty
                      ? _durationTrendData.last.x
                      : 0,
                  minY: 0,
                  maxY: _durationTrendData.isNotEmpty
                      ? (_durationTrendData.map((e) => e.y).reduce(max) * 1.1)
                      : 100,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get properly formatted calories value
  String _getCaloriesDisplayValue() {
    final calories = _activityStats['total_calories_burned'];
    print(
        'Debug - calories value: $calories (type: ${calories.runtimeType})'); // Debug log

    if (calories == null) return "0";

    // Handle both int and double types
    if (calories is num) {
      return calories.toStringAsFixed(0);
    }

    // Fallback - try to parse as string
    final parsed = double.tryParse(calories.toString());
    return parsed?.toStringAsFixed(0) ?? "0";
  }

  // Helper method to build activity statistic cards
  Widget _buildActivityStatCard(String title, String value) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
      spacing: 8,
      children: [
        const SizedBox(height: 10),
        Text("Number of training days: $numberOfTrainingDays",
            style: ThemeData().textTheme.bodyMedium,
            textAlign: TextAlign.center),

        Text(trainingDuration,
            style: ThemeData().textTheme.bodyMedium,
            textAlign: TextAlign.center),
        Text(
            "Used $_freeWeightsCount Free Weights, $_machinesCount Machines, $_cablesCount Cables and $_bodyweightCount Bodyweight Exercises",
            style: ThemeData().textTheme.bodyMedium,
            textAlign: TextAlign.center),
        Text(
            "${_activityStats['total_sessions'] ?? 0} Activities for a total of ${_activityStats['total_duration_minutes'] ?? 0} Minutes and an additonal Kalorie burn of ${_getCaloriesDisplayValue()} kcal",
            style: ThemeData().textTheme.bodyMedium,
            textAlign: TextAlign.center),
        //add how many types are used (free, machine etc)
        //add activity statistics
        //add food statistics
      ],
    );
  }

  // Update the Confirm button in DatePicker to refresh exercise graph data
  Row DatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 16),
        // Left side - date pickers with constraints
        Flexible(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 250,
              maxWidth: 400,
            ),
            child: Column(
              children: [
                // Start Date Picker
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _tempStartingDate != null
                          ? _parseDate(_tempStartingDate!)
                          : DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      helpText: 'Select Start Date',
                    );
                    if (picked != null) {
                      setState(() {
                        _tempStartingDate =
                            DateFormat('dd-MM-yyyy').format(picked);
                      });
                    }
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tempStartingDate ?? 'Select Start Date',
                          style: TextStyle(
                            color: _tempStartingDate != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // End Date Picker
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _tempEndingDate != null
                          ? _parseDate(_tempEndingDate!)
                          : DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      helpText: 'Select End Date',
                    );
                    if (picked != null) {
                      setState(() {
                        _tempEndingDate =
                            DateFormat('dd-MM-yyyy').format(picked);
                      });
                    }
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tempEndingDate ?? 'Select End Date',
                          style: TextStyle(
                            color: _tempEndingDate != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Right side - buttons with constraints
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 80,
            maxWidth: 120,
          ),
          child: Column(
            children: [
              // Confirm button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    startingDate = _tempStartingDate;
                    endingDate = _tempEndingDate;
                    // Disable default filtering when user selects custom dates
                    _useDefaultDateFilter = false;
                  });
                  // Call _loadStatistics() to update all statistics
                  _loadStatistics();

                  // Also update exercise graph if one is selected
                  if (_selectedExerciseForGraph != null) {
                    _loadExerciseGraphDataFromCoordinator(
                        _selectedExerciseForGraph!);
                  }
                  if (_selectedWidgetIndex == 6) {
                    setState(() {
                      // This will trigger a rebuild of FoodStatsScreen with new parameters
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Confirm"),
              ),
              const SizedBox(height: 8),
              // Clear button
              TextButton(
                onPressed: () {
                  setState(() {
                    // Reset to default 3-month range
                    final now = DateTime.now();
                    final threeMonthsAgo =
                        now.subtract(const Duration(days: 90));
                    _tempStartingDate =
                        DateFormat('dd-MM-yyyy').format(threeMonthsAgo);
                    _tempEndingDate = DateFormat('dd-MM-yyyy').format(now);
                    startingDate = null;
                    endingDate = null;
                    // Re-enable default filtering when clearing dates
                    _useDefaultDateFilter = true;
                  });
                  // Reload statistics with default filter
                  _loadStatistics();

                  // Also update exercise graph if one is selected
                  if (_selectedExerciseForGraph != null) {
                    _loadExerciseGraphDataFromCoordinator(
                        _selectedExerciseForGraph!);
                  }
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Clear", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // Helper method to parse date from string format
  DateTime _parseDate(String dateString) {
    try {
      final parts = dateString.split('-');
      return DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  // Add new methods for exercise progress functionality
  Future<void> _loadAvailableExercises() async {
    try {
      final exercises = await _dataService.getExercises();
      setState(() {
        _availableExercises = exercises;
        // Sort alphabetically with case-insensitive comparison and trimmed names (same as landing screen)
        _availableExercises.sort((a, b) =>
            a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase()));

        // Auto-select first exercise if available
        if (_availableExercises.isNotEmpty &&
            _selectedExerciseForGraph == null) {
          _selectedExerciseForGraph = _availableExercises.first.name;
          _loadExerciseGraphDataFromCoordinator(_selectedExerciseForGraph!);
        }
      });
    } catch (e) {
      print('Error loading exercises: $e');
    }
  }

  Widget _buildExerciseProgressView() {
    return Column(
      children: [
        Text(
          "Exercise Progress",
          style: ThemeData().textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Exercise dropdown
        if (_availableExercises.isNotEmpty)
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedExerciseForGraph,
              hint: const Text("Select an exercise"),
              items: _availableExercises.map((exercise) {
                return DropdownMenuItem<String>(
                  value: exercise.name,
                  child: Text(exercise.name),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedExerciseForGraph = newValue;
                  });
                  _loadExerciseGraphDataFromCoordinator(newValue);
                }
              },
            ),
          ),

        const SizedBox(height: 20),

        // Graph section
        if (_selectedExerciseForGraph != null)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: _exerciseGraphMaxHistoryDistance > 30
                                  ? 14
                                  : 7,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (_exerciseGraphMostRecentDate == null) {
                                  return const Text('');
                                }
                                final daysAgo = value.abs().round();
                                final date = _exerciseGraphMostRecentDate!
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
                        lineBarsData: _exerciseGraphData,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipRoundedRadius: 0.0,
                            showOnTopOfTheChartBoxArea: false,
                            fitInsideVertically: true,
                            tooltipMargin: 0,
                            getTooltipItems: (value) {
                              return value.map((e) {
                                final tooltips =
                                    _exerciseGraphTooltip[e.x.toInt()];
                                if (tooltips != null &&
                                    e.barIndex < tooltips.length) {
                                  return LineTooltipItem(
                                    tooltips[e.barIndex],
                                    const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                return null;
                              }).toList();
                            },
                          ),
                        ),
                        minY: _exerciseGraphMinScore - 5.0,
                        maxY: _exerciseGraphMaxScore + 5.0,
                        minX: -_exerciseGraphMaxHistoryDistance,
                        maxX: 0,
                      ),
                    ),
                  ),
                ),
                // Graph legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      const Text("Best Set Per Day",
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 10),
                      Container(width: 12, height: 12, color: Colors.blue),
                      const SizedBox(width: 5),
                      const Text("Progress", style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text("Select an exercise to view progress"),
            ),
          ),
      ],
    );
  }

  // ...existing code...
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
