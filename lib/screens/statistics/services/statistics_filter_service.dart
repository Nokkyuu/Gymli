import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:intl/intl.dart';

/// Service responsible for date filtering operations in statistics
class StatisticsFilterService {
  /// Standard filter period in days (default: 3 months ≈ 90 days)
  static const int defaultFilterDays = 90;

  /// Cache expiry time in minutes
  static const int cacheExpiryMinutes = 5;

  /// Exercise graph limit for training days
  static const int exerciseGraphLimit = 90;

  /// Filter training sets by date range
  List<Map<String, dynamic>> filterTrainingSets({
    required List<Map<String, dynamic>> trainingSets,
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) {
    List<Map<String, dynamic>> filtered = List.from(trainingSets);

    if (useDefaultFilter && startingDate == null && endingDate == null) {
      // Use last 3 months (90 days) by default
      final cutoffDate =
          DateTime.now().subtract(const Duration(days: defaultFilterDays));
      filtered = filtered.where((trainingSet) {
        try {
          final date = DateTime.parse(trainingSet['date']);
          return (date.isAfter(cutoffDate) ||
                  date.isAtSameMomentAs(cutoffDate)) &&
              trainingSet['set_type'] > 0; // Only count work sets
        } catch (e) {
          return false;
        }
      }).toList();
    } else {
      // Apply custom date filtering
      if (startingDate != null) {
        final start = _parseDateFromString(startingDate, isStartOfDay: true);
        filtered = filtered.where((trainingSet) {
          try {
            final date = DateTime.parse(trainingSet['date']);
            return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
                trainingSet['set_type'] > 0; // Only count work sets
          } catch (e) {
            return false;
          }
        }).toList();
      }

      if (endingDate != null) {
        final end = _parseDateFromString(endingDate, isStartOfDay: false);
        filtered = filtered.where((trainingSet) {
          try {
            final date = DateTime.parse(trainingSet['date']);
            return (date.isBefore(end) || date.isAtSameMomentAs(end)) &&
                trainingSet['set_type'] > 0; // Only count work sets
          } catch (e) {
            return false;
          }
        }).toList();
      }
    }

    return filtered;
  }

  /// Filter training dates by date range
  List<DateTime> filterTrainingDates({
    required List<DateTime> trainingDates,
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) {
    List<DateTime> filtered = List.from(trainingDates);

    if (useDefaultFilter && startingDate == null && endingDate == null) {
      // Use last 3 months (90 calendar days) by default
      final cutoffDate =
          DateTime.now().subtract(const Duration(days: defaultFilterDays));
      filtered = filtered
          .where((d) => d.isAfter(cutoffDate) || d.isAtSameMomentAs(cutoffDate))
          .toList();
    } else {
      // Apply custom date filtering
      if (startingDate != null) {
        final start = _parseDateFromString(startingDate, isStartOfDay: true);
        filtered = filtered
            .where((d) => d.isAfter(start) || d.isAtSameMomentAs(start))
            .toList();
      }

      if (endingDate != null) {
        final end = _parseDateFromString(endingDate, isStartOfDay: false);
        filtered = filtered
            .where((d) => d.isBefore(end) || d.isAtSameMomentAs(end))
            .toList();
      }
    }

    return filtered;
  }

  /// Filter exercise training sets with 90-day limit logic
  List<Map<String, dynamic>> filterExerciseTrainingSets({
    required List<Map<String, dynamic>> exerciseTrainingSets,
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) {
    List<Map<String, dynamic>> filtered = List.from(exerciseTrainingSets);

    // Apply date filtering (same logic as other statistics)
    if (startingDate != null || endingDate != null) {
      filtered = filtered.where((t) {
        try {
          final date = DateTime.parse(t['date']);
          bool includeSet = true;

          if (startingDate != null) {
            final start =
                _parseDateFromString(startingDate, isStartOfDay: true);
            includeSet = includeSet &&
                (date.isAfter(start) || date.isAtSameMomentAs(start));
          }

          if (endingDate != null) {
            final end = _parseDateFromString(endingDate, isStartOfDay: false);
            includeSet = includeSet &&
                (date.isBefore(end) || date.isAtSameMomentAs(end));
          }

          return includeSet;
        } catch (e) {
          return false;
        }
      }).toList();
    } else if (useDefaultFilter) {
      // Apply 3-month (90-day) default filter for exercise graph too
      filtered.sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

      if (filtered.length > 90) {
        // Get unique training dates first
        Set<String> uniqueDates = {};
        List<Map<String, dynamic>> filteredSets = [];

        for (var set in filtered) {
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
        filtered = filteredSets;
      }
    }

    return filtered;
  }

  /// Extract unique training dates from training sets (work sets only)
  List<DateTime> extractTrainingDates(List<Map<String, dynamic>> trainingSets) {
    Set<DateTime> uniqueDates = {};

    for (var trainingSet in trainingSets) {
      try {
        final date = DateTime.parse(trainingSet['date']);
        // Only count work sets (set_type > 0), not warmups
        if (trainingSet['set_type'] > 0) {
          uniqueDates.add(DateTime(date.year, date.month, date.day));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing date: $e');
        }
      }
    }

    return uniqueDates.toList()..sort();
  }

  /// Format training dates for dropdown menus
  List<String> formatTrainingDatesForDropdown(List<DateTime> trainingDates) {
    return trainingDates
        .map((d) => DateFormat('dd-MM-yyyy').format(d))
        .toList();
  }

  /// Check if date filtering should show snackbar notification
  bool shouldShowFilterNotification({
    required int originalCount,
    required int filteredCount,
    required bool useDefaultFilter,
    String? startingDate,
    String? endingDate,
  }) {
    return useDefaultFilter &&
        startingDate == null &&
        endingDate == null &&
        originalCount > filteredCount &&
        filteredCount > 0;
  }

  /// Get filter notification message
  String getFilterNotificationMessage({
    required int filteredCount,
    required int originalCount,
  }) {
    return 'Showing last 3 months ($filteredCount training days from $originalCount total)';
  }

  /// Validate date range inputs
  bool isValidDateRange(String? startingDate, String? endingDate) {
    if (startingDate == null || endingDate == null) return true;

    try {
      final start = _parseDateFromString(startingDate, isStartOfDay: true);
      final end = _parseDateFromString(endingDate, isStartOfDay: false);
      return start.isBefore(end) || start.isAtSameMomentAs(end);
    } catch (e) {
      return false;
    }
  }

  /// Parse date string from DD-MM-YYYY format
  DateTime _parseDateFromString(String dateString,
      {required bool isStartOfDay}) {
    var tokens = dateString.split("-");
    if (tokens.length != 3) {
      throw FormatException('Invalid date format: $dateString');
    }

    String isoString = isStartOfDay
        ? "${tokens[2]}-${tokens[1]}-${tokens[0]}T00:00:00"
        : "${tokens[2]}-${tokens[1]}-${tokens[0]}T23:59:59";

    return DateTime.parse(isoString);
  }
}
