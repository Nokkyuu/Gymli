/// Activity Controller - Manages data operations for activities
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import '../../../utils/api/api_models.dart';

class ActivityController extends ChangeNotifier {
  final TempService container = TempService();

  // Data lists
  List<ApiActivity> activities = [];
  List<ApiActivityLog> activityLogs = [];
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
      final activitiesData = await container.activityService.getActivities();
      final logsData = await container.activityService.getActivityLogs();
      //final statsData = await container.activityService.getActivityStats();

      activities =
          activitiesData.map((data) => ApiActivity.fromJson(data)).toList();
      activityLogs =
          logsData.map((data) => ApiActivityLog.fromJson(data)).toList();
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
      await container.activityService.createActivityLog(
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
      final result = await container.activityService.createActivity(
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
      await container.activityService.deleteActivityLog(logId: logId);
      await loadData();
    } catch (e) {
      if (kDebugMode) print('Error deleting activity log: $e');
      rethrow;
    }
  }

  /// Delete an activity
  Future<void> deleteActivity(int activityId) async {
    try {
      await container.activityService.deleteActivity(activityId: activityId);
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
          : ApiActivity(
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
  bool shouldShowDeleteButton(ApiActivity activity) {
    if (activity.id == null) return false;

    if (container.authService.isLoggedIn) {
      // Logged-in users can delete any activity
      return true;
    } else {
      // Non-authenticated users can only delete custom activities
      return activity.id! > 16;
    }
  }

  /// Get sorted activity logs (newest first)
  List<ApiActivityLog> get sortedActivityLogs {
    final sortedLogs = List<ApiActivityLog>.from(activityLogs);
    sortedLogs.sort((a, b) => b.date.compareTo(a.date));
    return sortedLogs;
  }
}
