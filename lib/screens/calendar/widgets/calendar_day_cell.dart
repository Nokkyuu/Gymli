import 'package:flutter/material.dart';
import '../constants/calendar_constants.dart';
import '../controllers/calendar_controller.dart';

/// A custom day cell widget for the calendar that displays:
/// - Day number with proper styling for selected/today states
/// - Background color for periods (cut/bulk/other)
/// - Icons for notes and workouts
/// - Gesture handling for right-click and long-press
class CalendarDayCell extends StatelessWidget {
  final BuildContext context;
  final DateTime day;
  final CalendarController controller;
  final bool selected;
  final bool today;
  final Function(BuildContext, DateTime, Offset) onShowPopupMenu;

  const CalendarDayCell({
    super.key,
    required this.context,
    required this.day,
    required this.controller,
    required this.selected,
    required this.today,
    required this.onShowPopupMenu,
  });

  DateTime _normalize(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _normalize(day);
    final hasNote = controller.hasNote(normalized);
    final hasWorkout = controller.hasWorkout(normalized);
    final period = controller.getPeriodForDate(normalized);
    final inPeriod = period != null;

    Color? backgroundColor;
    Color textColor = Colors.black;

    if (selected) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
    } else if (today) {
      textColor = Theme.of(context).colorScheme.primary;
    }

    if (inPeriod) {
      backgroundColor = CalendarConstants.getPeriodColor(period.type);
    }

    return GestureDetector(
      onSecondaryTapDown: (details) async {
        controller.selectDay(day, day);
        await onShowPopupMenu(context, day, details.globalPosition);
      },
      onLongPress: () async {
        controller.selectDay(day, day);
        final box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        await onShowPopupMenu(context, day, position);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.rectangle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(color: textColor),
            ),
          ),
          if (hasNote)
            Positioned(
              bottom: 4,
              left: 8,
              child: Icon(
                Icons.note,
                size: CalendarConstants.iconSize,
                color:
                    selected ? Colors.white : CalendarConstants.noteIconColor,
              ),
            ),
          if (hasWorkout)
            Positioned(
              bottom: 4,
              right: 8,
              child: Icon(
                Icons.fitness_center,
                size: CalendarConstants.iconSize,
                color: selected
                    ? Colors.white
                    : CalendarConstants.workoutIconColor,
              ),
            ),
        ],
      ),
    );
  }
}
