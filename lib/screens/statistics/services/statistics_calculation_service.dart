import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:time_machine/time_machine.dart';
import 'package:tuple/tuple.dart';

import '../../../utils/models/data_models.dart';
import '../../../utils/globals.dart' as globals;
import '../constants/muscle_constants.dart';
import '../constants/chart_constants.dart';
import '../models/statistics_data.dart';

/// Service responsible for all statistical calculations and business logic
class StatisticsCalculationService {
  /// Calculate muscle scores for heat map visualization
  List<double> calculateHeatMapData(List<List<double>> muscleHistoryScore) {
    if (muscleHistoryScore.isEmpty || muscleHistoryScore[0].isEmpty) {
      return List.filled(14, 0.0);
    }

    print("DEBUG _muscleHistoryScore $muscleHistoryScore");
    List<double> muscleHistoryScoreCum = [];

    for (int i = 0; i < muscleHistoryScore[0].length; i++) {
      double item = 0;
      for (int j = 0; j < muscleHistoryScore.length; j++) {
        if (i < muscleHistoryScore[j].length) {
          item += muscleHistoryScore[j][i];
        }
      }
      muscleHistoryScoreCum.add(item);
    }

    if (muscleHistoryScoreCum.isNotEmpty) {
      print("DEBUG muscleHistoryScoreCum $muscleHistoryScoreCum");
      var highestValue = muscleHistoryScoreCum.reduce(max);
      return muscleHistoryScoreCum
          .map((score) => highestValue > 0 ? score / highestValue : 0.0)
          .toList();
    } else {
      return List.filled(14, 0.0);
    }
  }

  /// Calculate equipment usage statistics
  EquipmentUsage calculateEquipmentUsage(
    List<Map<String, dynamic>> trainingSets,
    List<ApiExercise> exercises,
  ) {
    try {
      // Create a map of exercise names to their types
      final Map<String, int> exerciseNameToType = {};
      for (var exercise in exercises) {
        exerciseNameToType[exercise.name] = exercise.type;
      }

      // Count unique exercises by type from training sets
      final Set<String> freeWeightExercises = {};
      final Set<String> machineExercises = {};
      final Set<String> cableExercises = {};
      final Set<String> bodyweightExercises = {};

      for (var trainingSet in trainingSets) {
        String? exerciseName = trainingSet['exercise_name'];
        if (exerciseName != null) {
          int? exerciseType = exerciseNameToType[exerciseName];
          if (exerciseType != null) {
            switch (exerciseType) {
              case 0: // Free weights
                freeWeightExercises.add(exerciseName);
                break;
              case 1: // Machine
                machineExercises.add(exerciseName);
                break;
              case 2: // Cable
                cableExercises.add(exerciseName);
                break;
              case 3: // Bodyweight
                bodyweightExercises.add(exerciseName);
                break;
            }
          }
        }
      }

      return EquipmentUsage(
        freeWeights: freeWeightExercises.length,
        machines: machineExercises.length,
        cables: cableExercises.length,
        bodyweight: bodyweightExercises.length,
      );
    } catch (e) {
      print('Error calculating equipment usage: $e');
      return EquipmentUsage.empty();
    }
  }

  /// Calculate muscle history scores for bar chart visualization
  Future<List<List<double>>> calculateMuscleHistoryScores(
    List<DateTime> trainingDates,
    List<Map<String, dynamic>> allTrainingSets,
    List<ApiExercise> exercises,
  ) async {
    // Create muscle mapping
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

    // Create exercise mapping
    Map<String, List<Tuple2<int, double>>> exerciseMapping = {};
    for (var e in exercises) {
      List<Tuple2<int, double>> intermediateMap = [];
      for (int i = 0; i < e.muscleGroups.length; ++i) {
        String which = e.muscleGroups[i];
        var val = muscleMapping[which];
        if (val != null) {
          double intensity =
              val < e.muscleIntensities.length ? e.muscleIntensities[val] : 0.0;
          intermediateMap.add(Tuple2<int, double>(val, intensity));
        }
      }
      exerciseMapping[e.name] = intermediateMap;
    }

    List<List<double>> muscleHistoryScore = [];

    for (var day in trainingDates) {
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

    return muscleHistoryScore;
  }

  /// Generate bar chart data from muscle history scores
  List<List<BarChartGroupData>> generateBarChartStatistics(
    List<List<double>> muscleHistoryScore,
  ) {
    List<List<BarChartGroupData>> barChartStatistics = [];

    for (var i = 0; i < muscleHistoryScore.length; ++i) {
      var currentScore = muscleHistoryScore[i];
      List<double> accumulatedScore = [0.0];
      for (var d in currentScore) {
        accumulatedScore.add(accumulatedScore.last + d);
      }
      barChartStatistics.add(generateBars(i, accumulatedScore, muscleColors));
    }

    return barChartStatistics;
  }

  /// Generate bar chart groups for a specific day
  List<BarChartGroupData> generateBars(
    int x,
    List<double> values,
    List<Color> colors,
  ) {
    return List.generate(values.length - 1, (index) {
      return BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: values[index + 1],
            fromY: values[index],
            color: colors[index % colors.length],
            width: ChartStyles.barWidth,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });
  }

  /// Calculate training duration string
  String calculateTrainingDuration(List<DateTime> trainingDates) {
    if (trainingDates.isEmpty) {
      return "No training data available";
    }

    if (trainingDates.length == 1) {
      return "Single training day";
    }

    Period diff = LocalDate.dateTime(trainingDates.last)
        .periodSince(LocalDate.dateTime(trainingDates.first));
    return "Over the period of ${diff.months} month and ${diff.days} days";
  }

  /// Calculate trainings per week chart data
  List<FlSpot> calculateTrainingsPerWeek(List<DateTime> trainingDates) {
    if (trainingDates.isEmpty) {
      return [];
    }

    // Create a map to count trainings per week
    Map<int, int> trainingsPerWeekMap = {};

    for (var date in trainingDates) {
      int weekOfYear = _getWeekOfYear(date);
      trainingsPerWeekMap[weekOfYear] =
          (trainingsPerWeekMap[weekOfYear] ?? 0) + 1;
    }

    // Convert to FlSpot list
    List<FlSpot> spots = [];
    var weeks = trainingsPerWeekMap.keys.toList()..sort();

    for (int i = 0; i < weeks.length; i++) {
      spots
          .add(FlSpot(i.toDouble(), trainingsPerWeekMap[weeks[i]]!.toDouble()));
    }

    return spots;
  }

  /// Calculate exercise progress data for a specific exercise
  ExerciseProgressData calculateExerciseProgress(
    String exerciseName,
    List<Map<String, dynamic>> exerciseTrainingSets,
    ApiExercise? exercise, // Add exercise parameter
  ) {
    if (exerciseTrainingSets.isEmpty) {
      return ExerciseProgressData.empty();
    }

    // Group by date and find best set per day
    Map<String, Map<String, dynamic>> bestSetPerDay = {};

    for (var setData in exerciseTrainingSets) {
      if (setData['set_type'] == 0) continue; // Skip warmup sets

      final date = DateTime.parse(setData['date']);
      String dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      if (!bestSetPerDay.containsKey(dateKey)) {
        bestSetPerDay[dateKey] = setData;
      } else {
        final existing = bestSetPerDay[dateKey]!;
        final currentWeight = setData['weight'] as double;
        final currentReps = setData['repetitions'] as int;
        final existingWeight = existing['weight'] as double;
        final existingReps = existing['repetitions'] as int;

        // Update if better performance (higher weight, or same weight with more reps)
        if (currentWeight > existingWeight ||
            (currentWeight == existingWeight && currentReps > existingReps)) {
          bestSetPerDay[dateKey] = setData;
        }
      }
    }

    // Create graph data
    List<FlSpot> graphPoints = [];
    Map<int, List<String>> tooltipData = {};

    if (bestSetPerDay.isNotEmpty) {
      // Sort dates and find range
      var sortedDates = bestSetPerDay.keys.toList()..sort();
      final earliestDate = DateTime.parse(sortedDates.first);
      final latestDate = DateTime.parse(sortedDates.last);

      // Calculate scores and create points
      double minScore = double.infinity;
      double maxScore = double.negativeInfinity;

      for (String dateKey in sortedDates) {
        final date = DateTime.parse(dateKey);
        final setData = bestSetPerDay[dateKey]!;

        // Create ApiTrainingSet for score calculation
        final trainingSet = ApiTrainingSet(
          weight: setData['weight'] as double,
          repetitions: setData['repetitions'] as int,
          // baseReps: setData['base_reps'] as int,
          // maxReps: setData['max_reps'] as int,
          // increment: setData['increment'] as double,
          date: date,
          setType: setData['set_type'] as int,
          exerciseId: setData['exercise_id'] as int,
          exerciseName: exerciseName,
          userName: '',
        );

        double xValue = -latestDate.difference(date).inDays.toDouble();
        double yValue = _calculateScoreForSet(trainingSet, exercise);

        graphPoints.add(FlSpot(xValue, yValue));
        tooltipData[xValue.toInt()] = [
          "${setData['weight']}kg @ ${setData['repetitions']}reps ($dateKey)"
        ];

        minScore = min(minScore, yValue);
        maxScore = max(maxScore, yValue);
      }

      // Calculate max history distance
      double maxHistoryDistance =
          max(2.0, latestDate.difference(earliestDate).inDays.toDouble());

      // Create LineChartBarData from FlSpot list
      final lineChartBarData = LineChartBarData(
        spots: graphPoints,
        isCurved: false,
        color: Colors.blue,
        barWidth: 2,
        isStrokeCapRound: true,
        belowBarData: BarAreaData(show: false),
        dotData: const FlDotData(show: true),
      );

      return ExerciseProgressData(
        graphData: [lineChartBarData],
        tooltipData: tooltipData,
        minScore: minScore.isFinite ? minScore : 0,
        maxScore: maxScore.isFinite ? maxScore : 100,
        maxHistoryDistance: maxHistoryDistance,
        mostRecentDate: latestDate,
      );
    }

    return ExerciseProgressData.empty();
  }

  /// Load and calculate exercise progress graph data for a specific exercise
  /// This method handles exercise data filtering, best set calculation, and graph generation
  Future<ExerciseGraphDataResult> loadExerciseGraphData({
    required String exerciseName,
    required List<Map<String, dynamic>> allTrainingSets,
    required List<ApiExercise> exercises, // Add exercises parameter
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) async {
    try {
      // Find the exercise object for this exercise name
      ApiExercise? exercise;
      try {
        exercise = exercises.firstWhere((e) => e.name == exerciseName);
      } catch (e) {
        exercise = null;
      }

      // Filter for the selected exercise (exclude warmups)
      List<Map<String, dynamic>> exerciseTrainingSets = allTrainingSets
          .where((t) => t['exercise_name'] == exerciseName && t['set_type'] > 0)
          .toList();

      if (exerciseTrainingSets.isEmpty) {
        return ExerciseGraphDataResult.empty();
      }

      // Apply date filtering (same logic as other statistics)
      if (startingDate != null || endingDate != null) {
        exerciseTrainingSets = exerciseTrainingSets.where((t) {
          try {
            final date = DateTime.parse(t['date']);
            bool includeSet = true;

            if (startingDate != null) {
              var tokens = startingDate.split("-");
              String startingDateString =
                  "${tokens[2]}-${tokens[1]}-${tokens[0]}T00:00:00";
              DateTime start = DateTime.parse(startingDateString);
              includeSet = includeSet &&
                  (date.isAfter(start) || date.isAtSameMomentAs(start));
            }

            if (endingDate != null) {
              var tokens = endingDate.split("-");
              String endingDateString =
                  "${tokens[2]}-${tokens[1]}-${tokens[0]}T23:59:59";
              DateTime end = DateTime.parse(endingDateString);
              includeSet = includeSet &&
                  (date.isBefore(end) || date.isAtSameMomentAs(end));
            }

            return includeSet;
          } catch (e) {
            return false;
          }
        }).toList();
      } else if (useDefaultFilter) {
        // Apply 90-day default filter for exercise graph too
        exerciseTrainingSets.sort((a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
        if (exerciseTrainingSets.length > 90) {
          // Get unique training dates first
          Set<String> uniqueDates = {};
          List<Map<String, dynamic>> filteredSets = [];

          for (var set in exerciseTrainingSets) {
            final date = DateTime.parse(set['date']);
            String dateKey =
                "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
            if (!uniqueDates.contains(dateKey)) {
              uniqueDates.add(dateKey);
              if (uniqueDates.length <= 90) {
                filteredSets.add(set);
              }
            } else if (uniqueDates.length <= 90) {
              filteredSets.add(set);
            }
          }
          exerciseTrainingSets = filteredSets;
        }
      }

      // Group by date and find best set per day
      Map<String, Map<String, dynamic>> bestSetPerDay = {};

      for (var setData in exerciseTrainingSets) {
        final date = DateTime.parse(setData['date']);
        String dateKey =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        if (!bestSetPerDay.containsKey(dateKey)) {
          bestSetPerDay[dateKey] = setData;
        } else {
          // Compare with existing best set for this day
          final existing = bestSetPerDay[dateKey]!;
          final currentWeight = setData['weight'] as double;
          final currentReps = setData['repetitions'] as int;
          final existingWeight = existing['weight'] as double;
          final existingReps = existing['repetitions'] as int;

          // Choose better set (higher weight, then more reps)
          if (currentWeight > existingWeight ||
              (currentWeight == existingWeight && currentReps > existingReps)) {
            bestSetPerDay[dateKey] = setData;
          }
        }
      }

      // Create graph data
      List<FlSpot> graphPoints = [];
      Map<double, String> tooltipData = {};

      if (bestSetPerDay.isNotEmpty) {
        // Sort dates and find range
        var sortedDates = bestSetPerDay.keys.toList()..sort();
        final earliestDate = DateTime.parse(sortedDates.first);
        final latestDate = DateTime.parse(sortedDates.last);

        // Calculate scores and create points
        double minScore = double.infinity;
        double maxScore = double.negativeInfinity;

        for (String dateKey in sortedDates) {
          final date = DateTime.parse(dateKey);
          final setData = bestSetPerDay[dateKey]!;

          // Create ApiTrainingSet for score calculation
          final trainingSet = ApiTrainingSet(
            weight: setData['weight'] as double,
            repetitions: setData['repetitions'] as int,
            // baseReps: setData['base_reps'] as int,
            // maxReps: setData['max_reps'] as int,
            // increment: setData['increment'] as double,
            date: date,
            setType: setData['set_type'] as int,
            exerciseId: setData['exercise_id'] as int,
            exerciseName: exerciseName,
            userName: '',
          );

          double xValue = -latestDate.difference(date).inDays.toDouble();
          double yValue = _calculateScoreForSet(trainingSet, exercise);

          graphPoints.add(FlSpot(xValue, yValue));
          tooltipData[xValue] =
              "${setData['weight']}kg @ ${setData['repetitions']}reps ($dateKey)";

          minScore = min(minScore, yValue);
          maxScore = max(maxScore, yValue);
        }

        // Calculate max history distance
        double maxHistoryDistance =
            max(2.0, latestDate.difference(earliestDate).inDays.toDouble());

        // Create line chart data
        final lineChartData = LineChartBarData(
          spots: graphPoints,
          isCurved: false,
          curveSmoothness: 0.2,
          color: Colors.blue,
          barWidth: 2,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: true),
        );

        // Convert tooltip data to integer keys
        Map<int, List<String>> intTooltipData = {};
        for (var entry in tooltipData.entries) {
          intTooltipData[entry.key.toInt()] = [entry.value];
        }

        return ExerciseGraphDataResult(
          graphData: [lineChartData],
          tooltipData: intTooltipData,
          minScore: minScore.isFinite ? minScore : 0,
          maxScore: maxScore.isFinite ? maxScore : 100,
          maxHistoryDistance: maxHistoryDistance,
          mostRecentDate: latestDate,
        );
      }

      return ExerciseGraphDataResult.empty();
    } catch (e) {
      print('Error loading exercise graph data: $e');
      return ExerciseGraphDataResult.empty();
    }
  }

  /// Calculate score for a training set using the appropriate method
  double _calculateScoreForSet(
      ApiTrainingSet trainingSet, ApiExercise? exercise) {
    if (exercise != null) {
      return globals.calculateScoreWithExercise(trainingSet, exercise);
    } else {
      // Fallback: return 0 or use a simple calculation
      return 0.0;
    }
  }

  /// Get week of year for a given date
  int _getWeekOfYear(DateTime date) {
    int dayOfYear = int.parse(DateTime(date.year, date.month, date.day)
        .difference(DateTime(date.year, 1, 1))
        .inDays
        .toString());
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Calculate comprehensive muscle and bar chart statistics
  /// This method handles muscle mapping, training set analysis, and bar chart generation
  Future<StatisticsCalculationResult> calculateBarStatistics({
    required List<Map<String, dynamic>> trainingSets,
    required List<ApiExercise> exercises,
    required List<DateTime> filteredTrainingDates,
  }) async {
    try {
      // Muscle mapping from muscle group names to indices
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

      // Create exercise mapping from exercises to muscle involvement
      Map<String, List<Tuple2<int, double>>> exerciseMapping = {};
      for (var exercise in exercises) {
        List<Tuple2<int, double>> intermediateMap = [];
        for (int i = 0; i < exercise.muscleGroups.length; ++i) {
          String muscleName = exercise.muscleGroups[i];
          var muscleIndex = muscleMapping[muscleName];
          if (muscleIndex != null) {
            double intensity = muscleIndex < exercise.muscleIntensities.length
                ? exercise.muscleIntensities[muscleIndex]
                : 0.0;
            intermediateMap.add(Tuple2<int, double>(muscleIndex, intensity));
          }
        }
        exerciseMapping[exercise.name] = intermediateMap;
      }

      // Calculate muscle history scores for each training day
      List<List<double>> muscleHistoryScore = [];
      for (var day in filteredTrainingDates) {
        // Filter training sets for this specific day
        var dayTrainingSets = trainingSets.where((trainingSet) {
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

      // Generate bar chart statistics from muscle history scores
      List<List<BarChartGroupData>> barChartStatistics = [];
      for (var i = 0; i < muscleHistoryScore.length; ++i) {
        var currentScore = muscleHistoryScore[i];
        List<double> accumulatedScore = [0.0];
        for (var d in currentScore) {
          accumulatedScore.add(accumulatedScore.last + d);
        }
        barChartStatistics.add(generateBars(i, accumulatedScore, muscleColors));
      }

      // Calculate heat map data
      List<double> heatMapData = calculateHeatMapData(muscleHistoryScore);

      return StatisticsCalculationResult(
        muscleHistoryScore: muscleHistoryScore,
        barChartStatistics: barChartStatistics,
        heatMapData: heatMapData,
      );
    } catch (e) {
      print('Error calculating bar statistics: $e');
      return StatisticsCalculationResult.empty();
    }
  }
}

/// Result class for comprehensive statistics calculations
class StatisticsCalculationResult {
  final List<List<double>> muscleHistoryScore;
  final List<List<BarChartGroupData>> barChartStatistics;
  final List<double> heatMapData;

  const StatisticsCalculationResult({
    required this.muscleHistoryScore,
    required this.barChartStatistics,
    required this.heatMapData,
  });

  /// Create empty result
  factory StatisticsCalculationResult.empty() {
    return const StatisticsCalculationResult(
      muscleHistoryScore: [],
      barChartStatistics: [],
      heatMapData: [],
    );
  }
}

/// Result class for exercise graph data loading operations
class ExerciseGraphDataResult {
  final List<LineChartBarData> graphData;
  final Map<int, List<String>> tooltipData;
  final double minScore;
  final double maxScore;
  final double maxHistoryDistance;
  final DateTime? mostRecentDate;

  const ExerciseGraphDataResult({
    required this.graphData,
    required this.tooltipData,
    required this.minScore,
    required this.maxScore,
    required this.maxHistoryDistance,
    this.mostRecentDate,
  });

  /// Create empty result
  factory ExerciseGraphDataResult.empty() {
    return const ExerciseGraphDataResult(
      graphData: [],
      tooltipData: {},
      minScore: 0,
      maxScore: 100,
      maxHistoryDistance: 90,
      mostRecentDate: null,
    );
  }
}
