///Workout Setup Screen, accessed via the navigation bar or directly from a Workout
///create or edit Workouts by adding or removing Workout Units (Exercises with a set amount of warmup and work sets)
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../utils/themes/responsive_helper.dart';
import 'workout_setup/workout_setup_exports.dart';
import 'package:go_router/go_router.dart';
import 'package:Gymli/config/app_router.dart';
import '../utils/info_dialogues.dart';

//TODO: raarrange desktop layout, showing the radar chart for muslce activity distribution
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

  AppBar _buildAppBar(BuildContext context) {
    final isEditMode = widget.workoutName.isNotEmpty;

    return AppBar(
      title: const Text('Workout Setup'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRouter.main),
      ),
      actions: [
        buildInfoButton('Workout Setup Info', context,
            () => showInfoDialogWorkoutSetup(context)),
        if (isEditMode)
          Consumer<WorkoutSetupController>(
            builder: (context, controller, child) {
              final hasWorkout = controller.currentWorkout?.id != null;
              return IconButton(
                icon: const Icon(Icons.delete),
                tooltip: hasWorkout ? 'Delete Workout' : 'No Workout to Delete',
                onPressed: hasWorkout
                    ? () => _showDeleteDialog(context, controller)
                    : null,
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _workoutController),
        ChangeNotifierProvider.value(value: _exerciseController),
      ],
      child: Scaffold(
        appBar: _buildAppBar(context),
        resizeToAvoidBottomInset: false,
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
                ? WorkoutMobileLayoutWidget(
                    onSave: () => _handleSaveSuccess(context))
                : WorkoutDesktopLayoutWidget(
                    onSave: () => _handleSaveSuccess(context));
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
      BuildContext context, WorkoutSetupController controller) async {
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
            content:
                Text(controller.errorMessage ?? 'Failed to delete workout'),
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
