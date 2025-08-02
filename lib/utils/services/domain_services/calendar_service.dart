import '../../api/api.dart' as api;
import '../data_service.dart';

class CalendarService {
  final DataService _dataService = DataService();

  // Getters that delegate to DataService
  bool get isLoggedIn => _dataService.isLoggedIn;
  String get userName => _dataService.userName;

  //----------------- Calendar Notes Methods -----------------//

  Future<List<dynamic>> getCalendarNotes() async {
    if (isLoggedIn) {
      return await api.CalendarNoteService()
          .getCalendarNotes(userName: userName);
    } else {
      return _dataService.getInMemoryData('calendarNotes');
    }
  }

  Future<Map<String, dynamic>> createCalendarNote({
    required DateTime date,
    required String note,
  }) async {
    if (isLoggedIn) {
      return await api.CalendarNoteService().createCalendarNote(
        userName: userName,
        date: date,
        note: note,
      );
    } else {
      final newNote = {
        'id': _dataService.generateFakeId('calendarNotes'),
        'user_name': 'DefaultUser',
        'date': date.toIso8601String(),
        'note': note,
      };
      _dataService.addToInMemoryData('calendarNotes', newNote);
      return newNote;
    }
  }

  Future<void> deleteCalendarNote(int id) async {
    if (isLoggedIn) {
      await api.CalendarNoteService().deleteCalendarNote(id);
    } else {
      _dataService.removeFromInMemoryData(
          'calendarNotes', (n) => n['id'] == id);
    }
  }

  Future<void> updateCalendarNote(
    int id, {
    required String note,
    required DateTime date,
  }) async {
    if (isLoggedIn) {
      await api.CalendarNoteService().updateCalendarNote(
        id: id,
        userName: userName,
        date: date,
        note: note,
      );
    } else {
      // Update in memory
      final notes = _dataService.getInMemoryData('calendarNotes');
      final noteIndex = notes.indexWhere((n) => n['id'] == id);
      if (noteIndex != -1) {
        notes[noteIndex] = {
          'id': id,
          'user_name': 'DefaultUser',
          'date': date.toIso8601String(),
          'note': note,
        };
      }
    }
  }

  //----------------- Calendar Workouts Methods -----------------//

  Future<List<dynamic>> getCalendarWorkouts() async {
    if (isLoggedIn) {
      return await api.CalendarWorkoutService()
          .getCalendarWorkouts(userName: userName);
    } else {
      return _dataService.getInMemoryData('calendarWorkouts');
    }
  }

  Future<Map<String, dynamic>> createCalendarWorkout({
    required DateTime date,
    required String workout,
  }) async {
    if (isLoggedIn) {
      return await api.CalendarWorkoutService().createCalendarWorkout(
        userName: userName,
        date: date,
        workout: workout,
      );
    } else {
      final newWorkout = {
        'id': _dataService.generateFakeId('calendarWorkouts'),
        'user_name': 'DefaultUser',
        'date': date.toIso8601String(),
        'workout': workout,
      };
      _dataService.addToInMemoryData('calendarWorkouts', newWorkout);
      return newWorkout;
    }
  }

  Future<void> deleteCalendarWorkout(int id) async {
    if (isLoggedIn) {
      await api.CalendarWorkoutService().deleteCalendarWorkout(id);
    } else {
      _dataService.removeFromInMemoryData(
          'calendarWorkouts', (w) => w['id'] == id);
    }
  }

  //----------------- Calendar Periods Methods -----------------//

  Future<List<dynamic>> getPeriods() async {
    if (isLoggedIn) {
      return await api.CalendarPeriodService()
          .getCalendarPeriods(userName: userName);
    } else {
      return _dataService.getInMemoryData('periods');
    }
  }

  Future<Map<String, dynamic>> createPeriod({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (isLoggedIn) {
      return await api.CalendarPeriodService().createCalendarPeriod(
        userName: userName,
        type: type,
        start_date: startDate,
        end_date: endDate,
      );
    } else {
      final newPeriod = {
        'id': _dataService.generateFakeId('periods'),
        'user_name': 'DefaultUser',
        'type': type,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };
      _dataService.addToInMemoryData('periods', newPeriod);
      return newPeriod;
    }
  }

  Future<void> deletePeriod(int id) async {
    if (isLoggedIn) {
      await api.CalendarPeriodService().deleteCalendarPeriod(id);
    } else {
      _dataService.removeFromInMemoryData('periods', (p) => p['id'] == id);
    }
  }

  //----------------- Convenience Methods -----------------//

  /// Gets all calendar data for a specific date
  /// Returns a map containing notes, workouts, and periods for the given date
  Future<Map<String, dynamic>> getCalendarDataForDate(DateTime date) async {
    final dateString =
        date.toIso8601String().split('T')[0]; // Get YYYY-MM-DD format

    final notes = await getCalendarNotes();
    final workouts = await getCalendarWorkouts();
    final periods = await getPeriods();

    // Filter by date
    final notesForDate = notes.where((note) {
      final noteDate =
          DateTime.parse(note['date']).toIso8601String().split('T')[0];
      return noteDate == dateString;
    }).toList();

    final workoutsForDate = workouts.where((workout) {
      final workoutDate =
          DateTime.parse(workout['date']).toIso8601String().split('T')[0];
      return workoutDate == dateString;
    }).toList();

    final periodsForDate = periods.where((period) {
      final startDate = DateTime.parse(period['start_date']);
      final endDate = DateTime.parse(period['end_date']);
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    return {
      'notes': notesForDate,
      'workouts': workoutsForDate,
      'periods': periodsForDate,
    };
  }

  /// Gets all calendar data within a date range
  /// Returns a map containing notes, workouts, and periods for the given range
  Future<Map<String, dynamic>> getCalendarDataForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final notes = await getCalendarNotes();
    final workouts = await getCalendarWorkouts();
    final periods = await getPeriods();

    // Filter by date range
    final notesInRange = notes.where((note) {
      final noteDate = DateTime.parse(note['date']);
      return noteDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          noteDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final workoutsInRange = workouts.where((workout) {
      final workoutDate = DateTime.parse(workout['date']);
      return workoutDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          workoutDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final periodsInRange = periods.where((period) {
      final periodStartDate = DateTime.parse(period['start_date']);
      final periodEndDate = DateTime.parse(period['end_date']);
      // Include periods that overlap with the range
      return periodStartDate.isBefore(endDate.add(const Duration(days: 1))) &&
          periodEndDate.isAfter(startDate.subtract(const Duration(days: 1)));
    }).toList();

    return {
      'notes': notesInRange,
      'workouts': workoutsInRange,
      'periods': periodsInRange,
    };
  }

  /// Clears all calendar data (notes, workouts, and periods)
  /// Useful for settings screen or user logout
  Future<void> clearAllCalendarData() async {
    if (isLoggedIn) {
      // Clear from API
      try {
        // Delete all notes
        final notes = await getCalendarNotes();
        for (var note in notes) {
          if (note['id'] != null) {
            try {
              await deleteCalendarNote(note['id']);
            } catch (e) {
              print(
                  'Warning: Failed to delete calendar note ${note['id']}: $e');
            }
          }
        }

        // Delete all workouts
        final workouts = await getCalendarWorkouts();
        for (var workout in workouts) {
          if (workout['id'] != null) {
            try {
              await deleteCalendarWorkout(workout['id']);
            } catch (e) {
              print(
                  'Warning: Failed to delete calendar workout ${workout['id']}: $e');
            }
          }
        }

        // Delete all periods
        final periods = await getPeriods();
        for (var period in periods) {
          if (period['id'] != null) {
            try {
              await deletePeriod(period['id']);
            } catch (e) {
              print(
                  'Warning: Failed to delete calendar period ${period['id']}: $e');
            }
          }
        }

        print('Cleared all calendar data from API');
      } catch (e) {
        print('Error clearing calendar data from API: $e');
      }
    }

    // Always clear in-memory data regardless of login status
    _dataService.clearSpecificInMemoryData('calendarNotes');
    _dataService.clearSpecificInMemoryData('calendarWorkouts');
    _dataService.clearSpecificInMemoryData('periods');
    print('Cleared in-memory calendar data cache');
  }
}
