/// Landing Exercise Item - Individual exercise list tile widget
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../utils/models/data_models.dart';
import '../../../utils/themes/responsive_helper.dart';

class LandingExerciseItem extends StatelessWidget {
  final Exercise exercise;
  final String metainfo;
  final VoidCallback onTap;

  const LandingExerciseItem({
    super.key,
    required this.exercise,
    required this.metainfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentIcon = _getExerciseIcon();

    return ListTile(
      leading: CircleAvatar(
        radius: 17.5,
        child: FaIcon(currentIcon),
      ),
      dense: true,
      title: Text(
        exercise.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        metainfo,
        overflow: TextOverflow.ellipsis,
        maxLines: ResponsiveHelper.isMobile(context) ? 2 : 1,
      ),
      onTap: onTap,
    );
  }

  IconData _getExerciseIcon() {
    const itemList = [
      FontAwesomeIcons.dumbbell,
      Icons.forklift,
      Icons.cable,
      Icons.sports_martial_arts
    ];

    final exerciseType = exercise.type;
    return itemList[exerciseType];
  }
}
