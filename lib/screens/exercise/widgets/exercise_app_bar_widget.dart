import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Gymli/config/app_router.dart';
import '../controllers/exercise_phase_controller.dart';
import '../controllers/exercise_animation_controller.dart';
import '../controllers/exercise_timer_controller.dart';
import '../controllers/exercise_controller.dart';

class ExerciseAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final int exerciseId;
  final String exerciseName;
  final ExerciseController exerciseController;
  final ExercisePhaseController phaseController;
  final ExerciseAnimationController animationController;
  final ExerciseTimerController timerController;

  const ExerciseAppBarWidget({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.phaseController,
    required this.animationController,
    required this.timerController,
    required this.exerciseController,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: InkWell(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios),
      ),
      title: Text(exerciseName),
      bottom: PreferredSize(
        preferredSize: Size.zero,
        child: ListenableBuilder(
          listenable: timerController,
          builder: (context, _) => Text(
            timerController.timerText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
      actions: [
        _buildMyorepButton(context),
        _buildPhaseButton(context),
        _buildEditButton(context),
        _buildHistoryButton(context),
      ],
    );
  }

  Widget _buildMyorepButton(BuildContext context) {
    return ListenableBuilder(
      listenable: animationController,
      builder: (context, child) {
        return Stack(children: [
          SizedBox(
            height: 40,
            width: 40,
            child: animationController.isMyorepActive
                ? CustomPaint(
                    painter: animationController
                        .createMyorepPainter(phaseController.phaseColor),
                  )
                : null,
          ),
          IconButton(
              icon: Icon(
                Icons.speed,
                color: animationController.isMyorepActive
                    ? phaseController.phaseColor
                    : Colors.grey,
              ),
              tooltip:
                  'Myo-reps ${animationController.isMyorepActive ? "aktiv" : "inaktiv"}',
              onPressed: () {
                animationController.switchMyorep();

                Future.delayed(const Duration(milliseconds: 1200), () {
                  animationController.clearAnimatedText();
                });
              }),
        ]);
      },
    );
  }

  Widget _buildPhaseButton(BuildContext context) {
    return ListenableBuilder(
      listenable: phaseController,
      builder: (context, child) {
        return IconButton(
          icon: Icon(
            phaseController.phaseIcon,
            color: phaseController.phaseColor,
          ),
          tooltip: "${phaseController.phaseText}-Phase",
          onPressed: () {
            phaseController.changePhase();
            animationController.showPhaseAnimation(phaseController.phaseText);

            // Clear animation after delay
            Future.delayed(const Duration(milliseconds: 1200), () {
              animationController.clearAnimatedText();
            });
          },
        );
      },
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.push(
            '${AppRouter.exerciseSetup}?type=${Uri.encodeComponent(exerciseName)}');
      },
      icon: const Icon(Icons.edit),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        final queryParams = {
          'id': exerciseId.toString(),
          'name': Uri.encodeComponent(exerciseName),
        };
        final queryString =
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

        context.push('${AppRouter.exerciseHistory}?$queryString');
      },
      icon: const Icon(Icons.list),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);
}
