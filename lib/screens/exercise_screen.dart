/// Exercise Screen - Main Workout Interface
library;

import 'package:Gymli/utils/workout_session_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/themes/responsive_helper.dart';
import '../utils/workout_data_cache.dart';
import 'exercise/controllers/exercise_controller.dart';
import 'exercise/controllers/exercise_timer_controller.dart';
import 'exercise/controllers/exercise_phase_controller.dart';
import 'exercise/controllers/exercise_animation_controller.dart';
import 'exercise/widgets/exercise_graph_widget.dart';
import 'exercise/widgets/exercise_controls_widget.dart';
import 'exercise/widgets/training_sets_list_widget.dart';
import 'exercise/widgets/exercise_app_bar_widget.dart';
import 'exercise/widgets/animated_text_widget.dart';
import 'package:get_it/get_it.dart';


class ExerciseScreen extends StatefulWidget {
  final int exerciseId;
  final String exerciseName;
  final String workoutDescription;
  final void Function(Color)? onPhaseColorChanged;

  const ExerciseScreen(
      this.exerciseId, this.exerciseName, this.workoutDescription,
      {super.key, this.onPhaseColorChanged});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with TickerProviderStateMixin {
  // Controllers
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

  @override
  void didUpdateWidget(covariant ExerciseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final switchedExercise = oldWidget.exerciseId != widget.exerciseId || oldWidget.exerciseName != widget.exerciseName;
    if (switchedExercise) {
      final cache = GetIt.I<WorkoutDataCache>();
      cache.markActiveExercise(widget.exerciseId);
      print("A: caching?");
      final cached = cache.getCachedTrainingSets(widget.exerciseId);
      if (cached != null && cached.isNotEmpty) {
        _exerciseController.graphController.updateGraphFromTrainingSets(cached);
      } else {
        // Fall back to controller refresh which will fetch & populate cache
        _exerciseController.refreshGraphData(widget.exerciseName);
      }
    }
  }

  void _initializeComponents() async {
    // Initialize controllers
    _exerciseController = ExerciseController();
    _timerController = ExerciseTimerController();
    _phaseController = ExercisePhaseController(
      onPhaseColorChanged: widget.onPhaseColorChanged,
    );
    _animationController = ExerciseAnimationController();

    // Mark this exercise as active in the LRU cache and try to render graph from cache
    final cache = GetIt.I<WorkoutDataCache>();
    cache.markActiveExercise(widget.exerciseId);
    final cached = cache.getCachedTrainingSets(widget.exerciseId);
    if (cached != null && cached.isNotEmpty) {
      // GraphController is ready after ExerciseController construction
      _exerciseController.graphController.updateGraphFromTrainingSets(cached);
    }

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

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _exerciseController),
        ChangeNotifierProvider.value(value: _timerController),
        ChangeNotifierProvider.value(value: _phaseController),
        ChangeNotifierProvider.value(value: _animationController),
      ],
      child: Consumer<ExerciseController>(
        builder: (context, exerciseController, child) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: ExerciseAppBarWidget(
              exerciseId: widget.exerciseId,
              exerciseName: widget.exerciseName,
              phaseController: _phaseController,
              animationController: _animationController,
              timerController: _timerController,
              exerciseController: _exerciseController,
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
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Consumer<ExerciseController>(
      builder: (context, exerciseController, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;
            final availableHeight = screenHeight -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom -
                kToolbarHeight -
                100;

            final graphHeight = (availableHeight * 0.35);
            final listHeight = (availableHeight * 0.4);

            return Column(children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 5, top: 10),
                  child: Column(
                    children: [
                      SizedBox(
                        height: graphHeight,
                        child: ExerciseGraphWidget(
                          graphController: exerciseController.graphController,
                          groupExercises: const [],
                        ),
                      ),
                      ExerciseControlsWidget(
                        controller: exerciseController,
                        isDesktop: false,
                        onSubmit: _onSetAdded,
                      ),
                      SizedBox(
                        height: listHeight,
                        child: TrainingSetsListWidget(
                          controller: exerciseController,
                          showTitle: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]);
          },
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Consumer<ExerciseController>(
      builder: (context, exerciseController, child) {
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
                        graphController: exerciseController.graphController,
                        groupExercises: const [],
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ExerciseControlsWidget(
                        controller: exerciseController,
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
                  controller: exerciseController,
                  showTitle: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onSetAdded() async {
    final workoutState = GetIt.I<WorkoutSessionManager>().getSession();
    workoutState.addExercise(widget.exerciseName);
    await _exerciseController.refreshGraphData(widget.exerciseName);
    _timerController.updateLastActivity();
  }
}
