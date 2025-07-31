import 'package:flutter/material.dart';
import '../controllers/exercise_animation_controller.dart';
import '../controllers/exercise_phase_controller.dart';

class AnimatedTextWidget extends StatelessWidget {
  final ExerciseAnimationController animationController;
  final ExercisePhaseController phaseController;

  const AnimatedTextWidget({
    super.key,
    required this.animationController,
    required this.phaseController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListenableBuilder(
        listenable: animationController,
        builder: (context, child) {
          return AnimatedSwitcher(
            duration:
                Duration(milliseconds: animationController.animationSpeed),
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: animationController.offsetStart,
                end: animationController.offsetEnd,
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
              animationController.animatedText,
              key: animationController.animatedTextKey,
              style: TextTheme.of(context).titleLarge?.copyWith(
                    fontSize: 70,
                    color: phaseController.phaseColor,
                  ),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}
