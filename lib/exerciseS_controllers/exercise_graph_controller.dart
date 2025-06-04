import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../api_models.dart';
import '../globals.dart' as globals;
import 'package:flutter/material.dart';

/// Controller for managing exercise graph data and calculations
class ExerciseGraphController extends ChangeNotifier {
  static const List<Color> graphColors = [
    Color.fromARGB(255, 0, 109, 44),
    Color.fromARGB(255, 44, 162, 95),
    Color.fromARGB(255, 102, 194, 164),
    Color.fromARGB(255, 153, 216, 201),
  ];

  static const List<Color> additionalColors = [
    Color.fromARGB(255, 253, 204, 138),
    Color.fromARGB(255, 252, 141, 89),
    Color.fromARGB(255, 215, 48, 31)
  ];

  List<List<FlSpot>> _trainingGraphs = [[], [], [], []];
  List<List<FlSpot>> _additionalGraphs = [];
  Map<int, List<String>> _graphToolTip = {};

  double _minScore = 1e6;
  double _maxScore = 0.0;
  double _maxHistoryDistance = 90.0;
  DateTime? _mostRecentTrainingDate;

  // Getters
  List<List<FlSpot>> get trainingGraphs => _trainingGraphs;
  List<List<FlSpot>> get additionalGraphs => _additionalGraphs;
  Map<int, List<String>> get graphToolTip => _graphToolTip;
  double get minScore => _minScore;
  double get maxScore => _maxScore;
  double get maxHistoryDistance => _maxHistoryDistance;
  DateTime? get mostRecentTrainingDate => _mostRecentTrainingDate;

  /// Update graph data from training sets
  void updateGraphFromTrainingSets(List<ApiTrainingSet> trainingSets,
      {bool detailedGraph = false}) {
    _clearGraphData();

    if (trainingSets.isEmpty) {
      notifyListeners();
      return;
    }

    // Filter work sets only (exclude warmups)
    final workSets = trainingSets.where((set) => set.setType > 0).toList();
    if (workSets.isEmpty) {
      notifyListeners();
      return;
    }

    // Group by date and process
    final dataByDate = _groupTrainingSetsByDate(workSets);
    final graphData = _processGraphData(dataByDate, detailedGraph);

    _updateGraphRanges(dataByDate);
    _updateGraphPoints(graphData, detailedGraph);

    notifyListeners();
  }

  /// Efficiently update graph with a single new training set
  bool updateGraphWithNewSet(ApiTrainingSet newSet) {
    try {
      // Only update if this is a work set (not warmup)
      if (newSet.setType == 0) return false;

      final dateKey = _formatDateKey(newSet.date);
      final today = DateTime.now();
      final todayKey = _formatDateKey(today);

      // If this is today's set, update the graph
      if (dateKey == todayKey) {
        final todayIndex = _trainingGraphs[0].indexWhere((spot) => spot.x == 0);
        final score = globals.calculateScore(newSet);

        if (todayIndex != -1) {
          // Update existing point if this set is better
          if (score > _trainingGraphs[0][todayIndex].y) {
            _trainingGraphs[0][todayIndex] = FlSpot(0, score);
            _graphToolTip[0] = [
              "${newSet.weight}kg @ ${newSet.repetitions}reps"
            ];
          }
        } else {
          // Add new point for today
          _trainingGraphs[0].add(FlSpot(0, score));
          _graphToolTip[0] = ["${newSet.weight}kg @ ${newSet.repetitions}reps"];
        }

        _updateMinMaxScores();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating graph with new set: $e');
      return false;
    }
  }

  /// Generate line chart bar data for FL Chart
  List<LineChartBarData> generateLineChartBarData(List<String> groupExercises) {
    final barData = <LineChartBarData>[];

    // Create line chart bars from training graph data
    for (int i = 0; i < _trainingGraphs.length; i++) {
      if (_trainingGraphs[i].isNotEmpty) {
        barData.add(LineChartBarData(
          spots: _trainingGraphs[i],
          isCurved: false,
          color: i < graphColors.length ? graphColors[i] : Colors.grey,
          barWidth: 2,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: true),
        ));
      }
    }

    // Add additional graph data if any
    for (int i = 0; i < _additionalGraphs.length; i++) {
      if (_additionalGraphs[i].isNotEmpty) {
        barData.add(LineChartBarData(
          spots: _additionalGraphs[i],
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

    return barData;
  }

  /// Clear all graph data
  void _clearGraphData() {
    for (var graph in _trainingGraphs) {
      graph.clear();
    }
    _graphToolTip.clear();
  }

  /// Group training sets by date
  Map<String, List<ApiTrainingSet>> _groupTrainingSetsByDate(
      List<ApiTrainingSet> trainingSets) {
    final Map<String, List<ApiTrainingSet>> dataByDate = {};

    for (var set in trainingSets) {
      final dateKey = _formatDateKey(set.date);
      if (!dataByDate.containsKey(dateKey)) {
        dataByDate[dateKey] = [];
      }
      dataByDate[dateKey]!.add(set);
    }

    return dataByDate;
  }

  /// Process graph data from grouped training sets
  Map<String, ApiTrainingSet> _processGraphData(
      Map<String, List<ApiTrainingSet>> dataByDate, bool detailedGraph) {
    final Map<String, ApiTrainingSet> graphData = {};

    for (var entry in dataByDate.entries) {
      final dateKey = entry.key;
      final sets = entry.value;

      if (detailedGraph) {
        // For detailed graph, we might want multiple points per day
        // For now, just use the best set
        graphData[dateKey] = _findBestSet(sets);
      } else {
        // For simple graph, use the best set of the day
        graphData[dateKey] = _findBestSet(sets);
      }
    }

    return graphData;
  }

  /// Find the best training set from a list (highest weight, then most reps)
  ApiTrainingSet _findBestSet(List<ApiTrainingSet> sets) {
    ApiTrainingSet bestSet = sets.first;

    for (var set in sets) {
      if (set.weight > bestSet.weight ||
          (set.weight == bestSet.weight &&
              set.repetitions > bestSet.repetitions)) {
        bestSet = set;
      }
    }

    return bestSet;
  }

  /// Update graph ranges based on data
  void _updateGraphRanges(Map<String, List<ApiTrainingSet>> dataByDate) {
    if (dataByDate.isEmpty) return;

    final sortedDates = dataByDate.keys.toList()..sort();
    final earliestDate = DateTime.parse(sortedDates.first);
    final latestDate = DateTime.parse(sortedDates.last);

    _mostRecentTrainingDate = latestDate;
    final daysDifference = latestDate.difference(earliestDate).inDays;

    // Calculate dynamic range (minimum 2 days, maximum from global setting)
    final maxDaysFromLatest =
        latestDate.subtract(Duration(days: globals.graphNumberOfDays));
    DateTime startDate;

    if (daysDifference < 2) {
      startDate = latestDate.subtract(const Duration(days: 2));
    } else {
      startDate = earliestDate.isBefore(maxDaysFromLatest)
          ? maxDaysFromLatest
          : earliestDate;
    }

    _maxHistoryDistance =
        max(2.0, latestDate.difference(startDate).inDays.toDouble());
  }

  /// Update graph points from processed data
  void _updateGraphPoints(
      Map<String, ApiTrainingSet> graphData, bool detailedGraph) {
    if (graphData.isEmpty || _mostRecentTrainingDate == null) return;

    final List<FlSpot> graphPoints = [];
    final Map<double, String> tooltipData = {};

    final sortedDates = graphData.keys.toList()..sort();

    for (String dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      final bestSet = graphData[dateKey]!;

      // Calculate x-coordinate as days from latest date (negative values)
      double xValue =
          -_mostRecentTrainingDate!.difference(date).inDays.toDouble();
      double yValue = globals.calculateScore(bestSet);

      graphPoints.add(FlSpot(xValue, yValue));
      tooltipData[xValue] =
          "${bestSet.weight}kg @ ${bestSet.repetitions}reps ($dateKey)";
    }

    // Add points to training graph
    if (graphPoints.isNotEmpty) {
      _trainingGraphs[0].addAll(graphPoints);

      // Update tooltip data
      for (var entry in tooltipData.entries) {
        _graphToolTip[entry.key.toInt()] = [entry.value];
      }
    }

    _updateMinMaxScores();
  }

  /// Update min/max scores for proper graph scaling
  void _updateMinMaxScores() {
    double newMinScore = 1e6;
    double newMaxScore = 0.0;

    // Check all graph data
    for (var graph in _trainingGraphs) {
      for (var spot in graph) {
        newMinScore = min(newMinScore, spot.y);
        newMaxScore = max(newMaxScore, spot.y);
      }
    }

    for (var graph in _additionalGraphs) {
      for (var spot in graph) {
        newMinScore = min(newMinScore, spot.y);
        newMaxScore = max(newMaxScore, spot.y);
      }
    }

    // Set reasonable defaults if no data
    if (_trainingGraphs.every((graph) => graph.isEmpty) &&
        _additionalGraphs.every((graph) => graph.isEmpty)) {
      newMinScore = 0;
      newMaxScore = 100;
    }

    _minScore = newMinScore;
    _maxScore = newMaxScore;
  }

  /// Refresh graph data - triggers UI rebuild
  Future<void> refreshGraph() async {
    // Trigger UI rebuild with current data
    notifyListeners();
  }

  /// Format date as key string
  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
