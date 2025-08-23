import 'package:flutter/material.dart';
import '../constants/calendar_constants.dart';
import 'package:Gymli/utils/models/data_models.dart';

/// A widget that displays the calendar legend showing:
/// - Period type colors (Cut, Bulk, Other)
/// - Icons for notes and workouts
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          _buildLegendDot(CalendarConstants.getPeriodColor(PeriodType.cut)),
          const Text('Cut  '),
          _buildLegendDot(CalendarConstants.getPeriodColor(PeriodType.bulk)),
          const Text('Bulk  '),
          _buildLegendDot(CalendarConstants.getPeriodColor(PeriodType.other)),
          const Text('Other  '),
          const Icon(Icons.note,
              size: 16, color: CalendarConstants.noteIconColor),
          const Text(' Note  '),
          const Icon(Icons.fitness_center,
              size: 16, color: CalendarConstants.workoutIconColor),
          const Text(' Workout'),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
