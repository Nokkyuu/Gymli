import 'package:flutter/foundation.dart';
import '../../../utils/globals.dart' as globals;
import '../../../utils/api/api_models.dart';

class MuscleSelectionController extends ChangeNotifier {
  // Muscle data
  final List<List<String>> frontImages = [
    ['images/muscles/Front_biceps.png', 'Biceps'],
    ['images/muscles/Front_calves.png', 'Calves'],
    ['images/muscles/Front_Front_delts.png', 'Front Delts'],
    ['images/muscles/Front_forearms.png', 'Forearms'],
    ['images/muscles/Front_pecs.png', 'Pectoralis major'],
    ['images/muscles/Front_quads.png', 'Quadriceps'],
    ['images/muscles/Front_sideabs.png', 'Abdominals'],
    ['images/muscles/Front_abs.png', 'Abdominals'],
    ['images/muscles/Front_trapz.png', 'Trapezius'],
    ['images/muscles/Front_abs.png', 'Abdominals']
  ];

  final List<List<String>> backImages = [
    ['images/muscles/Back_calves.png', 'Calves'],
    ['images/muscles/Back_Back_delts.png', 'Back Delts'],
    ['images/muscles/Back_Back_delts2.png', 'Back Delts'],
    ['images/muscles/Back_Front_delts.png', 'Front Delts'],
    ['images/muscles/Back_Side_delts.png', 'Deltoids'],
    ['images/muscles/Back_forearms.png', 'Forearms'],
    ['images/muscles/Back_glutes.png', 'Gluteus maximus'],
    ['images/muscles/Back_hamstrings.png', 'Hamstrings'],
    ['images/muscles/Back_lats.png', 'Latissimus dorsi'],
    ['images/muscles/Back_trapz.png', 'Trapezius'],
    ['images/muscles/Back_triceps.png', 'Triceps'],
  ];

  final List<List> frontButtons = [
    [0.35, 0.4, 'Biceps'],
    [0.46, 0.4, 'Forearms'],
    [0.25, 0.4, 'Front Delts'],
    [0.28, 0.7, 'Pectoralis major'],
    [0.4, 0.7, 'Abdominals'],
    [0.2, 0.7, 'Trapezius'],
    [0.6, 0.62, 'Quadriceps'],
    [0.8, 0.58, 'Calves'],
  ];

  final List<List> backButtons = [
    [0.82, 0.6, 'Calves'],
    [0.2, 0.45, 'Deltoids'],
    [0.26, 0.38, 'Back Delts'],
    [0.5, 0.4, 'Forearms'],
    [0.55, 0.7, 'Gluteus maximus'],
    [0.68, 0.6, 'Hamstrings'],
    [0.4, 0.7, 'Latissimus dorsi'],
    [0.2, 0.7, 'Trapezius'],
    [0.35, 0.4, 'Triceps'],
  ];

  // Toggle muscle intensity (cycles through 0%, 25%, 50%, 75%, 100%)
  void toggleMuscle(String muscleName) {
    double currentValue = globals.muscle_val[muscleName] ?? 0.0;
    double newValue = _cycleOpacity(currentValue);
    globals.muscle_val[muscleName] = newValue;
    notifyListeners();
  }

  // Get current muscle intensity
  double getMuscleIntensity(String muscleName) {
    return globals.muscle_val[muscleName] ?? 0.0;
  }

  // Get muscle intensity as percentage
  int getMusclePercentage(String muscleName) {
    return (getMuscleIntensity(muscleName) * 100).round();
  }

  // Reset all muscles to 0
  void resetAllMuscles() {
    for (var m in muscleGroupNames) {
      globals.muscle_val[m] = 0.0;
    }
    notifyListeners();
  }

  // Set muscle intensity directly
  void setMuscleIntensity(String muscleName, double intensity) {
    globals.muscle_val[muscleName] = intensity.clamp(0.0, 1.0);
    notifyListeners();
  }

  // Get list of active muscles
  List<String> getActiveMuscles() {
    final activeMuscles = <String>[];
    for (var entry in globals.muscle_val.entries) {
      if (entry.value > 0) {
        activeMuscles.add(entry.key);
      }
    }
    return activeMuscles;
  }

  // Get formatted string of active muscles with percentages
  String getActiveMusclesString() {
    final activeMuscles = <String>[];
    for (var entry in globals.muscle_val.entries) {
      if (entry.value > 0) {
        activeMuscles.add('${entry.key} (${(entry.value * 100).round()}%)');
      }
    }
    return activeMuscles.isEmpty ? 'None selected' : activeMuscles.join(', ');
  }

  // Private helper to cycle through opacity values
  double _cycleOpacity(double currentOpacity) {
    if (currentOpacity >= 1.0) {
      return 0.0;
    } else {
      return currentOpacity + 0.25;
    }
  }
}
