/// ActivityService - Manages activity types and activity logs
///
/// This service handles all CRUD operations for activities and activity logs,
/// which are used for tracking cardio and other physical activities.
///
library;

import '../api/api_base.dart';
import '../models/data_models.dart';

class ActivityService {
  /// Retrieves all activities for a user
  /// Returns a list of activity objects
  Future<List<Activity>> getActivities() async {
    final data = await getData<List<dynamic>>('activities');
    return data.map((item) => Activity.fromJson(item)).toList();
  }

  /// Creates a new custom activity for a user
  Future<Activity> createActivity({
    required String name,
    required double kcalPerHour,
  }) async {
    final response = await createData('activities', {
      'name': name,
      'kcal_per_hour': kcalPerHour,
    });
    return Activity.fromJson(response);
  }

  /// Updates an existing activity
  Future<Activity> updateActivity({
    required int activityId,
    required String name,
    required double kcalPerHour,
  }) async {
    final response = await updateData(
        'activities/$activityId', {'name': name, 'kcal_per_hour': kcalPerHour});
    if (response.statusCode == 200) {
      return Activity.fromJson(response);
    } else {
      throw Exception('Failed to update activity: ${response}');
    }
  }

  /// Deletes an activity
  Future<void> deleteActivity({
    required int activityId,
  }) async {
    final response = await deleteData('activities/$activityId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete activity: ${response}');
    }
  }

  /// Retrieves activity logs with optional filtering
  Future<List<ActivityLog>> getActivityLogs({
    String? activityName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '/activity_logs';
    if (activityName != null) {
      url += '&activity_name=${Uri.encodeComponent(activityName)}';
    }
    if (startDate != null) {
      url += '&start_date=${startDate.toIso8601String()}';
    }
    if (endDate != null) {
      url += '&end_date=${endDate.toIso8601String()}';
    }
    final data = await getData<List<dynamic>>(url);
    return data.map((item) => ActivityLog.fromJson(item)).toList();
  }

  /// Creates a new activity log entry
  Future<ActivityLog> createActivityLog({
    required String activityName,
    required DateTime date,
    required int durationMinutes,
    String? notes,
  }) async {
    final response = await createData('activity_logs', {
      'activity_name': activityName,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'notes': notes,
    });
    return ActivityLog.fromJson(response);
  }

  /// Retrieves activity statistics for a user
  /// TODO: what does the endpoint return again?
  Future<Map<String, dynamic>> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '/activity_logs/stats?';
    if (startDate != null) {
      url += '&start_date=${startDate.toIso8601String()}';
    }
    if (endDate != null) {
      url += '&end_date=${endDate.toIso8601String()}';
    }
    return getData<Map<String, dynamic>>(url);
  }

  /// Deletes an activity log entry
  Future<void> deleteActivityLog({
    required int logId,
  }) async {
    final response = await deleteData('activity_logs/$logId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete activity log: ${response}');
    }
  }
}
