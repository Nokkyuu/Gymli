/// Statistics Data Service - Data fetching and caching for statistics screen
///
/// This service handles all data operations for the statistics screen including:
/// - Training sets retrieval with caching
/// - Exercise data loading
/// - Activity data management
/// - Cache invalidation and management
/// - Smart data loading to prevent redundant API calls
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:Gymli/utils/services/service_container.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../../utils/api/api_models.dart';
import '../../../utils/api/api_models.dart';
import 'statistics_filter_service.dart';

/// Service responsible for data fetching and caching for statistics
class StatisticsDataService {
  final ServiceContainer container;

  // Caching variables to prevent redundant API calls
  List<Map<String, dynamic>>? _cachedTrainingSets;
  List<ApiExercise>? _cachedExercises;
  List<dynamic>? _cachedActivityLogs;
  Map<String, dynamic>? _cachedActivityStats;
  bool _dataCacheValid = false;
  DateTime? _lastCacheTime;

  StatisticsDataService(this.container);

  /// Check if cache is expired based on configured cache expiry time
  bool get _isCacheExpired {
    if (_lastCacheTime == null) return true;
    return DateTime.now().difference(_lastCacheTime!).inMinutes >
        StatisticsFilterService.cacheExpiryMinutes;
  }

  /// Invalidate all cached data
  void invalidateCache() {
    _cachedTrainingSets = null;
    _cachedExercises = null;
    _cachedActivityLogs = null;
    _cachedActivityStats = null;
    _dataCacheValid = false;
    _lastCacheTime = null;
    if (kDebugMode) print('Statistics data cache invalidated');
  }

  /// Get training sets with smart caching
  Future<List<Map<String, dynamic>>> getTrainingSets() async {
    if (_cachedTrainingSets == null || !_dataCacheValid || _isCacheExpired) {
      if (kDebugMode) print('Loading training sets from API...');
      final rawData = await container.trainingSetService.getTrainingSets();
      _cachedTrainingSets = rawData.cast<Map<String, dynamic>>();
      _dataCacheValid = true;
      _lastCacheTime = DateTime.now();
    } else {
      if (kDebugMode) print('Using cached training sets');
    }
    return _cachedTrainingSets!;
  }

  /// Get exercises with smart caching
  Future<List<ApiExercise>> getExercises() async {
    if (_cachedExercises == null || !_dataCacheValid || _isCacheExpired) {
      if (kDebugMode) print('Loading exercises from API...');
      final exercisesData = await container.exerciseService.getExercises();
      _cachedExercises =
          exercisesData.map((e) => ApiExercise.fromJson(e)).toList();
      _dataCacheValid = true;
      _lastCacheTime = DateTime.now();
    } else {
      if (kDebugMode) print('Using cached exercises');
    }
    return _cachedExercises!;
  }

  /// Get activity logs with caching
  Future<List<dynamic>> getActivityLogs() async {
    if (_cachedActivityLogs == null || !_dataCacheValid || _isCacheExpired) {
      if (kDebugMode) print('Loading activity logs from API...');
      _cachedActivityLogs = await container.activityService.getActivityLogs();
      _dataCacheValid = true;
      _lastCacheTime = DateTime.now();
    } else {
      if (kDebugMode) print('Using cached activity logs');
    }
    return _cachedActivityLogs!;
  }

  /// Get activity statistics with caching
  Future<Map<String, dynamic>> getActivityStats() async {
    if (_cachedActivityStats == null || !_dataCacheValid || _isCacheExpired) {
      if (kDebugMode) print('Loading activity stats from API...');
      _cachedActivityStats = await container.activityService.getActivityStats();
      _dataCacheValid = true;
      _lastCacheTime = DateTime.now();
    } else {
      if (kDebugMode) print('Using cached activity stats');
    }
    return _cachedActivityStats!;
  }

  /// Load and process activity statistics and trend data
  /// This method handles activity stats, logs filtering, and trend calculations
  Future<ActivityDataResult> loadActivityData({
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) async {
    try {
      // Load activity statistics from API
      final statsData = await container.activityService.getActivityStats();
      if (kDebugMode) print('Activity stats loaded: $statsData');

      // Load activity logs for trend data
      final logsData = await container.activityService.getActivityLogs();
      if (kDebugMode) print('Activity logs count: ${logsData.length}');

      // Convert logs to ApiActivityLog objects and sort by date
      final activityLogs =
          logsData.map((data) => ApiActivityLog.fromJson(data)).toList();
      activityLogs.sort((a, b) => a.date.compareTo(b.date));

      // Apply date filtering (same logic as other statistics)
      List<ApiActivityLog> filteredActivityLogs = List.from(activityLogs);

      // Apply the same filtering logic as in _loadStatistics
      if (useDefaultFilter && startingDate == null && endingDate == null) {
        // Use last 90 days by default
        final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
        filteredActivityLogs = filteredActivityLogs
            .where((log) =>
                log.date.isAfter(cutoffDate) ||
                log.date.isAtSameMomentAs(cutoffDate))
            .toList();
      } else {
        // Apply custom date filtering
        if (startingDate != null) {
          var tokens = startingDate.split("-");
          String startingDateString =
              "${tokens[2]}-${tokens[1]}-${tokens[0]}T00:00:00";
          DateTime start = DateTime.parse(startingDateString);
          filteredActivityLogs = filteredActivityLogs
              .where((log) =>
                  log.date.isAfter(start) || log.date.isAtSameMomentAs(start))
              .toList();
        }
        if (endingDate != null) {
          var tokens = endingDate.split("-");
          String endingDateString =
              "${tokens[2]}-${tokens[1]}-${tokens[0]}T23:59:59";
          DateTime end = DateTime.parse(endingDateString);
          filteredActivityLogs = filteredActivityLogs
              .where((log) =>
                  log.date.isBefore(end) || log.date.isAtSameMomentAs(end))
              .toList();
        }
      }

      // Calculate filtered statistics from the filtered activity logs
      Map<String, dynamic> filteredStats = {
        'total_sessions': filteredActivityLogs.length,
        'total_duration_minutes': filteredActivityLogs.fold(
            0, (sum, log) => sum + log.durationMinutes),
        'total_calories_burned': filteredActivityLogs.fold(
            0.0, (sum, log) => sum + log.caloriesBurned),
      };

      // Calculate averages if we have data
      if (filteredStats['total_sessions'] > 0) {
        filteredStats['average_session_duration'] =
            filteredStats['total_duration_minutes'] /
                filteredStats['total_sessions'];
        filteredStats['average_calories_per_session'] =
            filteredStats['total_calories_burned'] /
                filteredStats['total_sessions'];
      } else {
        filteredStats['average_session_duration'] = 0.0;
        filteredStats['average_calories_per_session'] = 0.0;
      }

      // Group activities by day and aggregate values for chart data
      Map<String, Map<String, double>> dailyAggregates = {};

      for (final log in filteredActivityLogs) {
        // Create date key (YYYY-MM-DD)
        final dateKey =
            "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";

        if (!dailyAggregates.containsKey(dateKey)) {
          dailyAggregates[dateKey] = {
            'calories': 0.0,
            'duration': 0.0,
          };
        }

        // Aggregate values for the day
        dailyAggregates[dateKey]!['calories'] =
            dailyAggregates[dateKey]!['calories']! + log.caloriesBurned;
        dailyAggregates[dateKey]!['duration'] =
            dailyAggregates[dateKey]!['duration']! +
                log.durationMinutes.toDouble();
      }

      // Create chart data points from aggregated daily data
      final caloriesTrendData = <FlSpot>[];
      final durationTrendData = <FlSpot>[];

      if (dailyAggregates.isNotEmpty) {
        // Sort dates and create points
        final sortedDates = dailyAggregates.keys.toList()..sort();
        final earliestDate = DateTime.parse(sortedDates.first);

        for (final dateKey in sortedDates) {
          final date = DateTime.parse(dateKey);
          final dayIndex = date.difference(earliestDate).inDays.toDouble();
          final dailyData = dailyAggregates[dateKey]!;

          caloriesTrendData.add(FlSpot(dayIndex, dailyData['calories']!));
          durationTrendData.add(FlSpot(dayIndex, dailyData['duration']!));
        }
      }

      return ActivityDataResult(
        activityStats: filteredStats,
        caloriesTrendData: caloriesTrendData,
        durationTrendData: durationTrendData,
      );
    } catch (e) {
      if (kDebugMode) print('Error loading activity data: $e');
      return ActivityDataResult.empty();
    }
  }

  /// Force refresh all data (bypass cache)
  Future<void> refreshAllData() async {
    invalidateCache();
    await Future.wait([
      getTrainingSets(),
      getExercises(),
      getActivityLogs(),
      getActivityStats(),
    ]);
  }

  /// Check if any cached data exists
  bool get hasValidCache => _dataCacheValid && !_isCacheExpired;

  /// Get cache status information
  Map<String, dynamic> getCacheStatus() {
    return {
      'valid': _dataCacheValid,
      'expired': _isCacheExpired,
      'lastUpdate': _lastCacheTime?.toIso8601String(),
      'trainingSetsCount': _cachedTrainingSets?.length ?? 0,
      'exercisesCount': _cachedExercises?.length ?? 0,
      'activityLogsCount': _cachedActivityLogs?.length ?? 0,
    };
  }
}

/// Result class for activity data loading operations
class ActivityDataResult {
  final Map<String, dynamic> activityStats;
  final List<FlSpot> caloriesTrendData;
  final List<FlSpot> durationTrendData;

  const ActivityDataResult({
    required this.activityStats,
    required this.caloriesTrendData,
    required this.durationTrendData,
  });

  /// Create empty result
  factory ActivityDataResult.empty() {
    return const ActivityDataResult(
      activityStats: {},
      caloriesTrendData: [],
      durationTrendData: [],
    );
  }
}
