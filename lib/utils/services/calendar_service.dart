/// CalendarService - Manages calendar notes, workouts, and periods
///
/// This service handles all CRUD operations for calendar-related data.
///
library;

import 'dart:convert';
import '../api/api_base.dart';

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

  // Future<Map<String, dynamic>> getCalendarDataForRange({
  //   //TODO: create specialized endpoints or use cache?
  //   required DateTime startDate,
  //   required DateTime endDate,
  // }) async {
  //   final notes = await getCalendarNotes();
  //   final workouts = await getCalendarWorkouts();
  //   final periods = await getCalendarPeriods();

  //   // Filter by date range
  //   final notesInRange = notes.where((note) {
  //     final noteDate = DateTime.parse(note['date']);
  //     return noteDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
  //         noteDate.isBefore(endDate.add(const Duration(days: 1)));
  //   }).toList();

  //   final workoutsInRange = workouts.where((workout) {
  //     final workoutDate = DateTime.parse(workout['date']);
  //     return workoutDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
  //         workoutDate.isBefore(endDate.add(const Duration(days: 1)));
  //   }).toList();

  //   final periodsInRange = periods.where((period) {
  //     final periodStartDate = DateTime.parse(period['start_date']);
  //     final periodEndDate = DateTime.parse(period['end_date']);
  //     // Include periods that overlap with the range
  //     return periodStartDate.isBefore(endDate.add(const Duration(days: 1))) &&
  //         periodEndDate.isAfter(startDate.subtract(const Duration(days: 1)));
  //   }).toList();

  //   return {
  //     'notes': notesInRange,
  //     'workouts': workoutsInRange,
  //     'periods': periodsInRange,
  //   };
  // }

  // Calendar convenience methods
  // Future<Map<String, dynamic>> getCalendarDataForDate(DateTime date) async {
  //   //TODO: create specialized endpoints or use cache?
  //   final dateString =
  //       date.toIso8601String().split('T')[0]; // Get YYYY-MM-DD format

  //   final notes = await getCalendarNotes();
  //   final workouts = await getCalendarWorkouts();
  //   final periods = await getCalendarPeriods();

  //   // Filter by date
  //   final notesForDate = notes.where((note) {
  //     final noteDate =
  //         DateTime.parse(note['date']).toIso8601String().split('T')[0];
  //     return noteDate == dateString;
  //   }).toList();

  //   final workoutsForDate = workouts.where((workout) {
  //     final workoutDate =
  //         DateTime.parse(workout['date']).toIso8601String().split('T')[0];
  //     return workoutDate == dateString;
  //   }).toList();

  //   final periodsForDate = periods.where((period) {
  //     final startDate = DateTime.parse(period['start_date']);
  //     final endDate = DateTime.parse(period['end_date']);
  //     return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
  //         date.isBefore(endDate.add(const Duration(days: 1)));
  //   }).toList();

  //   return {
  //     'notes': notesForDate,
  //     'workouts': workoutsForDate,
  //     'periods': periodsForDate,
  //   };
  // }
}
