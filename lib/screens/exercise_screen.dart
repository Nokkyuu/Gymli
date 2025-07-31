/// Exercise Screen - Main Workout Interface
library;

import 'package:flutter/material.dart';
import '../utils/themes/responsive_helper.dart';
import 'exercise/repositories/exercise_repository.dart';
import 'exercise/controllers/exercise_controller.dart';
import 'exercise/controllers/exercise_timer_controller.dart';
import 'exercise/controllers/exercise_phase_controller.dart';
import 'exercise/controllers/exercise_animation_controller.dart';
import 'exercise/widgets/exercise_graph_widget.dart';
import 'exercise/widgets/exercise_controls_widget.dart';
import 'exercise/widgets/training_sets_list_widget.dart';
import 'exercise/widgets/exercise_app_bar_widget.dart';
import 'exercise/widgets/animated_text_widget.dart';

class ExerciseScreen extends StatefulWidget {
  final String exerciseName;
  final String workoutDescription;
  final void Function(Color)? onPhaseColorChanged;

  const ExerciseScreen(this.exerciseName, this.workoutDescription,
      {super.key, this.onPhaseColorChanged});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with TickerProviderStateMixin {
  // Controllers
  late ExerciseRepository _repository;
  late ExerciseController _exerciseController;
  late ExerciseTimerController _timerController;
  late ExercisePhaseController _phaseController;
  late ExerciseAnimationController _animationController;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() async {
    // Initialize controllers
    _repository = ExerciseRepository();
    _exerciseController = ExerciseController(repository: _repository);
    _timerController = ExerciseTimerController();
    _phaseController = ExercisePhaseController(
      onPhaseColorChanged: widget.onPhaseColorChanged,
    );
    _animationController = ExerciseAnimationController();

    // Initialize animation controller
    _animationController.initialize(this);

    // Initialize exercise data
    await _exerciseController.initialize(
        widget.exerciseName, widget.workoutDescription);

    // Initialize timer
    _timerController.initialize();

    // Listen to animation controller for myorep updates
    _animationController.addListener(() {
      _exerciseController.updateMyoreps(_animationController.isMyorepActive);
    });

    // Listen to phase controller for phase updates
    _phaseController.addListener(() {
      _exerciseController.updatePhase(_phaseController.currentPhase.name);
    });

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _exerciseController.dispose();
    _timerController.dispose();
    _phaseController.dispose();
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
      appBar: ExerciseAppBarWidget(
        exerciseName: widget.exerciseName,
        phaseController: _phaseController,
        animationController: _animationController,
        timerController: _timerController,
      ),
      body: Stack(children: [
        SafeArea(
          child: ResponsiveHelper.isWebMobile(context)
              ? _buildMobileLayout()
              : _buildDesktopLayout(),
        ),
        AnimatedTextWidget(
          animationController: _animationController,
          phaseController: _phaseController,
        ),
      ]),
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
            100;

        final graphHeight = (availableHeight * 0.35);
        final listHeight = (availableHeight * 0.35);

        return Column(children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: graphHeight,
                    child: ExerciseGraphWidget(
                      graphController: _exerciseController.graphController,
                      groupExercises: const [],
                    ),
                  ),
                  ExerciseControlsWidget(
                    controller: _exerciseController,
                    isDesktop: false,
                    onSubmit: _onSetAdded,
                  ),
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
        Expanded(
          flex: 2,
          child: Column(
            children: [
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
    await _exerciseController.refreshGraphData(widget.exerciseName);
    _timerController.updateLastActivity();
  }
}
