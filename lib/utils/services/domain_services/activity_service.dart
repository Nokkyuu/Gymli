import '../../api/api.dart' as api;
import '../data_service.dart';

class ActivityService {
  final DataService _dataService = DataService();

  // Getters that delegate to DataService
  bool get isLoggedIn => _dataService.isLoggedIn;
  String get userName => _dataService.userName;

  /// Initializes default activities for a new user
  /// This method should be called when a user first logs in to set up
  /// standard activity types with reasonable calorie estimates
  Future<Map<String, dynamic>> initializeUserActivities() async {
    if (isLoggedIn) {
      return await api.ActivityService()
          .initializeUserActivities(userName: userName);
    } else {
      // For non-authenticated users, set up default activities in memory
      final defaultActivities = [
        {"id": 1, "name": "Walking (casual)", "kcal_per_hour": 200.0},
        {"id": 2, "name": "Walking (brisk)", "kcal_per_hour": 300.0},
        {"id": 3, "name": "Running (light jog)", "kcal_per_hour": 400.0},
        {"id": 4, "name": "Running (moderate)", "kcal_per_hour": 600.0},
        {"id": 5, "name": "Running (fast)", "kcal_per_hour": 800.0},
        {"id": 6, "name": "Cycling (leisurely)", "kcal_per_hour": 300.0},
        {"id": 7, "name": "Cycling (moderate)", "kcal_per_hour": 500.0},
        {"id": 8, "name": "Swimming", "kcal_per_hour": 400.0},
        {"id": 9, "name": "Rowing machine", "kcal_per_hour": 450.0},
        {"id": 10, "name": "Elliptical", "kcal_per_hour": 350.0},
        {"id": 11, "name": "Stair climbing", "kcal_per_hour": 500.0},
        {"id": 12, "name": "Basketball", "kcal_per_hour": 450.0},
        {"id": 13, "name": "Soccer", "kcal_per_hour": 500.0},
        {"id": 14, "name": "Tennis", "kcal_per_hour": 400.0},
        {"id": 15, "name": "Yoga", "kcal_per_hour": 150.0},
        {"id": 16, "name": "Hiking", "kcal_per_hour": 350.0},
      ];

      _dataService.setInMemoryData('activities', defaultActivities);
      _dataService.setInMemoryData('activityLogs', <Map<String, dynamic>>[]);

      return {
        "message":
            "Initialized ${defaultActivities.length} activities for non-authenticated user"
      };
    }
  }

  /// Retrieves all activities for the current user
  /// Automatically initializes default activities if none exist
  /// Returns a list of activity objects with name and kcal_per_hour
  Future<List<dynamic>> getActivities() async {
    if (isLoggedIn) {
      try {
        final activities =
            await api.ActivityService().getActivities(userName: userName);

        // // If no activities exist, initialize them first
        // if (activities.isEmpty) {
        //   await api.ActivityService()
        //       .initializeUserActivities(userName: userName);
        //   // Get the activities again after initialization
        //   return await api.ActivityService().getActivities(userName: userName);
        // }

        return activities;
      } catch (e) {
        if (e.toString().contains('already has activities initialized')) {
          // If we get this error, just try to get activities again
          return await api.ActivityService().getActivities(userName: userName);
        }
        rethrow;
      }
    } else {
      // For non-authenticated users
      final inMemoryActivities = _dataService.getInMemoryData('activities');
      if (inMemoryActivities.isEmpty) {
        // Initialize if empty
        await initializeUserActivities();
        return _dataService.getInMemoryData('activities');
      }
      return inMemoryActivities;
    }
  }

  /// Creates a new custom activity
  /// [name] - The name of the activity
  /// [kcalPerHour] - Calories burned per hour for this activity
  /// Returns the created activity data
  Future<Map<String, dynamic>> createActivity({
    required String name,
    required double kcalPerHour,
  }) async {
    print(
        'ActivityService.createActivity called with name: $name, kcal: $kcalPerHour'); // Debug

    if (isLoggedIn) {
      print('User is logged in, calling API service'); // Debug
      final result = await api.ActivityService().createActivity(
        userName: userName,
        name: name,
        kcalPerHour: kcalPerHour,
      );
      print('API service returned: $result'); // Debug
      return result;
    } else {
      print('User not logged in, storing in memory'); // Debug
      // For non-authenticated users, store in memory
      final activities = _dataService.getInMemoryData('activities');
      final newId = activities.isEmpty
          ? 1
          : (activities
                  .map((a) => a['id'] as int)
                  .reduce((a, b) => a > b ? a : b) +
              1);

      final activity = {
        'id': newId,
        'user_name': 'DefaultUser',
        'name': name,
        'kcal_per_hour': kcalPerHour,
      };

      _dataService.addToInMemoryData('activities', activity);
      print('Added activity to memory: $activity'); // Debug
      return activity;
    }
  }

  /// Updates an existing activity
  /// [activityId] - The ID of the activity to update
  /// [name] - The updated name of the activity
  /// [kcalPerHour] - The updated calories per hour
  /// Returns the updated activity data
  Future<Map<String, dynamic>> updateActivity({
    required int activityId,
    required String name,
    required double kcalPerHour,
  }) async {
    if (isLoggedIn) {
      return await api.ActivityService().updateActivity(
        activityId: activityId,
        userName: userName,
        name: name,
        kcalPerHour: kcalPerHour,
      );
    } else {
      // Update in memory
      final activities = _dataService.getInMemoryData('activities');
      final index = activities.indexWhere((a) => a['id'] == activityId);
      if (index != -1) {
        final updatedActivity = {
          ...activities[index],
          'name': name,
          'kcal_per_hour': kcalPerHour,
        };
        activities[index] = updatedActivity;
        return updatedActivity as Map<String, dynamic>;
      } else {
        throw Exception('Activity not found');
      }
    }
  }

  /// Deletes an activity
  /// [activityId] - The ID of the activity to delete
  Future<void> deleteActivity(int activityId) async {
    if (isLoggedIn) {
      await api.ActivityService().deleteActivity(
        activityId: activityId,
        userName: userName,
      );
    } else {
      // Remove from memory
      _dataService.removeFromInMemoryData(
          'activities', (a) => a['id'] == activityId);
    }
  }

  /// Retrieves activity logs with optional filtering
  /// [activityName] - Optional filter by specific activity name
  /// [startDate] - Optional filter from this date
  /// [endDate] - Optional filter until this date
  /// Returns a list of activity log objects
  Future<List<dynamic>> getActivityLogs({
    String? activityName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (isLoggedIn) {
      return await api.ActivityService().getActivityLogs(
        userName: userName,
        activityName: activityName,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      // Filter in-memory activity logs
      List<dynamic> logs =
          List.from(_dataService.getInMemoryData('activityLogs'));

      if (activityName != null) {
        logs =
            logs.where((log) => log['activity_name'] == activityName).toList();
      }

      if (startDate != null) {
        logs = logs.where((log) {
          final logDate = DateTime.parse(log['date']);
          return logDate.isAfter(startDate) ||
              logDate.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        logs = logs.where((log) {
          final logDate = DateTime.parse(log['date']);
          return logDate.isBefore(endDate) || logDate.isAtSameMomentAs(endDate);
        }).toList();
      }

      return logs;
    }
  }

  /// Creates a new activity log entry
  /// [activityName] - The name of the activity performed
  /// [date] - The date of the activity session
  /// [durationMinutes] - Duration of the activity in minutes
  /// [notes] - Optional notes about the session
  /// Returns the created activity log with calculated calories
  Future<Map<String, dynamic>> createActivityLog({
    required String activityName,
    required DateTime date,
    required int durationMinutes,
    String? notes,
  }) async {
    if (isLoggedIn) {
      return await api.ActivityService().createActivityLog(
        userName: userName,
        activityName: activityName,
        date: date,
        durationMinutes: durationMinutes,
        notes: notes,
      );
    } else {
      // For non-authenticated users, calculate calories and store in memory
      final activities = _dataService.getInMemoryData('activities');
      final activity = activities.firstWhere(
        (a) => a['name'] == activityName,
        orElse: () => null,
      );

      double caloriesBurned = 0.0;
      if (activity != null) {
        final kcalPerHour = activity['kcal_per_hour'] as double;
        caloriesBurned = (kcalPerHour * durationMinutes) / 60.0;
      }

      final activityLogs = _dataService.getInMemoryData('activityLogs');
      final newId = activityLogs.isEmpty
          ? 1
          : (activityLogs
                  .map((l) => l['id'] as int)
                  .reduce((a, b) => a > b ? a : b) +
              1);

      final log = {
        'id': newId,
        'user_name': 'DefaultUser',
        'activity_name': activityName,
        'date': date.toIso8601String(),
        'duration_minutes': durationMinutes,
        'calories_burned': double.parse(caloriesBurned.toStringAsFixed(1)),
        'notes': notes,
      };

      _dataService.addToInMemoryData('activityLogs', log);
      return log;
    }
  }

  /// Retrieves activity statistics for the current user
  /// [startDate] - Optional stats from this date
  /// [endDate] - Optional stats until this date
  /// Returns activity statistics including totals and averages
  Future<Map<String, dynamic>> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (isLoggedIn) {
      return await api.ActivityService().getActivityStats(
        userName: userName,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      // Calculate stats from in-memory data
      final logs =
          await getActivityLogs(startDate: startDate, endDate: endDate);

      if (logs.isEmpty) {
        return {
          'total_sessions': 0,
          'total_minutes': 0,
          'total_calories': 0.0,
          'average_duration': 0.0,
          'average_calories_per_session': 0.0,
        };
      }

      final totalSessions = logs.length;
      final totalMinutes = logs.fold<int>(
          0, (sum, log) => sum + (log['duration_minutes'] as int));
      final totalCalories = logs.fold<double>(
          0.0, (sum, log) => sum + (log['calories_burned'] as double));

      return {
        'total_sessions': totalSessions,
        'total_minutes': totalMinutes,
        'total_calories': totalCalories,
        'average_duration': totalMinutes / totalSessions,
        'average_calories_per_session': totalCalories / totalSessions,
      };
    }
  }

  /// Deletes an activity log entry
  /// [logId] - The ID of the log entry to delete
  Future<void> deleteActivityLog(int logId) async {
    if (isLoggedIn) {
      await api.ActivityService().deleteActivityLog(
        logId: logId,
        userName: userName,
      );
    } else {
      // Remove from memory
      _dataService.removeFromInMemoryData(
          'activityLogs', (log) => log['id'] == logId);
    }
  }
}
