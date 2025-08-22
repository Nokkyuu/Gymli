/// ActivityService - Manages activity types and activity logs
///
/// This service handles all CRUD operations for activities and activity logs,
/// which are used for tracking cardio and other physical activities.
///
library;

import 'dart:convert';
import 'api_base.dart';

class ActivityService {
  /// Retrieves all activities for a user
  /// Returns a list of activity objects
  Future<List<dynamic>> getActivities() async {
    return getData<List<dynamic>>('activities');
  }

  /// Creates a new custom activity for a user
  Future<Map<String, dynamic>> createActivity({
    required String name,
    required double kcalPerHour,
  }) async {
    return json.decode(await createData('activities', {
      'name': name,
      'kcal_per_hour': kcalPerHour,
    }));
  }

  /// Updates an existing activity
  Future<Map<String, dynamic>> updateActivity({
    required int activityId,
    required String name,
    required double kcalPerHour,
  }) async {
    final response = await updateData(
        'activities/$activityId', {'name': name, 'kcal_per_hour': kcalPerHour});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update activity: ${response.body}');
    }
  }

  /// Deletes an activity
  Future<void> deleteActivity({
    required int activityId,
  }) async {
    final response = await deleteData('activities/$activityId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete activity: ${response.body}');
    }
  }

  /// Retrieves activity logs with optional filtering
  Future<List<dynamic>> getActivityLogs({
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
    return getData<List<dynamic>>(url);
  }

  /// Creates a new activity log entry
  Future<Map<String, dynamic>> createActivityLog({
    required String activityName,
    required DateTime date,
    required int durationMinutes,
    String? notes,
  }) async {
    return json.decode(await createData('activity_logs', {
      'activity_name': activityName,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'notes': notes,
    }));
  }

  /// Retrieves activity statistics for a user
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
      throw Exception('Failed to delete activity log: ${response.body}');
    }
  }
}
