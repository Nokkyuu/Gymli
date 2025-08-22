import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../../utils/models/data_models.dart';
import '../../../utils/globals.dart' as globals;
import 'package:flutter/material.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import '../../../utils/themes/themes.dart';
import 'package:get_it/get_it.dart';
import 'package:Gymli/utils/api/api_export.dart';

final themeColors = ThemeColors();

/// Controller for managing exercise graph data and calculations
class ExerciseGraphController extends ChangeNotifier {
  static const List<Color> graphColors = [
    Color.fromARGB(217, 33, 149, 243),
    Color.fromARGB(255, 44, 162, 95),
    Color.fromARGB(255, 102, 194, 164),
    Color.fromARGB(255, 153, 216, 201),
  ];

  static const List<Color> additionalColors = [
    Color.fromARGB(255, 253, 204, 138),
    Color.fromARGB(255, 252, 141, 89),
    Color.fromARGB(255, 215, 48, 31)
  ];

  static final Map<String, Color> periodColors = {
    'cut': themeColors.periodColors['cut']!, // Orange fallback
    'bulk': themeColors.periodColors['bulk']!, // Green fallback
    // 'maintenance': Color.fromARGB(80, 158, 158, 158), // Gray with transparency
    // 'recovery': Color.fromARGB(80, 33, 150, 243), // Blue with transparency
  };

  List<List<FlSpot>> _trainingGraphs = [[], [], [], []];
  List<List<FlSpot>> _additionalGraphs = [];
  Map<int, List<String>> _graphToolTip = {};
  List<BetweenBarsData> _periodBarsData = [];

  double _minScore = 1e6;
  double _maxScore = 0.0;
  double _maxHistoryDistance = 90.0;
  DateTime? _mostRecentTrainingDate;

  ApiExercise? _currentExercise; // Add this field

  // Add this field to store period types
  List<String> _periodTypes = [];

  // 1. Feld für Notiz-Daten
  Set<String> _noteDates = {};
  Map<String, String> _notesByDate = {};

  // Getters
  List<List<FlSpot>> get trainingGraphs => _trainingGraphs;
  List<List<FlSpot>> get additionalGraphs => _additionalGraphs;
  Map<int, List<String>> get graphToolTip => _graphToolTip;
  List<BetweenBarsData> get periodBarsData => _periodBarsData;
  double get minScore => _minScore;
  double get maxScore => _maxScore;
  double get maxHistoryDistance => _maxHistoryDistance;
  DateTime? get mostRecentTrainingDate => _mostRecentTrainingDate;
  ApiExercise? get currentExercise => _currentExercise;

// 2. Methode zum Laden der Notizdaten
  Future<void> loadNoteDates() async {
    final notes = await GetIt.I<CalendarService>().getCalendarNotes();
    _noteDates = notes
        .map<String>((n) => (n['date'] as String).substring(0, 10))
        .toSet();
    _notesByDate = {
      for (var n in notes)
        (n['date'] as String).substring(0, 10): (n['note'] as String? ?? '')
    };
  }

  /// Set the current exercise - call this when exercise data is available
  void setCurrentExercise(ApiExercise? exercise) {
    _currentExercise = exercise;
    // Don't notify listeners here as this is just setting up data
  }

  /// Update graph data from training sets
  Future<void> updateGraphFromTrainingSets(List<ApiTrainingSet> trainingSets,
      {bool detailedGraph = false}) async {
    await loadNoteDates();
    // Add async here
    _clearGraphData();

    if (trainingSets.isEmpty) {
      await _loadPeriodData(); // Load periods even if no training data
      notifyListeners();
      return;
    }

    // Filter work sets only (exclude warmups)
    final workSets = trainingSets.where((set) => set.setType > 0).toList();
    if (workSets.isEmpty) {
      await _loadPeriodData(); // Add await here too
      notifyListeners();
      return;
    }

    // Group by date and process
    final dataByDate = _groupTrainingSetsByDate(workSets);
    final graphData = _processGraphData(dataByDate, detailedGraph);

    _updateGraphRanges(dataByDate);
    _updateGraphPoints(
        graphData, dataByDate, detailedGraph); // Pass dataByDate too
    await _loadPeriodData(); // This await was missing proper async function

    notifyListeners();
  }

  /// Load period data and create helper lines with belowBarData
  Future<void> _loadPeriodData() async {
    try {
      final periods = await GetIt.I<CalendarService>().getCalendarPeriods();
      _periodTypes.clear(); // Clear period types

      if (_mostRecentTrainingDate == null) return;

      for (var period in periods) {
        final type = period['type'] as String? ?? 'maintenance';
        final startDateStr = period['start_date'] as String?;
        final endDateStr = period['end_date'] as String?;

        if (startDateStr == null || endDateStr == null) continue;

        try {
          final startDate = DateTime.parse(startDateStr);
          final endDate = DateTime.parse(endDateStr);

          // Convert dates to x-coordinates
          final startX =
              -_mostRecentTrainingDate!.difference(startDate).inDays.toDouble();
          final endX =
              -_mostRecentTrainingDate!.difference(endDate).inDays.toDouble();

          // Check if period overlaps with graph range
          final graphStartX = -_maxHistoryDistance;
          final graphEndX = 0.0;

          if (startX <= graphEndX && endX >= graphStartX) {
            // Clamp the period to the visible range
            final clampedStartX = max(startX, graphStartX);
            final clampedEndX = min(endX, graphEndX);

            // Create invisible helper line at the top of the graph
            final List<FlSpot> periodSpots = [
              FlSpot(clampedStartX, _maxScore + 10),
              FlSpot(clampedEndX, _maxScore + 10),
            ];

            _additionalGraphs.add(periodSpots);
            _periodTypes.add(type); // Store the period type
          }
        } catch (e) {
          print('Error parsing period dates: $e');
        }
      }
    } catch (e) {
      print('Error loading period data: $e');
    }
  } // Efficiently update graph with a single new training set

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
        final score = _calculateScoreForSet(newSet); // Use helper method

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

  /// Calculate score for a training set using the appropriate method
  double _calculateScoreForSet(ApiTrainingSet trainingSet) {
    if (_currentExercise != null) {
      return globals.calculateScoreWithExercise(trainingSet, _currentExercise!);
    } else {
      // Fallback shows 0
      return 0;
    }
  }

  /// Update graph points from processed data
  void _updateGraphPoints(Map<String, ApiTrainingSet> graphData,
      Map<String, List<ApiTrainingSet>> dataByDate, bool detailedGraph) {
    if (graphData.isEmpty || _mostRecentTrainingDate == null) return;

    final List<FlSpot> bestPoints = [];
    final List<FlSpot> secondBestPoints = [];
    final Map<double, String> tooltipData = {};

    final sortedDates = graphData.keys.toList()..sort();

    for (String dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      final setsForDay = dataByDate[dateKey] ?? [];
      if (setsForDay.isEmpty) continue;

      // Sort sets by score descending using the new score calculation
      final sortedSets = List<ApiTrainingSet>.from(setsForDay)
        ..sort((a, b) =>
            _calculateScoreForSet(b).compareTo(_calculateScoreForSet(a)));

      final bestSet = sortedSets[0];
      final secondBestSet =
          sortedSets.length > 1 ? sortedSets[1] : sortedSets[0];

      // Calculate x-coordinate as days from latest date (negative values)
      double xValue =
          -_mostRecentTrainingDate!.difference(date).inDays.toDouble();
      double yBest = _calculateScoreForSet(bestSet);
      double ySecondBest = _calculateScoreForSet(secondBestSet);

      bestPoints.add(FlSpot(xValue, yBest));
      secondBestPoints.add(FlSpot(xValue, ySecondBest));
      // Tooltip mit Notiz, falls vorhanden
      String tooltip =
          "${bestSet.weight}kg @ ${bestSet.repetitions}reps ($dateKey)";
      if (_notesByDate.containsKey(dateKey) &&
          _notesByDate[dateKey]!.isNotEmpty) {
        tooltip += "\n📝 ${_notesByDate[dateKey]}";
      }
      tooltipData[xValue] = tooltip;
    }

    // Add points to training graph
    if (bestPoints.isNotEmpty) {
      _trainingGraphs[0].addAll(bestPoints);
      for (var entry in tooltipData.entries) {
        _graphToolTip[entry.key.toInt()] = [entry.value];
      }
    }
    if (secondBestPoints.isNotEmpty) {
      _trainingGraphs[1].addAll(secondBestPoints);
    }

    _updateMinMaxScores();
  }

  /// Generate line chart bar data for FL Chart
  List<LineChartBarData> generateLineChartBarData(List<String> groupExercises) {
    final barData = <LineChartBarData>[];

    // Best line (index 0)
    if (_trainingGraphs[0].isNotEmpty) {
      barData.add(LineChartBarData(
        spots: _trainingGraphs[0],
        isCurved: false,
        color: graphColors[0],
        barWidth: 2,
        isStrokeCapRound: true,
        belowBarData: BarAreaData(show: false),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) {
            // Datum berechnen
            final date =
                _mostRecentTrainingDate?.add(Duration(days: spot.x.toInt()));
            final dateKey = date != null
                ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
                : "";
            if (_noteDates.contains(dateKey)) {
              // Spezieller Dot für Notiz
              return FlDotCrossPainter(
                size: 10,
                width: 3,
                color: ThemeColors.themeOrange,
              );
            }
            // Standard-Dot
            return FlDotCirclePainter(
              radius: 4,
              color: bar.color ?? Colors.blue,
              strokeWidth: 0,
              strokeColor: Colors.transparent,
            );
          },
        ),
      ));
    }

    // Lowest line (index 1) - faint
    if (_trainingGraphs.length > 1 && _trainingGraphs[1].isNotEmpty) {
      barData.add(LineChartBarData(
        spots: _trainingGraphs[1],
        isCurved: false,
        color: Colors.black.withOpacity(0.1), // faint color
        barWidth: 1,
        isStrokeCapRound: false,
        belowBarData: BarAreaData(show: false),
        dotData: const FlDotData(show: false),
      ));
    }

    // Add remaining training graphs (indices 2 and 3)
    for (int i = 2; i < _trainingGraphs.length; i++) {
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

    // Add period helper lines with belowBarData
    for (int i = 0;
        i < _periodTypes.length && i < _additionalGraphs.length;
        i++) {
      if (_additionalGraphs[i].isNotEmpty) {
        barData.add(LineChartBarData(
          spots: _additionalGraphs[i],
          isCurved: false,
          color: Colors.transparent, // Invisible line
          barWidth: 0,
          isStrokeCapRound: false,
          belowBarData: BarAreaData(
            show: true,
            color: periodColors[_periodTypes[i]] ??
                const Color.fromARGB(80, 158, 158, 158),
            cutOffY: _minScore - 10, // Fill down to below visible area
          ),
          dotData: const FlDotData(show: false),
        ));
      }
    }

    // Add remaining non-period additional graphs
    for (int i = _periodTypes.length; i < _additionalGraphs.length; i++) {
      if (_additionalGraphs[i].isNotEmpty) {
        barData.add(LineChartBarData(
          spots: _additionalGraphs[i],
          isCurved: true,
          color: (i - _periodTypes.length) < additionalColors.length
              ? additionalColors[i - _periodTypes.length]
              : Colors.grey,
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
    for (var graph in _additionalGraphs) {
      graph.clear();
    }
    _additionalGraphs.clear();
    _periodBarsData.clear();
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

  /// Find the best training set from a list (highest score)
  ApiTrainingSet _findBestSet(List<ApiTrainingSet> sets) {
    ApiTrainingSet bestSet = sets.first;

    for (var set in sets) {
      if (_calculateScoreForSet(set) > _calculateScoreForSet(bestSet)) {
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

    // Round min down and max up to the next integer
    newMinScore =
        newMinScore.isFinite ? newMinScore.floorToDouble() : newMinScore;
    newMaxScore =
        newMaxScore.isFinite ? newMaxScore.ceilToDouble() : newMaxScore;

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
