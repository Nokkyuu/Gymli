import 'package:flutter/material.dart';
import 'dart:math' as Math;

class ExerciseAnimationController extends ChangeNotifier {
  late AnimationController _myorepParticlesController;
  late UniqueKey _animatedTextKey;
  late Offset _offsetStart;
  late Offset _offsetEnd;
  late String _animatedText;
  late int _animationSpeed;

  bool _isMyorepActive = false;
  final int _particleCount = 5;

  bool get isMyorepActive => _isMyorepActive;
  String get animatedText => _animatedText;
  UniqueKey get animatedTextKey => _animatedTextKey;
  Offset get offsetStart => _offsetStart;
  Offset get offsetEnd => _offsetEnd;
  int get animationSpeed => _animationSpeed;

  void initialize(TickerProvider vsync) {
    _myorepParticlesController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animatedTextKey = UniqueKey();
    _animatedText = "";
    _offsetStart = const Offset(0, 1);
    _offsetEnd = const Offset(0, -1);
    _animationSpeed = 1600;
  }

  void switchMyorep() {
    _isMyorepActive = !_isMyorepActive;

    if (_isMyorepActive) {
      _animatedText = "Myo-Reps \n GO! GO! GO!";
    } else {
      _animatedText = "Myo-Reps \n deactivated";
    }

    _animationSpeed = 1000;
    _offsetStart = const Offset(0, -1);
    _offsetEnd = const Offset(0, 1);
    _animatedTextKey = UniqueKey();

    notifyListeners();
  }

  void showPhaseAnimation(String phaseText) {
    _animatedText = phaseText;
    _offsetStart = const Offset(-1.5, 0);
    _offsetEnd = const Offset(1.5, 0);
    _animationSpeed = 1200;
    _animatedTextKey = UniqueKey();

    notifyListeners();
  }

  void clearAnimatedText() {
    _animatedText = "";
    notifyListeners();
  }

  CustomPainter createMyorepPainter(Color color) {
    return _MyoRepParticlesPainter(
      animation: _myorepParticlesController,
      particleCount: _particleCount,
      color: color,
    );
  }

  void dispose() {
    _myorepParticlesController.dispose();
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
    final double particleLifetime = 0.8;

    for (int i = 0; i < particleCount; i++) {
      final double spawnTime = (i / particleCount) % 1.0;
      double localTime = (animation.value - spawnTime) % 1.0;
      if (localTime < 0) localTime += 1.0;

      double t = localTime / particleLifetime;
      if (t > 1.0) continue;

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
