/// Muscle Constants - Muscle Group Names, Colors, and Coordinate Mappings
///
/// This file contains all constants related to muscle groups used in statistics
/// and visualizations throughout the application.
library;

import 'package:flutter/material.dart';

/// Muscle group names as displayed in charts and UI
const List<String> muscleNames = [
  "Pecs", // 0 - Pectoralis major
  "Trapz", // 1 - Trapezius
  "Biceps", // 2 - Biceps
  "Abs", // 3 - Abdominals
  "Front-D", // 4 - Front Delts
  "Delts", // 5 - Deltoids (Side)
  "Back-D", // 6 - Back Delts
  "Lats", // 7 - Latissimus dorsi
  "Triceps", // 8 - Triceps
  "Glutes", // 9 - Gluteus maximus
  "Hams", // 10 - Hamstrings
  "Quads", // 11 - Quadriceps
  "Forearms", // 12 - Forearms
  "Calves", // 13 - Calves
];

/// Colors assigned to each muscle group for consistent visualization
const List<Color> muscleColors = [
  Color.fromARGB(255, 166, 206, 227), // Pecs
  Color.fromARGB(255, 202, 178, 214), // Trapz
  Color.fromARGB(255, 178, 223, 138), // Biceps
  Color.fromARGB(255, 51, 160, 44), // Abs
  Color.fromARGB(255, 251, 154, 153), // Front-D
  Color.fromARGB(255, 251, 154, 153), // Delts
  Color.fromARGB(255, 251, 154, 153), // Back-D
  Color.fromARGB(255, 31, 120, 180), // Lats
  Color.fromARGB(255, 227, 26, 28), // Triceps
  Color.fromARGB(255, 255, 127, 0), // Glutes
  Color.fromARGB(255, 253, 191, 111), // Hams
  Color.fromARGB(255, 106, 61, 154), // Quads
  Color.fromARGB(255, 255, 255, 153), // Forearms
  Color.fromARGB(255, 177, 89, 40), // Calves
];

/// Coordinate mapping for muscle heatmap visualization
/// Each list contains [x, y] coordinates as percentages (0.0 to 1.0)
const List<List<double>> muscleHeatmapCoordinates = [
  [0.25, 0.73], // pectoralis
  [0.75, 0.80], // trapezius
  [0.37, 0.68], // biceps
  [0.25, 0.59], // abs
  [0.36, 0.79], // Front delts
  [0.64, 0.85], // Side Delts
  [0.64, 0.75], // Back Delts
  [0.74, 0.65], // latissimus
  [0.61, 0.68], // triceps
  [0.74, 0.50], // glutes
  [0.71, 0.40], // hamstrings
  [0.29, 0.41], // quadriceps
  [0.4, 0.57], // forearms
  [0.31, 0.20], // calves
];

/// Mapping of muscle group full names to their index in the arrays above
const Map<String, int> muscleNameToIndex = {
  "Pectoralis major": 0,
  "Trapezius": 1,
  "Biceps": 2,
  "Abdominals": 3,
  "Front Delts": 4,
  "Deltoids": 5,
  "Back Delts": 6,
  "Latissimus dorsi": 7,
  "Triceps": 8,
  "Gluteus maximus": 9,
  "Hamstrings": 10,
  "Quadriceps": 11,
  "Forearms": 12,
  "Calves": 13,
};

/// Get muscle color by index
Color getMuscleColor(int index) {
  if (index >= 0 && index < muscleColors.length) {
    return muscleColors[index];
  }
  return Colors.grey; // Default color for invalid index
}

/// Get muscle name by index
String getMuscleName(int index) {
  if (index >= 0 && index < muscleNames.length) {
    return muscleNames[index];
  }
  return "Unknown"; // Default name for invalid index
}

/// Get muscle coordinates by index
List<double>? getMuscleCoordinates(int index) {
  if (index >= 0 && index < muscleHeatmapCoordinates.length) {
    return muscleHeatmapCoordinates[index];
  }
  return null; // Invalid index
}

/// Get muscle index by full name
int? getMuscleIndex(String muscleName) {
  return muscleNameToIndex[muscleName];
}
