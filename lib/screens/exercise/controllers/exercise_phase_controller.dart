import 'package:flutter/material.dart';
import '../../../utils/themes/themes.dart';

enum ExercisePhase { normal, deload, power }

class ExercisePhaseController extends ChangeNotifier {
  ExercisePhase _currentPhase = ExercisePhase.normal;
  final void Function(Color)? _onPhaseColorChanged;

  ExercisePhaseController({void Function(Color)? onPhaseColorChanged})
      : _onPhaseColorChanged = onPhaseColorChanged;

  ExercisePhase get currentPhase => _currentPhase;

  Color get phaseColor {
    switch (_currentPhase) {
      case ExercisePhase.deload:
        return ThemeColors().phaseColor['deload']!;
      case ExercisePhase.power:
        return ThemeColors().phaseColor['power']!;
      case ExercisePhase.normal:
      default:
        return ThemeColors().phaseColor['normal']!;
    }
  }

  IconData get phaseIcon {
    switch (_currentPhase) {
      case ExercisePhase.deload:
        return Icons.ac_unit;
      case ExercisePhase.power:
        return Icons.flash_on;
      case ExercisePhase.normal:
      default:
        return Icons.trending_up;
    }
  }

  String get phaseText {
    switch (_currentPhase) {
      case ExercisePhase.deload:
        return "Deload";
      case ExercisePhase.power:
        return "Power";
      case ExercisePhase.normal:
      default:
        return "Normal";
    }
  }

  void changePhase() {
    _currentPhase = ExercisePhase
        .values[(_currentPhase.index + 1) % ExercisePhase.values.length];
    //_onPhaseColorChanged?.call(phaseColor);
    //TODO: remove, implement or change
    notifyListeners();
  }
}
