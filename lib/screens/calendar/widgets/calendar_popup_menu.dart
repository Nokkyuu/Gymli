import 'package:flutter/material.dart';
import '../controllers/calendar_controller.dart';
import 'calendar_dialogs.dart';

DateTime _normalize(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day);
}

Future<void> showDayPopupMenu({
  required BuildContext context,
  required CalendarController controller,
  required DateTime day,
  required Offset position,
}) async {
  final normalized = _normalize(day);
  await showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx, position.dy),
    items: [
      const PopupMenuItem(
        value: 'note',
        child: Row(
          children: [
            Icon(Icons.note, size: 18, color: Colors.blue),
            SizedBox(width: 8),
            Text('Add/Edit Note'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'workout',
        child: Row(
          children: [
            Icon(Icons.fitness_center, size: 18, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Add Workout'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'period',
        child: Row(
          children: [
            Icon(Icons.timeline, size: 18, color: Colors.orange),
            SizedBox(width: 8),
            Text('Add Time Period'),
          ],
        ),
      ),
      if (controller.hasNote(normalized) || controller.hasWorkout(normalized))
        const PopupMenuItem(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.clear, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Clear Notes & Workouts'),
            ],
          ),
        ),
    ],
  ).then((value) async {
    if (value == 'note') {
      // ignore: use_build_context_synchronously
      await showDayActionDialog(context, controller, normalized);
    } else if (value == 'workout') {
      // ignore: use_build_context_synchronously
      await showWorkoutDialog(context, controller, normalized);
    } else if (value == 'period') {
      await showAddPeriodDialog(
          // ignore: use_build_context_synchronously
          context: context,
          controller: controller,
          startDate: normalized);
    } else if (value == 'clear') {
      await controller.clearNotesAndWorkoutsForDay(normalized);
    }
  });
}
