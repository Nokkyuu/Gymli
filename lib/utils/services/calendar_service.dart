/// CalendarService - Manages calendar notes, workouts, and periods
///
/// This service handles all CRUD operations for calendar-related data.
///
library;

import '../api/api_base.dart';
import '../models/data_models.dart';

class CalendarService {
  Future<List<CalendarNote>> getCalendarNotes() async {
    final data = await getData<List<dynamic>>('calendar_notes');
    return data.map((item) => CalendarNote.fromJson(item)).toList();
  }

  Future<CalendarNote> createCalendarNote({
    required DateTime date,
    required String note,
  }) async {
    final response = await createData('calendar_notes', {
      'date': date.toIso8601String(),
      'note': note,
    });
    return CalendarNote.fromJson(response);
  }

  Future<void> deleteCalendarNote(int id) async {
    final response = await deleteData('calendar_notes/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete calendar note');
    }
  }

  Future<CalendarNote> updateCalendarNote({
    required int id,
    required DateTime date,
    required String note,
  }) async {
    final response = await updateData(
        'calendar_notes/$id', {'date': date.toIso8601String(), 'note': note});
    if (response.statusCode == 200) {
      return CalendarNote.fromJson(response);
    } else {
      throw Exception('Failed to update calendar note');
    }
  }

  Future<List<CalendarWorkout>> getCalendarWorkouts() async {
    final data = await getData<List<dynamic>>('calendar_workouts');
    return data.map((item) => CalendarWorkout.fromJson(item)).toList();
  }

  Future<CalendarWorkout> createCalendarWorkout({
    required DateTime date,
    required String workout,
  }) async {
    final response = await createData('calendar_workouts', {
      'date': date.toIso8601String(),
      'workout': workout,
    });
    return CalendarWorkout.fromJson(response);
  }

  Future<void> deleteCalendarWorkout(int id) async {
    final response = await deleteData('calendar_workouts/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete calendar workout');
    }
  }

  Future<List<CalendarPeriod>> getCalendarPeriods() async {
    final data = await getData<List<dynamic>>('periods');
    return data.map((item) => CalendarPeriod.fromJson(item)).toList();
  }

  Future<CalendarPeriod> createCalendarPeriod({
    required String type,
    required DateTime start_date,
    required DateTime end_date,
  }) async {
    final response = await createData('periods', {
      'type': type,
      'start_date': start_date.toIso8601String(),
      'end_date': end_date.toIso8601String(),
    });
    return CalendarPeriod.fromJson(response);
  }

  Future<void> deleteCalendarPeriod(int id) async {
    final response = await deleteData('periods/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete calendar period');
    }
  }
}
