import 'package:flutter/material.dart';
import '../models/calendar_period.dart';
import 'package:Gymli/utils/themes/themes.dart' show ThemeColors;

class CalendarConstants {
  // Calendar configuration
  static final DateTime minDate = DateTime.utc(2020, 1, 1);
  static final DateTime maxDate = DateTime.utc(2100, 12, 31);

  // Period types
  static const List<PeriodType> periodTypes = [
    PeriodType.cut,
    PeriodType.bulk,
    PeriodType.other,
  ];

  // Repeat types for workouts
  static const List<String> repeatTypes = ['none', 'weekly', 'interval'];

  // Default values
  static const int defaultIntervalDays = 3;
  static const int defaultDurationWeeks = 6;

  // Colors - Now using singleton
  static Map<PeriodType, Color> get periodColors {
    final themeColors = ThemeColors();
    return {
      PeriodType.cut: themeColors.phaseColor['cut']!,
      PeriodType.bulk: themeColors.phaseColor['bulk']!,
      PeriodType.other: themeColors.phaseColor['other']!,
    };
  }

  static const Color noteColor = Colors.blue;
  static const Color workoutColor = Colors.deepPurple;

  // Icon colors (aliases for compatibility)
  static const Color noteIconColor = noteColor;
  static const Color workoutIconColor = workoutColor;

  // Icon sizes (aliases for compatibility)
  static const double iconSize = calendarIconSize;

  // Helper methods
  static Color getPeriodColor(PeriodType type) {
    return periodColors[type]!;
  }

  // Icon sizes
  static const double calendarIconSize = 14.0;
  static const double legendIconSize = 16.0;
  static const double popupIconSize = 18.0;

  // Spacing
  static const double legendDotSize = 14.0;
  static const EdgeInsets legendPadding =
      EdgeInsets.symmetric(vertical: 4, horizontal: 8);
  static const EdgeInsets dayDetailsPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 4);
  static const EdgeInsets dayDetailsContentPadding = EdgeInsets.all(8);

  // Error messages
  static const String periodOverlapError = 'Periods cannot overlap!';
  static const String selectWorkoutError = 'Please select a workout';
  static const String durationError = 'Duration must be at least 1 week';

  // UI strings
  static const String appBarTitle = 'Calendar & Notes';
  static const String notesTabTitle = 'Notes';
  static const String workoutsTabTitle = 'Workouts';
  static const String periodsTabTitle = 'Periods';

  static const String noNotesMessage = 'No notes yet.';
  static const String noWorkoutsMessage = 'No workouts yet.';
  static const String noPeriodsMessage = 'No periods yet.';

  // Dialog titles
  static const String noteDialogTitle = 'Note';
  static const String workoutDialogTitle = 'Add Workout';
  static const String periodDialogTitle = 'Add Time Period';

  // Menu items
  static const String addEditNoteMenu = 'Add/Edit Note';
  static const String addWorkoutMenu = 'Add Workout';
  static const String addPeriodMenu = 'Add Time Period';
  static const String clearNotesWorkoutsMenu = 'Clear Notes & Workouts';

  // Repeat type labels
  static const String noRepeatLabel = 'No Repeat';
  static const String weeklyRepeatLabel = 'Repeat Weekly';
  static const String intervalRepeatLabel = 'Repeat Every X Days';

  // Form labels
  static const String workoutHint = 'Assign workout';
  static const String noteHint = 'Enter note...';
  static const String repeatLabel = 'Repeat';
  static const String durationWeeksLabel = 'Duration (weeks):';
  static const String selectTypeHint = 'Select type';
  static const String startLabel = 'Start:';
  static const String endLabel = 'End:';
  static const String selectLabel = 'Select';
  static const String saveLabel = 'Save';
  static const String addLabel = 'Add';
  static const String withLabel = 'with';
  static const String daysRestLabel = 'days rest';
}
