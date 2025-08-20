import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import '../models/models.dart';
import '../constants/calendar_constants.dart';
import 'package:get_it/get_it.dart';
import 'package:Gymli/utils/api/api.dart';

class CalendarController extends ChangeNotifier {
  final CalendarService calendarService = GetIt.I<CalendarService>();
  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Data collections
  final Map<DateTime, CalendarNote> _notes = {};
  final List<CalendarPeriod> _periods = [];
  final List<CalendarWorkout> _calendarWorkouts = [];
  List<String> _workoutNames = [];

  // Loading states
  bool _isLoading = false;
  bool _isLoadingWorkouts = false;
  bool _isLoadingNotes = false;
  bool _isLoadingPeriods = false;

  // Getters
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  Map<DateTime, CalendarNote> get notes => Map.unmodifiable(_notes);
  List<CalendarPeriod> get periods => List.unmodifiable(_periods);
  List<CalendarWorkout> get calendarWorkouts =>
      List.unmodifiable(_calendarWorkouts);
  List<String> get workoutNames => List.unmodifiable(_workoutNames);

  bool get isLoading => _isLoading;
  bool get isLoadingWorkouts => _isLoadingWorkouts;
  bool get isLoadingNotes => _isLoadingNotes;
  bool get isLoadingPeriods => _isLoadingPeriods;

  // Initialize all data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadWorkouts(),
        loadCalendarNotes(),
        loadCalendarWorkouts(),
        loadPeriods(),
      ]);
    } catch (e) {
      if (kDebugMode) print('Error initializing calendar: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Date management
  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  void setSelectedDay(DateTime? day) {
    _selectedDay = day;
    notifyListeners();
  }

  void selectDay(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    notifyListeners();
  }

  // Helper to normalize dates (remove time part)
  DateTime normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // Data loading methods
  Future<void> loadWorkouts() async {
    _isLoadingWorkouts = true;
    notifyListeners();

    try {
      final workouts = await GetIt.I<WorkoutService>().getWorkouts();
      _workoutNames = workouts.map<String>((w) => w['name'] as String).toList();
    } catch (e) {
      if (kDebugMode) print('Error loading workouts: $e');
    } finally {
      _isLoadingWorkouts = false;
      notifyListeners();
    }
  }

  Future<void> loadCalendarNotes() async {
    _isLoadingNotes = true;
    notifyListeners();

    try {
      final notes = await calendarService.getCalendarNotes();
      _notes.clear();
      for (var n in notes) {
        final note = CalendarNote.fromMap(n);
        _notes[normalize(note.date)] = note;
      }
    } catch (e) {
      if (kDebugMode) print('Error loading calendar notes: $e');
    } finally {
      _isLoadingNotes = false;
      notifyListeners();
    }
  }

  Future<void> loadCalendarWorkouts() async {
    try {
      final workouts = await calendarService.getCalendarWorkouts();
      _calendarWorkouts.clear();
      for (var w in workouts) {
        final workout = CalendarWorkout.fromMap(w);
        _calendarWorkouts.add(CalendarWorkout(
          date: normalize(workout.date),
          workoutName: workout.workoutName,
          id: workout.id,
        ));
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading calendar workouts: $e');
    }
  }

  Future<void> loadPeriods() async {
    _isLoadingPeriods = true;
    notifyListeners();

    try {
      final periods = await calendarService.getCalendarPeriods();
      _periods.clear();
      for (var p in periods) {
        _periods.add(CalendarPeriod.fromMap(p));
      }
    } catch (e) {
      if (kDebugMode) print('Error loading periods: $e');
    } finally {
      _isLoadingPeriods = false;
      notifyListeners();
    }
  }

  // Note operations
  Future<String?> saveNote(DateTime date, String? note) async {
    final normalizedDate = normalize(date);
    final existingNote = _notes[normalizedDate];

    try {
      if (note == null || note.trim().isEmpty) {
        // Delete note
        if (existingNote != null) {
          await calendarService.deleteCalendarNote(existingNote.id!);
          _notes.remove(normalizedDate);
        }
      } else {
        if (existingNote != null) {
          // Update existing note
          await calendarService.updateCalendarNote(
              id: existingNote.id!, note: note, date: normalizedDate);
          _notes[normalizedDate] = existingNote.copyWith(note: note);
        } else {
          // Create new note
          final createdNote = await calendarService
              .createCalendarNote(date: normalizedDate, note: note);
          _notes[normalizedDate] = CalendarNote(
            id: createdNote['id'],
            date: normalizedDate,
            note: note,
          );
        }
      }
      notifyListeners();
      return null; // Success
    } catch (e) {
      if (kDebugMode) print('Error saving note: $e');
      return 'Failed to save note: $e';
    }
  }

  // Workout operations
  Future<String?> addWorkout(DateTime date, String workoutName) async {
    try {
      final createdWorkout = await calendarService
          .createCalendarWorkout(date: date, workout: workoutName);

      _calendarWorkouts.add(CalendarWorkout(
        date: normalize(date),
        workoutName: workoutName,
        id: createdWorkout['id'],
      ));

      notifyListeners();
      return null; // Success
    } catch (e) {
      if (kDebugMode) print('Error adding workout: $e');
      return 'Failed to add workout: $e';
    }
  }

  Future<String?> deleteWorkout(CalendarWorkout workout) async {
    try {
      if (workout.id != null) {
        await calendarService.deleteCalendarWorkout(workout.id!);
      }
      _calendarWorkouts.remove(workout);
      notifyListeners();
      return null; // Success
    } catch (e) {
      if (kDebugMode) print('Error deleting workout: $e');
      return 'Failed to delete workout: $e';
    }
  }

  // Period operations
  Future<String?> addPeriod(String type, DateTime start, DateTime end) async {
    try {
      // Check for overlap first
      final newPeriod = CalendarPeriod(
        type: PeriodType.fromString(type),
        start: start,
        end: end,
      );

      final hasOverlap = _periods.any((p) => newPeriod.overlaps(p));
      if (hasOverlap) {
        return CalendarConstants.periodOverlapError;
      }

      final createdPeriod = await calendarService
          .createCalendarPeriod(type: type, start_date: start, end_date: end);

      _periods.add(CalendarPeriod(
        type: PeriodType.fromString(type),
        start: start,
        end: end,
        id: createdPeriod['id'],
      ));

      notifyListeners();
      return null; // Success
    } catch (e) {
      if (kDebugMode) print('Error adding period: $e');
      return 'Failed to add period: $e';
    }
  }

  Future<String?> deletePeriod(CalendarPeriod period) async {
    try {
      if (period.id != null) {
        await calendarService.deleteCalendarPeriod(period.id!);
      }
      _periods.remove(period);
      notifyListeners();
      return null; // Success
    } catch (e) {
      if (kDebugMode) print('Error deleting period: $e');
      return 'Failed to delete period: $e';
    }
  }

  // Utility methods
  bool hasNote(DateTime date) {
    return _notes.containsKey(normalize(date));
  }

  bool hasWorkout(DateTime date) {
    final normalizedDate = normalize(date);
    return _calendarWorkouts.any((w) => normalize(w.date) == normalizedDate);
  }

  CalendarPeriod? getPeriodForDate(DateTime date) {
    final normalizedDate = normalize(date);
    try {
      return _periods.firstWhere((p) => p.containsDate(normalizedDate));
    } catch (e) {
      return null;
    }
  }

  CalendarNote? getNoteForDate(DateTime date) {
    return _notes[normalize(date)];
  }

  List<CalendarWorkout> getWorkoutsForDate(DateTime date) {
    final normalizedDate = normalize(date);
    return _calendarWorkouts
        .where((w) => normalize(w.date) == normalizedDate)
        .toList();
  }

  Future<String?> clearNotesAndWorkoutsForDay(DateTime day) async {
    final normalizedDay = normalize(day);

    try {
      // Remove note
      if (_notes.containsKey(normalizedDay)) {
        await calendarService
            .deleteCalendarNote(_notes[normalizedDay]!.id!);
        _notes.remove(normalizedDay);
      }

      // Remove all workouts for that day
      final workoutsToRemove = _calendarWorkouts
          .where((w) => normalize(w.date) == normalizedDay)
          .toList();

      for (final w in workoutsToRemove) {
        if (w.id != null) {
          await calendarService.deleteCalendarWorkout(w.id!);
        }
      }

      _calendarWorkouts.removeWhere((w) => normalize(w.date) == normalizedDay);
      notifyListeners();
      return null; // Success
    } catch (e) {
      if (kDebugMode) print('Error clearing day data: $e');
      return 'Failed to clear day data: $e';
    }
  }

  // Bulk workout operations
  Future<String?> addWorkoutWithRepeat({
    required DateTime startDate,
    required String workoutName,
    required String repeatType,
    int intervalDays = CalendarConstants.defaultIntervalDays,
    int durationWeeks = CalendarConstants.defaultDurationWeeks,
  }) async {
    try {
      if (repeatType == 'none') {
        return await addWorkout(startDate, workoutName);
      }

      if (durationWeeks <= 0) {
        return CalendarConstants.durationError;
      }

      List<DateTime> dates = [];
      DateTime current = startDate;

      if (repeatType == 'weekly') {
        final endDate = startDate.add(Duration(days: (durationWeeks * 7) - 7));
        while (!current.isAfter(endDate)) {
          dates.add(current);
          current = current.add(const Duration(days: 7));
        }
      } else if (repeatType == 'interval') {
        final endDate = startDate.add(Duration(days: (durationWeeks * 7)));
        while (!current.isAfter(endDate)) {
          dates.add(current);
          current = current.add(Duration(days: intervalDays + 1));
        }
      }

      // Add all workouts
      for (final date in dates) {
        final error = await addWorkout(date, workoutName);
        if (error != null) return error;
      }

      return null; // Success
    } catch (e) {
      if (kDebugMode) print('Error adding repeated workouts: $e');
      return 'Failed to add repeated workouts: $e';
    }
  }

  // Get sorted lists for display
  List<MapEntry<DateTime, CalendarNote>> getSortedNotes() {
    final entries = _notes.entries.toList();
    entries.sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  List<CalendarWorkout> getSortedWorkouts() {
    final workouts = _calendarWorkouts.toList();
    workouts.sort((a, b) => b.date.compareTo(a.date));
    return workouts;
  }

  List<CalendarPeriod> getSortedPeriods() {
    final periods = _periods.toList();
    periods.sort((a, b) => b.start.compareTo(a.start));
    return periods;
  }

  // Delete individual items
  Future<String?> deleteNote(CalendarNote note) async {
    try {
      await calendarService.deleteCalendarNote(note.id!);
      _notes.remove(normalize(note.date));
      notifyListeners();
      return null;
    } catch (e) {
      if (kDebugMode) print('Error deleting note: $e');
      return 'Failed to delete note: $e';
    }
  }

  // Getter for notes as a list (sorted by date)
  List<CalendarNote> get notesList {
    return _notes.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
