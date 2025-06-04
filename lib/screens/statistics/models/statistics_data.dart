/// Statistics Data Models
///
/// This file contains data models and classes used throughout the statistics screen
/// for better type safety and data organization.
library;

import 'package:fl_chart/fl_chart.dart';

/// Model for filter options used in statistics
class StatisticsFilter {
  final String? startDate;
  final String? endDate;
  final bool useDefaultFilter;

  const StatisticsFilter({
    this.startDate,
    this.endDate,
    this.useDefaultFilter = true,
  });

  /// Create a copy of this filter with modified values
  StatisticsFilter copyWith({
    String? startDate,
    String? endDate,
    bool? useDefaultFilter,
  }) {
    return StatisticsFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      useDefaultFilter: useDefaultFilter ?? this.useDefaultFilter,
    );
  }

  /// Check if custom dates are set
  bool get hasCustomDates => startDate != null || endDate != null;

  /// Check if filter is empty (no dates set and using default)
  bool get isEmpty => !hasCustomDates && useDefaultFilter;
}

/// Model for basic statistics overview
class StatisticsOverview {
  final int numberOfTrainingDays;
  final String trainingDuration;
  final int freeWeightsCount;
  final int machinesCount;
  final int cablesCount;
  final int bodyweightCount;
  final Map<String, dynamic> activityStats;

  const StatisticsOverview({
    required this.numberOfTrainingDays,
    required this.trainingDuration,
    required this.freeWeightsCount,
    required this.machinesCount,
    required this.cablesCount,
    required this.bodyweightCount,
    required this.activityStats,
  });

  /// Create an empty statistics overview
  factory StatisticsOverview.empty() {
    return const StatisticsOverview(
      numberOfTrainingDays: 0,
      trainingDuration: "No training data available",
      freeWeightsCount: 0,
      machinesCount: 0,
      cablesCount: 0,
      bodyweightCount: 0,
      activityStats: {},
    );
  }
}

/// Model for chart data used in various visualizations
class ChartDataSet {
  final List<LineChartBarData> trainingsPerWeekData;
  final List<BarChartGroupData> muscleUsageData;
  final List<FlSpot> caloriesTrendData;
  final List<FlSpot> durationTrendData;
  final List<double> heatMapData;

  const ChartDataSet({
    required this.trainingsPerWeekData,
    required this.muscleUsageData,
    required this.caloriesTrendData,
    required this.durationTrendData,
    required this.heatMapData,
  });

  /// Create an empty chart data set
  factory ChartDataSet.empty() {
    return const ChartDataSet(
      trainingsPerWeekData: [],
      muscleUsageData: [],
      caloriesTrendData: [],
      durationTrendData: [],
      heatMapData: [],
    );
  }
}

/// Model for exercise progress data
class ExerciseProgressData {
  final List<LineChartBarData> graphData;
  final Map<int, List<String>> tooltipData;
  final double minScore;
  final double maxScore;
  final double maxHistoryDistance;
  final DateTime? mostRecentDate;

  const ExerciseProgressData({
    required this.graphData,
    required this.tooltipData,
    required this.minScore,
    required this.maxScore,
    required this.maxHistoryDistance,
    this.mostRecentDate,
  });

  /// Create empty exercise progress data
  factory ExerciseProgressData.empty() {
    return const ExerciseProgressData(
      graphData: [],
      tooltipData: {},
      minScore: 0,
      maxScore: 100,
      maxHistoryDistance: 90,
      mostRecentDate: null,
    );
  }
}

/// Model for equipment usage statistics
class EquipmentUsage {
  final int freeWeights;
  final int machines;
  final int cables;
  final int bodyweight;

  const EquipmentUsage({
    required this.freeWeights,
    required this.machines,
    required this.cables,
    required this.bodyweight,
  });

  /// Create empty equipment usage
  factory EquipmentUsage.empty() {
    return const EquipmentUsage(
      freeWeights: 0,
      machines: 0,
      cables: 0,
      bodyweight: 0,
    );
  }

  /// Get total exercise count
  int get total => freeWeights + machines + cables + bodyweight;
}

/// Model for activity statistics
class ActivityStatistics {
  final int totalSessions;
  final int totalDurationMinutes;
  final double totalCaloriesBurned;
  final double averageSessionDuration;
  final double averageCaloriesPerSession;

  const ActivityStatistics({
    required this.totalSessions,
    required this.totalDurationMinutes,
    required this.totalCaloriesBurned,
    required this.averageSessionDuration,
    required this.averageCaloriesPerSession,
  });

  /// Create from raw API data
  factory ActivityStatistics.fromMap(Map<String, dynamic> data) {
    final totalSessions = data['total_sessions'] ?? 0;
    final totalDuration = data['total_duration_minutes'] ?? 0;
    final totalCalories = (data['total_calories_burned'] ?? 0.0).toDouble();

    return ActivityStatistics(
      totalSessions: totalSessions,
      totalDurationMinutes: totalDuration,
      totalCaloriesBurned: totalCalories,
      averageSessionDuration:
          totalSessions > 0 ? totalDuration / totalSessions : 0.0,
      averageCaloriesPerSession:
          totalSessions > 0 ? totalCalories / totalSessions : 0.0,
    );
  }

  /// Create empty activity statistics
  factory ActivityStatistics.empty() {
    return const ActivityStatistics(
      totalSessions: 0,
      totalDurationMinutes: 0,
      totalCaloriesBurned: 0.0,
      averageSessionDuration: 0.0,
      averageCaloriesPerSession: 0.0,
    );
  }

  /// Get formatted calories display value
  String get formattedCalories => totalCaloriesBurned.toStringAsFixed(0);
}

/// Enum for different statistics view types
enum StatisticsViewType {
  overview,
  trainingsPerWeek,
  muscleUsage,
  heatmap,
  exerciseProgress,
  activities,
}

/// Extension to get display names for statistics view types
extension StatisticsViewTypeExtension on StatisticsViewType {
  String get displayName {
    switch (this) {
      case StatisticsViewType.overview:
        return "Statistics Overview";
      case StatisticsViewType.trainingsPerWeek:
        return "Trainings per Week";
      case StatisticsViewType.muscleUsage:
        return "Muscle Usage per Exercise";
      case StatisticsViewType.heatmap:
        return "Muscle Heatmap";
      case StatisticsViewType.exerciseProgress:
        return "Exercise Progress";
      case StatisticsViewType.activities:
        return "Activities";
    }
  }
}

/// Model for date range parsing result
class DateRange {
  final DateTime? start;
  final DateTime? end;
  final bool isValid;

  const DateRange({
    this.start,
    this.end,
    required this.isValid,
  });

  /// Create invalid date range
  factory DateRange.invalid() {
    return const DateRange(isValid: false);
  }

  /// Parse date range from string format (dd-MM-yyyy)
  factory DateRange.fromStrings(String? startDate, String? endDate) {
    try {
      DateTime? start;
      DateTime? end;

      if (startDate != null) {
        final startParts = startDate.split('-');
        start = DateTime(
          int.parse(startParts[2]), // year
          int.parse(startParts[1]), // month
          int.parse(startParts[0]), // day
        );
      }

      if (endDate != null) {
        final endParts = endDate.split('-');
        end = DateTime(
          int.parse(endParts[2]), // year
          int.parse(endParts[1]), // month
          int.parse(endParts[0]), // day
          23, 59, 59, // end of day
        );
      }

      return DateRange(
        start: start,
        end: end,
        isValid: true,
      );
    } catch (e) {
      return DateRange.invalid();
    }
  }

  /// Check if date is within this range
  bool contains(DateTime date) {
    if (!isValid) return false;

    bool afterStart =
        start == null || date.isAfter(start!) || date.isAtSameMomentAs(start!);
    bool beforeEnd =
        end == null || date.isBefore(end!) || date.isAtSameMomentAs(end!);

    return afterStart && beforeEnd;
  }
}
