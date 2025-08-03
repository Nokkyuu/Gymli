import 'package:flutter/material.dart';
import '../controllers/calendar_controller.dart';

/// A widget that displays details for the selected day including:
/// - Notes for the day
/// - Workouts scheduled for the day
class CalendarDayDetails extends StatelessWidget {
  final DateTime day;
  final CalendarController controller;

  const CalendarDayDetails({
    super.key,
    required this.day,
    required this.controller,
  });

  DateTime _normalize(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedDay = _normalize(day);
    final noteData = controller.notes[normalizedDay];
    final note = noteData?.note;
    final workouts = controller.calendarWorkouts
        .where((w) => _normalize(w.date) == normalizedDay)
        .map((w) => w.workoutName)
        .toList();

    if (note == null && workouts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details for ${day.toLocal()}'.split(' ')[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (note != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(child: Text(note)),
                ],
              ),
            ],
            if (workouts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.fitness_center,
                      size: 16, color: Colors.deepPurple),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Workouts: ${workouts.join(', ')}')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
