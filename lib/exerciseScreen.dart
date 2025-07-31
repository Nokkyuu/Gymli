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
import 'utils/responsive_helper.dart';
import 'screens/exercise/repositories/exercise_repository.dart';
import 'screens/exercise/controllers/exercise_controller.dart';
import 'screens/exercise/controllers/exercise_timer_controller.dart';
import 'screens/exercise/widgets/exercise_graph_widget.dart';
import 'screens/exercise/widgets/exercise_controls_widget.dart';
import 'screens/exercise/widgets/training_sets_list_widget.dart';
import 'utils/themes.dart';
import 'dart:math' as Math;

enum ExercisePhase { normal, deload, power }

class ExerciseScreen extends StatefulWidget {
  final String exerciseName;
  final String workoutDescription;
  final void Function(Color)? onPhaseColorChanged;

  const ExerciseScreen(this.exerciseName, this.workoutDescription,
      {super.key, this.onPhaseColorChanged});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreen();
}

class _ExerciseScreen extends State<ExerciseScreen>
    with TickerProviderStateMixin {
  bool _isMyorepActive = false;
  ExercisePhase _currentPhase = ExercisePhase.normal;
  late AnimationController _myorepParticlesController;
  final int _particleCount = 5; // Number of particles for Myo-reps
  late UniqueKey _animatedTextKey;
  late Offset _offset_start;
  late Offset _offset_end;
  late String _animatedText;
  late int _animationSpeed; // Animation duration in milliseconds

  Color _phaseColor(ExercisePhase phase) {
    switch (phase) {
      case ExercisePhase.deload:
        return ThemeColors().phaseColor['deload']!;
      case ExercisePhase.power:
        return ThemeColors().phaseColor['power']!;
      case ExercisePhase.normal:
      default:
        return ThemeColors().phaseColor['normal']!;
    }
  }

  IconData _phaseIcon(ExercisePhase phase) {
    switch (phase) {
      case ExercisePhase.deload:
        return Icons.ac_unit;
      case ExercisePhase.power:
        return Icons.flash_on;
      case ExercisePhase.normal:
      default:
        return Icons.trending_up;
    }
  }

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

  String _getPhaseText(ExercisePhase phase) {
    switch (phase) {
      case ExercisePhase.deload:
        return "Deload";
      case ExercisePhase.power:
        return "Power";
      case ExercisePhase.normal:
      default:
        return "Normal";
    }
  }

  void _initializeComponents() async {
    // Initialize clean architecture components
    _animatedTextKey = UniqueKey();
    _myorepParticlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animatedTextKey = UniqueKey();
    _repository = ExerciseRepository();
    _exerciseController = ExerciseController(repository: _repository);
    _timerController = ExerciseTimerController();
    _animatedText = "";
    _offset_start = const Offset(0, 1);
    _offset_end = const Offset(0, -1);
    _animationSpeed = 1600;
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
    _myorepParticlesController.dispose();
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
          toggleMyorepButton(context),
          togglePhaseButton(context, () {}),
          navigationButtonExerciseEdit(context),
          navigationButtonExerciseHistory(context),
        ],
      ),
      body: Stack(children: [
        SafeArea(
          child: ResponsiveHelper.isWebMobile(context)
              ? _buildMobileLayout()
              : _buildDesktopLayout(),
        ),
        _buildAnimatedText(),
      ]),
    );
  }

  myorepSparkAnimation() {
    return CustomPaint(
      painter: _MyoRepParticlesPainter(
        animation: _myorepParticlesController,
        particleCount: _particleCount,
        color: _phaseColor(_currentPhase),
      ),
    );
  }

  Center _buildAnimatedText() {
    return Center(
        child: AnimatedSwitcher(
      duration: Duration(milliseconds: _animationSpeed),
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: _offset_start,
          end: _offset_end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.slowMiddle,
        ));
        final fadeAnimation = animation.drive(
          TweenSequence([
            TweenSequenceItem(
              tween: Tween<double>(begin: 0, end: 0.5)
                  .chain(CurveTween(curve: Curves.easeInCubic)),
              weight: 50,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 0.5, end: 0)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
              weight: 50,
            ),
          ]),
        );
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      child: Text(
        _animatedText,
        key: _animatedTextKey,
        style: TextTheme.of(context).titleLarge?.copyWith(
              fontSize: 70,
              color: _phaseColor(_currentPhase),
            ),
        textAlign: TextAlign.center,
      ),
    ));
  }

  IconButton navigationButtonExerciseHistory(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseListScreen(widget.exerciseName),
          ),
        );
      },
      icon: const Icon(Icons.list),
    );
  }

  IconButton navigationButtonExerciseEdit(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseSetupScreen(widget.exerciseName),
          ),
        );
      },
      icon: const Icon(Icons.edit),
    );
  }

  Widget toggleMyorepButton(BuildContext context) {
    return Stack(children: [
      SizedBox(
          height: 40,
          width: 40,
          child: _isMyorepActive ? myorepSparkAnimation() : null),
      IconButton(
        icon: Icon(
          Icons.speed,
          color: _isMyorepActive ? ThemeColors.themeOrange : Colors.grey,
        ),
        tooltip: 'Myo-reps ${_isMyorepActive ? "aktiv" : "inaktiv"}',
        onPressed: () {
          setState(() {
            _switchMyorep();
          });
        },
      ),
    ]);
  }

  void _switchMyorep() {
    setState(() {
      _isMyorepActive = !_isMyorepActive;
      _exerciseController.updateMyoreps(_isMyorepActive);
      if (_isMyorepActive) {
        _animatedText = "Myo-Reps \n activated \n GO! GO! GO!";
      } else {
        _animatedText = "Myo-Reps \n deactivated";
      }
      _animationSpeed = 1600;
      _offset_start = const Offset(0, -1);
      _offset_end = const Offset(0, 1);
      _animatedTextKey = UniqueKey(); // Triggert AnimatedSwitcher
      // Notify listeners about the change
      widget.onPhaseColorChanged?.call(_phaseColor(_currentPhase));

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _animatedText = ""; // Clear text after animation
          });
        }
      });
    });
  }

  void _changePhase() {
    setState(() {
      _currentPhase = ExercisePhase
          .values[(_currentPhase.index + 1) % ExercisePhase.values.length];
      _animatedText = _getPhaseText(_currentPhase);
      _offset_start = const Offset(-1.5, 0);
      _offset_end = const Offset(1.5, 0);
      _animationSpeed = 1200;
      _animatedTextKey = UniqueKey(); // Triggert AnimatedSwitcher
      _exerciseController.updatePhase(_currentPhase.name);
    });
    // Timer zum Ausblenden nach 1,2 Sekunden
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _animatedText = ""; // Clear text after animation
        });
      }
    });

    widget.onPhaseColorChanged
        ?.call(_phaseColor(_currentPhase)); // <- Theme ändern
  }

  Widget togglePhaseButton(BuildContext context, VoidCallback? onChanged) {
    return IconButton(
      icon: Icon(
        _phaseIcon(_currentPhase),
        color: _phaseColor(_currentPhase),
      ),
      tooltip: () {
        switch (_currentPhase) {
          case ExercisePhase.deload:
            return "Deload-Phase";
          case ExercisePhase.power:
            return "Power-Phase";
          case ExercisePhase.normal:
          default:
            return "normal-Phase";
        }
      }(),
      onPressed: () {
        _changePhase();
        if (onChanged != null) onChanged();
      },
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

class _MyoRepParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final int particleCount;
  final Color color;

  _MyoRepParticlesPainter({
    required this.animation,
    required this.particleCount,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2.2;
    final double particleLifetime = 0.8; // Wie lange ein Partikel lebt (0-1)

    for (int i = 0; i < particleCount; i++) {
      // Jeder Partikel startet versetzt über die gesamte Animation
      final double spawnTime = (i / particleCount) % 1.0;

      // Berechne den aktuellen Fortschritt für diesen Partikel
      double localTime = (animation.value - spawnTime) % 1.0;
      if (localTime < 0) localTime += 1.0;

      // Normalisiere auf die Lebensdauer des Partikels
      double t = localTime / particleLifetime;

      // Skip wenn Partikel nicht aktiv ist
      if (t > 1.0) continue;

      // Seed für Richtung: basierend auf aktuellem Loop und Partikel-Index
      int currentLoop = (animation.value / 1.0).floor();
      final rand = Math.Random(currentLoop * particleCount + i);
      final angle = rand.nextDouble() * 2 * Math.pi;

      final particleRadius = maxRadius * t;
      final dx = center.dx + particleRadius * Math.cos(angle);
      final dy = center.dy + particleRadius * Math.sin(angle);
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dx, dy), 6 * (1 - t), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MyoRepParticlesPainter oldDelegate) => true;
}
