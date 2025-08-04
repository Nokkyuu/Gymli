import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../utils/api/api_models.dart';

class ExerciseTileWidget extends StatelessWidget {
  final ApiWorkoutUnit exercise;
  final IconData icon;
  final VoidCallback onRemove;

  const ExerciseTileWidget({
    super.key,
    required this.exercise,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: true,
      leading: FaIcon(icon),
      title: Text(exercise.exerciseName),
      subtitle: Text(
          'Warm Ups: ${exercise.warmups}, Work Sets: ${exercise.worksets}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onRemove,
      ),
    );
  }
}
