///Exercise Setup screen, accessed via navigation drawer or from the ExerciseScreen.
///Screen is used to create or update exercises.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/themes/responsive_helper.dart';
import '../utils/info_dialogues.dart';
import 'exercise_setup/exercise_setup_exports.dart';

class ExerciseSetupScreen extends StatefulWidget {
  final String exerciseName;

  const ExerciseSetupScreen(this.exerciseName, {super.key});

  @override
  State<ExerciseSetupScreen> createState() => _ExerciseSetupScreenState();
}

class _ExerciseSetupScreenState extends State<ExerciseSetupScreen> {
  late ExerciseSetupController _exerciseController;

  @override
  void initState() {
    super.initState();
    _exerciseController = ExerciseSetupController();

    // Initialize with the provided exercise name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _exerciseController.initialize(widget.exerciseName);
    });
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobileWeb = ResponsiveHelper.isWebMobile(context);

    return ChangeNotifierProvider.value(
      value: _exerciseController,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          title: const Text("Exercise Setup"),
          actions: [
            buildInfoButton('Exercise Setup Info', context,
                () => showInfoDialogExerciseSetup(context)),
            Consumer<ExerciseSetupController>(
              builder: (context, controller, child) {
                return IconButton(
                  onPressed: controller.currentExercise?.id != null
                      ? () => _showDeleteDialog(context, controller)
                      : null,
                  icon: const Icon(Icons.delete),
                );
              },
            ),
          ],
        ),
        body: Consumer<ExerciseSetupController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        controller.initialize(widget.exerciseName);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return isMobileWeb
                ? ExerciseMobileLayoutWidget(
                    onSuccess: () => _handleSaveSuccess(context))
                : ExerciseDesktopLayoutWidget(
                    onSuccess: () => _handleSaveSuccess(context));
          },
        ),
      ),
    );
  }

  void _handleSaveSuccess(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context, ExerciseSetupController controller) async {
    if (controller.currentExercise?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${controller.currentExercise!.name}"?'),
        content: const Text(
            'This will permanently delete the exercise and ALL training history. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final success = await controller.deleteExercise();

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise deleted successfully')),
        );
        Navigator.of(context).pop(); // Close the screen
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(controller.errorMessage ?? 'Failed to delete exercise'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting exercise: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting exercise: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
