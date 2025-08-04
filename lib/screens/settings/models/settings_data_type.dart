/// Settings Data Type - Enum and utilities for data types
library;

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

enum SettingsDataType {
  trainingSets('TrainingSets', 'Trainings', FontAwesomeIcons.chartLine),
  exercises('Exercises', 'Exercises', FontAwesomeIcons.list),
  workouts('Workouts', 'Workouts', FontAwesomeIcons.clipboardList),
  foods('Foods', 'Foods', FontAwesomeIcons.utensils);

  const SettingsDataType(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final IconData icon;

  static SettingsDataType fromString(String value) {
    return SettingsDataType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SettingsDataType.trainingSets,
    );
  }
}
