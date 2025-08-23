/// Landing Exercise List - Exercise list view with responsive layout
library;

import 'package:flutter/material.dart';
import '../../../utils/models/data_models.dart';
import '../../../utils/themes/responsive_helper.dart';
import 'landing_exercise_item.dart';

class LandingExerciseList extends StatelessWidget {
  final List<Exercise> exercises;
  final List<String> metainfo;
  final Function(Exercise, String) onExerciseTap;

  const LandingExerciseList({
    super.key,
    required this.exercises,
    required this.metainfo,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Center(child: Text("No exercises yet"));
    }

    return ResponsiveHelper.isMobile(context)
        ? _buildMobileListView()
        : _buildDesktopGridView(context);
  }

  Widget _buildMobileListView() {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) => _buildExerciseItem(index),
    );
  }

  Widget _buildDesktopGridView(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isDesktop(context) ? 4 : 3,
        childAspectRatio: 4.0,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          child: _buildExerciseItem(index),
        );
      },
    );
  }

  Widget _buildExerciseItem(int index) {
    final exercise = exercises[index];
    final meta = index < metainfo.length
        ? metainfo[index]
        : '${exercise.defaultRepBase}-${exercise.defaultRepMax} Reps';

    return LandingExerciseItem(
      exercise: exercise,
      metainfo: meta,
      onTap: () => _handleExerciseTap(exercise, meta),
    );
  }

  void _handleExerciseTap(Exercise exercise, String meta) {
    String description = "";
    if (meta.split(":").isNotEmpty && meta.split(":")[0] == "Warm") {
      description = meta;
    }
    onExerciseTap(exercise, description);
  }
}
