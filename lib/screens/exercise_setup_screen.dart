///Exercise Setup screen, accessed via navigation drawer or from the ExerciseScreen.
///Screen is used to create or update exercises.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/themes/responsive_helper.dart';
import 'exercise_setup/exercise_setup_exports.dart';
import 'package:go_router/go_router.dart';
import 'package:Gymli/widgets/app_router.dart';
import '../utils/info_dialogues.dart';

class ExerciseSetupScreen extends StatefulWidget {
  final int exerciseId;

  const ExerciseSetupScreen(this.exerciseId, {super.key});

  @override
  State<ExerciseSetupScreen> createState() => _ExerciseSetupScreenState();
}

class _ExerciseSetupScreenState extends State<ExerciseSetupScreen> {
  late ExerciseSetupController _exerciseController;

  @override
  void initState() {
    super.initState();
    _exerciseController = ExerciseSetupController();

    // Initialize with the provided exercise ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _exerciseController.initialize(widget.exerciseId);
    });
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }

  AppBar _buildAppBar(BuildContext context) {
    final isEditMode = widget.exerciseId != 0;

    return AppBar(
      title: const Text('Exercise Setup'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRouter.main),
      ),
      actions: [
        buildInfoButton('Exercise Setup Info', context,
            () => showInfoDialogExerciseSetup(context)),
        if (isEditMode)
          Consumer<ExerciseSetupController>(
            builder: (context, controller, child) {
              final hasExercise = controller.currentExercise?.id != null;
              return IconButton(
                icon: const Icon(Icons.delete),
                tooltip:
                    hasExercise ? 'Delete Exercise' : 'No Exercise to Delete',
                onPressed: hasExercise
                    ? () => _showDeleteDialog(context, controller)
                    : null,
              );
            },
          ),
      ],
    );
  }

  void _showDeleteDialog(
      BuildContext context, ExerciseSetupController controller) {
    showDialog(
      context: context,
      builder: (BuildContext dialogueContext) {
        return AlertDialog(
          title: const Text('Delete Exercise'),
          content: Text(
              'Are you sure you want to delete "${controller.currentExercise?.name}"?\n\nThis will also delete all training sets associated with this exercise. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogueContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogueContext).pop();
                final success = await controller.deleteExercise();
                if (success) {
                  if (kDebugMode) print('✅ Exercise deleted successfully');
                }

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Exercise deleted successfully')),
                  );
                  context.go(AppRouter.main);
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobileWeb = ResponsiveHelper.isWebMobile(context);

    return ChangeNotifierProvider.value(
      value: _exerciseController,
      child: Scaffold(
        appBar: _buildAppBar(context),
        resizeToAvoidBottomInset: false,
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
                        controller.initialize(widget.exerciseId);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return isMobileWeb
                ? ExerciseMobileLayoutWidget(
                    onSuccess: _handleSaveSuccess) // ✅ Add callback
                : ExerciseDesktopLayoutWidget(
                    onSuccess: _handleSaveSuccess); // ✅ Add callback
          },
        ),
      ),
    );
  }

  // ✅ Handle navigation at screen level
  void _handleSaveSuccess() {
    if (kDebugMode) print('🎯 Screen received save success callback');

    if (!mounted) {
      if (kDebugMode) print('❌ Screen widget is not mounted');
      return;
    }

    // ✅ Use post-frame callback for safe navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        if (kDebugMode) print('❌ Screen widget unmounted during callback');
        return;
      }

      final context = this.context;
      if (!context.mounted) {
        if (kDebugMode) print('❌ Screen context is not mounted');
        return;
      }

      if (kDebugMode) {
        print('✅ Screen context is mounted, attempting navigation');
      }

      try {
        if (context.canPop()) {
          if (kDebugMode) print('🔙 Can pop - using context.pop()');
          context.pop();
        } else {
          if (kDebugMode) print('🏠 Cannot pop - going to main screen');
          context.go(AppRouter.main);
        }
        if (kDebugMode) print('✅ Navigation completed successfully');
      } catch (e) {
        if (kDebugMode) print('❌ Navigation error: $e');
        // ✅ Final fallback
        try {
          if (context.mounted) {
            if (kDebugMode) print('🔄 Trying fallback navigation...');
            context.go(AppRouter.main);
          }
        } catch (fallbackError) {
          if (kDebugMode) print('❌ Fallback navigation failed: $fallbackError');
        }
      }
    });
  }
}
