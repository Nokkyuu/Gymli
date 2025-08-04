import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/workout_setup_controller.dart';

class WorkoutFormWidget extends StatelessWidget {
  final VoidCallback? onSave;

  const WorkoutFormWidget({
    super.key,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutSetupController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                textAlign: TextAlign.center,
                controller: controller.workoutNameController,
                obscureText: false,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Workout Name',
                ),
              ),
            ),
            TextButton.icon(
              icon: controller.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(controller.isLoading ? "Saving..." : "Add Workout"),
              onPressed: controller.isLoading
                  ? null
                  : () async {
                      final success = await controller.saveWorkout();
                      if (success) {
                        onSave?.call();
                      }
                    },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
