/// Activity Controller - Manages data operations for activities
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import '../../../utils/models/data_models.dart';
import 'package:Gymli/utils/api/api_export.dart';
import 'package:get_it/get_it.dart';
//import 'package:Gymli/utils/services/auth_service.dart';

class ActivityController extends ChangeNotifier {
  final TempService container = GetIt.I<TempService>();

  // Data lists
  List<Activity> activities = [];
  List<ActivityLog> activityLogs = [];
  Map<String, dynamic> activityStats = {};

  // Loading states
  bool _isLoading = true;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Load all activity data
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load all data - getActivities will handle initialization if needed
      final activitiesData = await GetIt.I<ActivityService>().getActivities();
      final logsData = await GetIt.I<ActivityService>().getActivityLogs();
      //final statsData = await container.activityService.getActivityStats();

      activities =
          activitiesData.map((data) => Activity.fromJson(data)).toList();
      activityLogs =
          logsData.map((data) => ActivityLog.fromJson(data)).toList();
      // activityStats = statsData;

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) print('Error loading activity data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Log an activity
  Future<void> logActivity({
    required String activityName,
    required DateTime date,
    required int durationMinutes,
    String? notes,
  }) async {
    try {
      await GetIt.I<ActivityService>().createActivityLog(
        activityName: activityName,
        date: date,
        durationMinutes: durationMinutes,
        notes: notes,
      );

      // Reload data to reflect changes
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error logging activity: $e');
      rethrow;
    }
  }

  /// Create a custom activity
  Future<void> createCustomActivity({
    required String name,
    required double kcalPerHour,
  }) async {
    try {
      final result = await GetIt.I<ActivityService>().createActivity(
        name: name,
        kcalPerHour: kcalPerHour,
      );

      if (kDebugMode) print('Activity created successfully: $result');

      // Reload data to reflect changes
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error creating custom activity: $e');
      rethrow;
    }
  }

  /// Delete an activity log
  Future<void> deleteActivityLog(int logId) async {
    try {
      await GetIt.I<ActivityService>().deleteActivityLog(logId: logId);
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error deleting activity log: $e');
      rethrow;
    }
  }

  /// Delete an activity
  Future<void> deleteActivity(int activityId) async {
    try {
      await GetIt.I<ActivityService>().deleteActivity(activityId: activityId);
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error deleting activity: $e');
      rethrow;
    }
  }

  /// Calculate calories for a given activity and duration
  double calculateCalories(String? activityName, String durationText) {
    if (activityName == null || durationText.isEmpty) return 0.0;

    final selectedActivity = activities.firstWhere(
      (a) => a.name == activityName,
      orElse: () => activities.isNotEmpty
          ? activities.first
          : Activity(
              id: 0,
              userName: '',
              name: '',
              kcalPerHour: 0,
            ),
    );

    final duration = int.tryParse(durationText) ?? 0;
    return (selectedActivity.kcalPerHour * duration) / 60.0;
  }

  /// Check if delete button should be shown for an activity
  bool shouldShowDeleteButton(Activity activity) {
    if (activity.id == null)
      return false;
    else
      return true;
  }

  /// Get sorted activity logs (newest first)
  List<ActivityLog> get sortedActivityLogs {
    final sortedLogs = List<ActivityLog>.from(activityLogs);
    sortedLogs.sort((a, b) => b.date.compareTo(a.date));
    return sortedLogs;
  }
}
