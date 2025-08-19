///Exercise Setup screen, accessed via navigation drawer or from the ExerciseScreen.
///Screen is used to create or update exercises.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/themes/responsive_helper.dart';
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
}
