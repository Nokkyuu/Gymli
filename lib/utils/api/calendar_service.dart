/// CalendarService - Manages calendar notes, workouts, and periods
///
/// This service handles all CRUD operations for calendar-related data.
///
library;

import 'dart:convert';
import 'api_base.dart';

class CalendarService {
  Future<List<dynamic>> getCalendarNotes() async {
    return getData<List<dynamic>>('calendar_notes');
  }

  Future<Map<String, dynamic>> createCalendarNote({
    required DateTime date,
    required String note,
  }) async {
    return json.decode(await createData('calendar_notes', {
      'date': date.toIso8601String(),
      'note': note,
    }));
  }

  Future<void> deleteCalendarNote(int id) async {
    final response = await deleteData('calendar_notes/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete calendar note');
    }
  }

  Future<Map<String, dynamic>> updateCalendarNote({
    required int id,
    required DateTime date,
    required String note,
  }) async {
    final response = await updateData(
        'calendar_notes/$id', {'date': date.toIso8601String(), 'note': note});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update calendar note');
    }
  }

  Future<List<dynamic>> getCalendarWorkouts() async {
    return getData<List<dynamic>>('calendar_workouts');
  }

  Future<Map<String, dynamic>> createCalendarWorkout({
    required DateTime date,
    required String workout,
  }) async {
    return json.decode(await createData('calendar_workouts', {
      'date': date.toIso8601String(),
      'workout': workout,
    }));
  }

  Future<void> deleteCalendarWorkout(int id) async {
    final response = await deleteData('calendar_workouts/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete calendar workout');
    }
  }

  Future<List<dynamic>> getCalendarPeriods() async {
    return getData<List<dynamic>>('periods');
  }

  Future<Map<String, dynamic>> createCalendarPeriod({
    required String type,
    required DateTime start_date,
    required DateTime end_date,
  }) async {
    return json.decode(await createData('periods', {
      'type': type,
      'start_date': start_date.toIso8601String(),
      'end_date': end_date.toIso8601String(),
    }));
  }

  Future<void> deleteCalendarPeriod(int id) async {
    final response = await deleteData('periods/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete calendar period');
    }
  }
}
