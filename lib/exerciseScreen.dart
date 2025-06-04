/// Exercise Screen - Main Workout Interface
///
/// Refactored to use a clean architecture with separated concerns:
/// - Repository pattern for data management
/// - Controller pattern for business logic
/// - Widget composition for UI components
library;

import 'package:flutter/material.dart';
import 'package:Gymli/exerciseListScreen.dart';
import 'package:Gymli/exerciseSetupScreen.dart';
import 'responsive_helper.dart';
import 'screens/exercise/repositories/exercise_repository.dart';
import 'screens/exercise/controllers/exercise_controller.dart';
import 'screens/exercise/controllers/exercise_timer_controller.dart';
import 'screens/exercise/widgets/exercise_graph_widget.dart';
import 'screens/exercise/widgets/exercise_controls_widget.dart';
import 'screens/exercise/widgets/training_sets_list_widget.dart';

class ExerciseScreen extends StatefulWidget {
  final String exerciseName;
  final String workoutDescription;

  const ExerciseScreen(this.exerciseName, this.workoutDescription, {super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreen();
}

class _ExerciseScreen extends State<ExerciseScreen> {
  // Clean architecture components
  late ExerciseRepository _repository;
  late ExerciseController _exerciseController;
  late ExerciseTimerController _timerController;

  // State management
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() async {
    // Initialize clean architecture components
    _repository = ExerciseRepository();
    _exerciseController = ExerciseController(repository: _repository);
    _timerController = ExerciseTimerController();

    // Initialize the exercise data
    await _exerciseController.initialize(
        widget.exerciseName, widget.workoutDescription);

    // Initialize timer
    _timerController.initialize();

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(widget.exerciseName),
        bottom: PreferredSize(
          preferredSize: Size.zero,
          child: ListenableBuilder(
            listenable: _timerController,
            builder: (context, _) => Text(
              _timerController.timerText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ExerciseSetupScreen(widget.exerciseName),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseListScreen(widget.exerciseName),
                ),
              );
            },
            icon: const Icon(Icons.list),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveHelper.isWebMobile(context)
            ? _buildMobileLayout()
            : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final availableHeight = screenHeight -
            MediaQuery.of(context).padding.top -
            MediaQuery.of(context).padding.bottom -
            kToolbarHeight -
            100; // Account for app bar and margins

        final graphHeight = (availableHeight * 0.35);
        final listHeight = (availableHeight * 0.35);

        return Column(children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: availableHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Graph Section
                  SizedBox(
                    height: graphHeight,
                    child: ExerciseGraphWidget(
                      graphController: _exerciseController.graphController,
                      groupExercises: const [],
                    ),
                  ),

                  // Exercise Controls
                  ExerciseControlsWidget(
                    controller: _exerciseController,
                    isDesktop: false,
                    onSubmit: _onSetAdded,
                  ),

                  // Training Sets List
                  SizedBox(
                    height: listHeight,
                    child: TrainingSetsListWidget(
                      controller: _exerciseController,
                      showTitle: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Main workout interface
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Graph Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ExerciseGraphWidget(
                    graphController: _exerciseController.graphController,
                    groupExercises: const [],
                  ),
                ),
              ),

              const Divider(),

              // Exercise Controls
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ExerciseControlsWidget(
                    controller: _exerciseController,
                    isDesktop: true,
                    onSubmit: _onSetAdded,
                  ),
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(),

        // Right side - Training sets list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TrainingSetsListWidget(
              controller: _exerciseController,
              showTitle: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onSetAdded() async {
    // Update graph data after adding a set
    await _exerciseController.refreshGraphData(widget.exerciseName);

    // Update timer
    _timerController.updateLastActivity();
  }
}
