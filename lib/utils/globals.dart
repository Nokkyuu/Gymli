/// Global Variables and Constants for Gymli Application
///
library;

import 'package:Gymli/utils/models/data_models.dart';
import 'package:flutter/foundation.dart';

// User preference settings
int idleTimerWakeup = 90; // Idle timer wakeup time in seconds
int graphNumberOfDays = 300; // Number of days to show in statistics graphs
bool detailedGraph = false; // Whether to show detailed graph view

// Muscle group activation values - tracks current muscle targeting
// Used for exercise creation and analysis
var muscle_val = {
  "Pectoralis major": 0.0, // Chest muscle activation (0.0-1.0)
  "Trapezius": 0.0, // Upper back/neck activation
  "Biceps": 0.0, // Bicep muscle activation
  "Abdominals": 0.0, // Core/abs activation
  "Front Delts": 0.0, // Front shoulder activation
  "Deltoids": 0.0, // Main shoulder activation
  "Back Delts": 0.0, // Rear shoulder activation
  "Latissimus dorsi": 0.0, // Lat/back activation
  "Triceps": 0.0, // Tricep muscle activation
  "Gluteus maximus": 0.0, // Glute activation
  "Hamstrings": 0.0, // Hamstring activation
  "Quadriceps": 0.0, // Quad activation
  "Forearms": 0.0, // Forearm activation
  "Calves": 0.0 // Calf activation
};

List<String> exerciseList = [];

double calculateScoreWithExercise(
    //TODO: extract so somewhere
    ApiTrainingSet trainingSet,
    ApiExercise exercise) {
  return trainingSet.weight +
      (((trainingSet.repetitions - exercise.defaultRepBase) /
              (exercise.defaultRepMax - exercise.defaultRepBase)) *
          exercise.defaultIncrement);
}

List<List> muscleHistoryScore = [];

final ValueNotifier<bool> exerciseDataChangedNotifier =
    ValueNotifier<bool>(false);

void notifyExerciseDataChanged() {
  exerciseDataChangedNotifier.value = !exerciseDataChangedNotifier.value;
}
