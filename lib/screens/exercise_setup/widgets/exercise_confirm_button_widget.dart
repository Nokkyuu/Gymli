import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/exercise_setup_controller.dart';
import '../../../utils/globals.dart' as globals;
import 'package:go_router/go_router.dart';
import 'package:Gymli/config/app_router.dart';

class ExerciseConfirmButtonWidget extends StatelessWidget {
  final VoidCallback? onSuccess;

  const ExerciseConfirmButtonWidget({
    super.key,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseSetupController>(
      builder: (context, controller, child) {
        return IconButton(
          icon: controller.isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.check),
          iconSize: 40,
          tooltip: 'Confirm',
          onPressed: controller.isLoading
              ? null
              : () => _showConfirmDialog(context, controller),
        );
      },
    );
  }

  Future<void> _showConfirmDialog(
      BuildContext context, ExerciseSetupController controller) async {
    final bool? success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                globals.exerciseList
                        .contains(controller.exerciseTitleController.text)
                    ? Icons.edit
                    : Icons.add_circle,
                size: 48,
                color: globals.exerciseList
                        .contains(controller.exerciseTitleController.text)
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                globals.exerciseList
                        .contains(controller.exerciseTitleController.text)
                    ? 'Update Exercise'
                    : 'Create New Exercise',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (globals.exerciseList
                  .contains(controller.exerciseTitleController.text))
                const Text(
                  'This will update the existing exercise configuration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange),
                ),
              const SizedBox(height: 16),
              Card(
                elevation: 2.0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fitness_center, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.exerciseTitleController.text,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16),
                          const SizedBox(width: 4),
                          Text(
                              'Equipment: ${controller.getDeviceName(controller.chosenDevice)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.repeat, size: 16),
                          const SizedBox(width: 4),
                          Text(
                              'Reps: ${controller.minRep.toInt()} - ${controller.maxRep.toInt()}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.add, size: 16),
                          const SizedBox(width: 4),
                          Text('Weight increments: ${controller.weightInc} kg'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Active muscle groups: ${controller.getActiveMuscleGroups()}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (kDebugMode)
                        print('🔧 Starting exercise save process...');

                      try {
                        final saveSuccess = await controller.saveExercise();
                        if (saveSuccess) {
                          if (kDebugMode)
                            print('✅ All operations completed successfully');

                          // ✅ Close dialog with success=true
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        } else {
                          if (kDebugMode) print('❌ Save operation failed');
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(false);
                          }
                        }
                      } catch (e) {
                        if (kDebugMode) print('❌ Error in save process: $e');
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(false);
                        }
                      }
                    },
                    child: Text(
                      globals.exerciseList
                              .contains(controller.exerciseTitleController.text)
                          ? 'Update Exercise'
                          : 'Create Exercise',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // ✅ Just call the callback if successful - let parent handle navigation
    if (success == true) {
      if (kDebugMode)
        print('🚀 Exercise saved successfully, calling onSuccess callback...');

      // ✅ Call the callback to notify parent screen
      if (onSuccess != null) {
        onSuccess!();
      }
    } else {
      if (kDebugMode) print('❌ Dialog returned success=$success');
    }
  }
}
