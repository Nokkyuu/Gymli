///Workout Setup Screen, accessed via the navigation bar or directly from a Workout
///create or edit Workouts by adding or removing Workout Units (Exercises with a set amount of warmup and work sets)
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/themes/responsive_helper.dart';
import '../utils/info_dialogues.dart';
import 'workout_setup/workout_setup_exports.dart';

class WorkoutSetupScreen extends StatefulWidget {
  final String workoutName;
  
  const WorkoutSetupScreen(this.workoutName, {super.key});

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  late WorkoutSetupController _workoutController;
  late ExerciseSelectionController _exerciseController;

  @override
  void initState() {
    super.initState();
    _workoutController = WorkoutSetupController();
    _exerciseController = ExerciseSelectionController();
    
    // Initialize with the provided workout name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _workoutController.initialize(widget.workoutName);
    });
  }

  @override
  void dispose() {
    _workoutController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Workout Editor';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _workoutController),
        ChangeNotifierProvider.value(value: _exerciseController),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          title: const Text(title),
          centerTitle: true,
          actions: [
            buildInfoButton('Workout Setup Info', context,
                () => showInfoDialogWorkoutSetup(context)),
            Consumer<WorkoutSetupController>(
              builder: (context, controller, child) {
                return IconButton(
                  onPressed: controller.currentWorkout?.id != null
                      ? () => _showDeleteDialog(context, controller)
                      : null,
                  icon: const Icon(Icons.delete),
                );
              },
            ),
          ],
        ),
        body: Consumer<WorkoutSetupController>(
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
                        controller.initialize(widget.workoutName);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return ResponsiveHelper.isWebMobile(context)
                ? WorkoutMobileLayoutWidget(onSave: () => _handleSaveSuccess(context))
                : WorkoutDesktopLayoutWidget(onSave: () => _handleSaveSuccess(context));
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

  Future<void> _showDeleteDialog(BuildContext context, WorkoutSetupController controller) async {
    if (controller.currentWorkout?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${controller.currentWorkout!.name}"?'),
        content: const Text(
            'This will permanently delete the workout and ALL associated data. This cannot be undone.'),
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
      final success = await controller.deleteWorkout();
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted successfully')),
        );
        Navigator.of(context).pop(); // Close the screen
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Failed to delete workout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting workout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
