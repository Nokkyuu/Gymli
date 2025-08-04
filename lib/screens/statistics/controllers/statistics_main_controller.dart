/// Statistics Main Controller - Primary business logic controller for statistics screen
/// Manages all statistics data, loading states, and coordinates with services
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_machine/time_machine.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/api/api_models.dart';
import '../../../utils/services/service_container.dart';
import '../services/statistics_data_service.dart';
import '../services/statistics_filter_service.dart';
import '../services/statistics_calculation_service.dart';
import '../services/statistics_coordinator.dart';

//TODO: Refactor into smaller and more specialized controllers
class StatisticsMainController extends ChangeNotifier {
  final ServiceContainer _container;

  // Service instances
  late final StatisticsDataService _dataService;
  late final StatisticsFilterService _filterService;
  late final StatisticsCalculationService _calculationService;
  late final StatisticsCoordinator _coordinator;

  // State variables
  bool _isLoading = true;
  String? _errorMessage;

  // Statistics data
  int _numberOfTrainingDays = 0;
  String _trainingDuration = "";
  List<String> _trainingDates = [];
  List<LineChartBarData> _trainingsPerWeekChart = [];
  List<BarChartGroupData> _barChartStatistics = [];
  List<double> _heatMapMulti = [];
  List<List<double>> _muscleHistoryScore = [];

  // Date filtering
  String? _startingDate;
  String? _endingDate;
  String? _tempStartingDate;
  String? _tempEndingDate;
  bool _useDefaultDateFilter = true;

  // Equipment usage
  int _freeWeightsCount = 0;
  int _machinesCount = 0;
  int _cablesCount = 0;
  int _bodyweightCount = 0;

  // Activity data
  Map<String, dynamic> _activityStats = {};
  List<FlSpot> _caloriesTrendData = [];
  List<FlSpot> _durationTrendData = [];
  bool _isLoadingActivityData = false;

  // Exercise progress
  List<ApiExercise> _availableExercises = [];
  String? _selectedExerciseForGraph;
  List<LineChartBarData> _exerciseGraphData = [];
  Map<int, List<String>> _exerciseGraphTooltip = {};
  double _exerciseGraphMinScore = 0;
  double _exerciseGraphMaxScore = 100;
  double _exerciseGraphMaxHistoryDistance = 90;
  DateTime? _exerciseGraphMostRecentDate;

  // Additional metrics
  int _totalWeightLiftedKg = 0;

  // Desktop view selection
  int _selectedWidgetIndex = 0;

  // Constants - Muscle heatmap coordinates
  final List<List<double>> _heatMapCoordinates = [
    [0.25, 1 - 0.73], //pectoralis
    [0.75, 1 - 0.80], // trapezius
    [0.37, 1 - 0.68], // biceps
    [0.25, 1 - 0.59], // abs
    [0.36, 1 - 0.79], //Front delts
    [0.64, 1 - 0.85], //Side Delts
    [0.64, 1 - 0.75], //Back Delts
    [0.74, 1 - 0.65], //latiss
    [0.61, 1 - 0.68], //tri
    [0.74, 1 - 0.50], //glut
    [0.71, 1 - 0.40], //ham
    [0.29, 1 - 0.41], //quad
    [0.4, 1 - 0.57], //fore
    [0.31, 1 - 0.20], //calv
  ];

  StatisticsMainController({ServiceContainer? container})
      : _container = container ?? ServiceContainer() {
    _initializeServices();
    _initializeDatePicker();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get numberOfTrainingDays => _numberOfTrainingDays;
  String get trainingDuration => _trainingDuration;
  List<String> get trainingDates => List.from(_trainingDates);
  List<LineChartBarData> get trainingsPerWeekChart =>
      List.from(_trainingsPerWeekChart);
  List<BarChartGroupData> get barChartStatistics =>
      List.from(_barChartStatistics);
  List<double> get heatMapMulti => List.from(_heatMapMulti);
  List<List<double>> get heatMapCoordinates => List.from(_heatMapCoordinates);
  List<List<double>> get muscleHistoryScore => List.from(_muscleHistoryScore);

  String? get startingDate => _startingDate;
  String? get endingDate => _endingDate;
  String? get tempStartingDate => _tempStartingDate;
  String? get tempEndingDate => _tempEndingDate;
  bool get useDefaultDateFilter => _useDefaultDateFilter;

  int get freeWeightsCount => _freeWeightsCount;
  int get machinesCount => _machinesCount;
  int get cablesCount => _cablesCount;
  int get bodyweightCount => _bodyweightCount;

  Map<String, dynamic> get activityStats => Map.from(_activityStats);
  List<FlSpot> get caloriesTrendData => List.from(_caloriesTrendData);
  List<FlSpot> get durationTrendData => List.from(_durationTrendData);
  bool get isLoadingActivityData => _isLoadingActivityData;

  List<ApiExercise> get availableExercises => List.from(_availableExercises);
  String? get selectedExerciseForGraph => _selectedExerciseForGraph;
  List<LineChartBarData> get exerciseGraphData => List.from(_exerciseGraphData);
  Map<int, List<String>> get exerciseGraphTooltip =>
      Map.from(_exerciseGraphTooltip);
  double get exerciseGraphMinScore => _exerciseGraphMinScore;
  double get exerciseGraphMaxScore => _exerciseGraphMaxScore;
  double get exerciseGraphMaxHistoryDistance =>
      _exerciseGraphMaxHistoryDistance;
  DateTime? get exerciseGraphMostRecentDate => _exerciseGraphMostRecentDate;

  int get totalWeightLiftedKg => _totalWeightLiftedKg;
  int get selectedWidgetIndex => _selectedWidgetIndex;

  @override
  void dispose() {
    _container.authService.authStateNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  /// Initialize the statistics screen
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      await loadStatistics();

      // Listen for data changes
      _container.authService.authStateNotifier.addListener(_onDataChanged);
    } catch (e) {
      _setError('Failed to initialize statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all statistics data
  Future<void> loadStatistics() async {
    try {
      _setLoading(true);

      // Get all training sets from data service
      final allTrainingSets = await _dataService.getTrainingSets();

      // Check if we have any training sets at all
      if (allTrainingSets.isEmpty) {
        _setEmptyState();
        return;
      }

      await _processTrainingData(allTrainingSets);
      await _updateBarStatisticsFromCoordinator();
      await _loadActivityDataFromCoordinator();
    } catch (e) {
      if (kDebugMode) print('Error loading statistics: $e');
      _setError('Error loading data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set temporary start date
  void setTempStartingDate(String? date) {
    _tempStartingDate = date;
    notifyListeners();
  }

  /// Set temporary end date
  void setTempEndingDate(String? date) {
    _tempEndingDate = date;
    notifyListeners();
  }

  /// Confirm date selection and reload data
  Future<void> confirmDateSelection() async {
    _startingDate = _tempStartingDate;
    _endingDate = _tempEndingDate;
    _useDefaultDateFilter = false;

    await loadStatistics();

    // Update exercise graph if one is selected
    if (_selectedExerciseForGraph != null) {
      await _loadExerciseGraphDataFromCoordinator(_selectedExerciseForGraph!);
    }
  }

  /// Clear date selection and use default filter
  Future<void> clearDateSelection() async {
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));
    _tempStartingDate = DateFormat('dd-MM-yyyy').format(threeMonthsAgo);
    _tempEndingDate = DateFormat('dd-MM-yyyy').format(now);
    _startingDate = null;
    _endingDate = null;
    _useDefaultDateFilter = true;

    await loadStatistics();

    // Update exercise graph if one is selected
    if (_selectedExerciseForGraph != null) {
      await _loadExerciseGraphDataFromCoordinator(_selectedExerciseForGraph!);
    }
  }

  /// Set selected widget for desktop view
  void setSelectedWidget(int index) {
    _selectedWidgetIndex = index;

    // Load data when specific views are selected
    if (index == 4) {
      _loadAvailableExercises();
    } else if (index == 5) {
      _loadActivityDataFromCoordinator();
    }

    notifyListeners();
  }

  /// Select exercise for progress graph
  Future<void> selectExerciseForGraph(String exerciseName) async {
    _selectedExerciseForGraph = exerciseName;
    await _loadExerciseGraphDataFromCoordinator(exerciseName);
  }

  /// Get properly formatted calories display value
  String getCaloriesDisplayValue() {
    final calories = _activityStats['total_calories_burned'];
    if (kDebugMode) {
      print(
          'Debug - calories value: $calories (type: ${calories.runtimeType})');
    }

    if (calories == null) return "0";

    // Handle both int and double types
    if (calories is num) {
      return calories.toStringAsFixed(0);
    }

    // Fallback - try to parse as string
    final parsed = double.tryParse(calories.toString());
    return parsed?.toStringAsFixed(0) ?? "0";
  }

  /// Parse date from string format
  DateTime parseDate(String dateString) {
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

  /// Calculate week number
  int weekNumber(DateTime date) {
    DateTime jan1 = DateTime(date.year, 1, 1);
    int dayOfYear = date.difference(jan1).inDays + 1;
    int week = ((dayOfYear - date.weekday + 10) / 7).floor();

    if (week < 1) {
      return weekNumber(DateTime(date.year - 1, 12, 31));
    } else if (week > 52) {
      DateTime dec31 = DateTime(date.year, 12, 31);
      if (dec31.weekday < 4) {
        return 1;
      }
    }

    return week;
  }

  // Private methods

  void _initializeServices() {
    _dataService = StatisticsDataService(_container);
    _filterService = StatisticsFilterService();
    _calculationService = StatisticsCalculationService();
    _coordinator = StatisticsCoordinator(
      dataService: _dataService,
      calculationService: _calculationService,
      filterService: _filterService,
    );
  }

  void _initializeDatePicker() {
    if (_useDefaultDateFilter) {
      final now = DateTime.now();
      final threeMonthsAgo = now.subtract(const Duration(days: 90));
      _tempStartingDate = DateFormat('dd-MM-yyyy').format(threeMonthsAgo);
      _tempEndingDate = DateFormat('dd-MM-yyyy').format(now);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setEmptyState() {
    _numberOfTrainingDays = 0;
    _trainingDuration = "No training data available";
    _trainingDates.clear();
    _trainingsPerWeekChart.clear();
    _barChartStatistics.clear();
    _heatMapMulti.clear();
    _muscleHistoryScore.clear();
    _setLoading(false);
  }

  Future<void> _processTrainingData(
      List<Map<String, dynamic>> allTrainingSets) async {
    // Extract unique training dates
    Set<DateTime> uniqueDates = {};
    for (var trainingSet in allTrainingSets) {
      try {
        final date = DateTime.parse(trainingSet['date']);
        if (trainingSet['set_type'] > 0) {
          uniqueDates.add(DateTime(date.year, date.month, date.day));
        }
      } catch (e) {
        if (kDebugMode) print('Error parsing date: $e');
      }
    }

    List<DateTime> trainingDatesList = uniqueDates.toList()..sort();

    // Set all training dates for dropdown menus
    _trainingDates.clear();
    for (var d in trainingDatesList) {
      _trainingDates.add(DateFormat('dd-MM-yyyy').format(d));
    }

    // Apply filtering
    final filteredTrainingDates = _filterService.filterTrainingDates(
      trainingDates: trainingDatesList,
      startingDate: _startingDate,
      endingDate: _endingDate,
      useDefaultFilter: _useDefaultDateFilter,
    );

    _numberOfTrainingDays = filteredTrainingDates.length;
    if (_numberOfTrainingDays == 0) {
      _trainingDuration = "No work sets found in selected date range";
      _trainingsPerWeekChart.clear();
      _barChartStatistics.clear();
      _heatMapMulti.clear();
      return;
    }

    // Calculate date range and duration
    DateTime startDate, endDate;
    if (_useDefaultDateFilter) {
      endDate = DateTime.now();
      startDate = endDate.subtract(const Duration(days: 90));
    } else {
      startDate = _startingDate != null
          ? parseDate(_startingDate!)
          : DateTime.now().subtract(const Duration(days: 90));
      endDate = _endingDate != null ? parseDate(_endingDate!) : DateTime.now();
    }

    _totalWeightLiftedKg = await _calculateTotalWeightLiftedKg(
      trainingSets: allTrainingSets,
      startDate: startDate,
      endDate: endDate,
    );

    Period diff =
        LocalDate.dateTime(endDate).periodSince(LocalDate.dateTime(startDate));
    _trainingDuration =
        "Over the period of ${diff.months} month and ${diff.days} days";

    // Create trainings per week chart
    await _createTrainingsPerWeekChart(filteredTrainingDates);
  }

  Future<void> _createTrainingsPerWeekChart(
      List<DateTime> filteredTrainingDates) async {
    Map<int, int> trainingsPerWeekMap = {};

    for (var date in filteredTrainingDates) {
      int week = weekNumber(date);
      int year = date.year;
      int weekKey = year * 100 + week;
      trainingsPerWeekMap[weekKey] = (trainingsPerWeekMap[weekKey] ?? 0) + 1;
    }

    List<int> sortedWeekKeys = trainingsPerWeekMap.keys.toList()..sort();

    if (sortedWeekKeys.isEmpty) {
      _trainingsPerWeekChart.clear();
      return;
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedWeekKeys.length; i++) {
      int weekKey = sortedWeekKeys[i];
      int count = trainingsPerWeekMap[weekKey] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    _trainingsPerWeekChart.clear();
    _trainingsPerWeekChart.add(LineChartBarData(
      spots: spots,
      isCurved: false,
      color: Colors.blue,
      barWidth: 2,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(show: false),
      dotData: const FlDotData(show: true),
    ));
  }

  Future<int> _calculateTotalWeightLiftedKg({
    required List<Map<String, dynamic>> trainingSets,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    int total = 0;
    for (final set in trainingSets) {
      try {
        if ((set['set_type'] ?? 0) > 0) {
          final date = DateTime.parse(set['date']);
          if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              date.isBefore(endDate.add(const Duration(days: 1)))) {
            final reps = set['repetitions'] ?? 0;
            final weight = set['weight'] ?? 0;
            total += (reps as int) * (weight as int);
          }
        }
      } catch (e) {
        continue;
      }
    }
    return total;
  }

  Future<void> _updateBarStatisticsFromCoordinator() async {
    try {
      final result = await _coordinator.calculateBarStatistics(
        startingDate: _startingDate,
        endingDate: _endingDate,
        useDefaultFilter: _useDefaultDateFilter,
      );

      _muscleHistoryScore = result.muscleHistoryScore;
      _barChartStatistics = result.barChartStatistics.isEmpty
          ? []
          : result.barChartStatistics.last;
      _heatMapMulti = result.heatMapData;

      await _calculateEquipmentUsage();
    } catch (e) {
      if (kDebugMode) print('Error updating bar statistics: $e');
    }
  }

  Future<void> _calculateEquipmentUsage() async {
    try {
      final result = await _coordinator.getEquipmentUsage(
        startingDate: _startingDate,
        endingDate: _endingDate,
        useDefaultFilter: _useDefaultDateFilter,
      );

      _freeWeightsCount = result['freeWeights'] ?? 0;
      _machinesCount = result['machines'] ?? 0;
      _cablesCount = result['cables'] ?? 0;
      _bodyweightCount = result['bodyweight'] ?? 0;
    } catch (e) {
      if (kDebugMode) print('Error calculating equipment usage: $e');
      _freeWeightsCount = 0;
      _machinesCount = 0;
      _cablesCount = 0;
      _bodyweightCount = 0;
    }
  }

  Future<void> _loadActivityDataFromCoordinator() async {
    _isLoadingActivityData = true;
    notifyListeners();

    try {
      final result = await _coordinator.loadActivityData(
        startingDate: _startingDate,
        endingDate: _endingDate,
        useDefaultFilter: _useDefaultDateFilter,
      );

      _activityStats = result.activityStats;
      _caloriesTrendData = result.caloriesTrendData;
      _durationTrendData = result.durationTrendData;
    } catch (e) {
      if (kDebugMode) print('Error loading activity data: $e');
      _activityStats = {};
      _caloriesTrendData = [];
      _durationTrendData = [];
    } finally {
      _isLoadingActivityData = false;
      notifyListeners();
    }
  }

  Future<void> _loadExerciseGraphDataFromCoordinator(
      String exerciseName) async {
    try {
      final result = await _coordinator.loadExerciseGraphData(
        exerciseName: exerciseName,
        startingDate: _startingDate,
        endingDate: _endingDate,
        useDefaultFilter: _useDefaultDateFilter,
      );

      _exerciseGraphData = result.graphData;
      _exerciseGraphTooltip = result.tooltipData;
      _exerciseGraphMinScore = result.minScore;
      _exerciseGraphMaxScore = result.maxScore;
      _exerciseGraphMaxHistoryDistance = result.maxHistoryDistance;
      _exerciseGraphMostRecentDate = result.mostRecentDate;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading exercise graph data: $e');
      _exerciseGraphData = [];
      _exerciseGraphTooltip = {};
      _exerciseGraphMinScore = 0;
      _exerciseGraphMaxScore = 100;
      _exerciseGraphMaxHistoryDistance = 90;
      _exerciseGraphMostRecentDate = null;
      notifyListeners();
    }
  }

  Future<void> _loadAvailableExercises() async {
    try {
      final exercises = await _dataService.getExercises();
      _availableExercises = exercises;
      _availableExercises.sort((a, b) =>
          a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase()));

      if (_availableExercises.isNotEmpty && _selectedExerciseForGraph == null) {
        _selectedExerciseForGraph = _availableExercises.first.name;
        await _loadExerciseGraphDataFromCoordinator(_selectedExerciseForGraph!);
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading exercises: $e');
    }
  }

  void _onDataChanged() {
    _dataService.invalidateCache();
    loadStatistics();
  }
}
