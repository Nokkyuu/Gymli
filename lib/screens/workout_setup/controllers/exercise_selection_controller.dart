import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../utils/models/data_models.dart';

class ExerciseSelectionController extends ChangeNotifier {
  // Exercise selection data
  ApiExercise? _selectedExercise;
  int _warmups = 0;
  int _worksets = 1;

  // Form controller for mobile dropdown
  final TextEditingController exerciseController = TextEditingController();

  // Icon mapping for exercise types
  final List<IconData> itemList = [
    FontAwesomeIcons.dumbbell,
    Icons.forklift,
    Icons.cable,
    Icons.sports_martial_arts
  ];

  // Getters
  ApiExercise? get selectedExercise => _selectedExercise;
  int get warmups => _warmups;
  int get worksets => _worksets;

  // Set selected exercise
  void setSelectedExercise(ApiExercise? exercise) {
    _selectedExercise = exercise;
    if (exercise != null) {
      exerciseController.text = exercise.name;
    }
    notifyListeners();
  }

  // Update warmup sets
  void updateWarmups(int value) {
    if (value >= 0 && value <= 10) {
      _warmups = value;
      notifyListeners();
    }
  }

  // Update work sets
  void updateWorksets(int value) {
    if (value >= 0 && value <= 10) {
      _worksets = value;
      notifyListeners();
    }
  }

  // Get icon for exercise type
  IconData getExerciseIcon(int type) {
    if (type >= 0 && type < itemList.length) {
      return itemList[type];
    }
    return itemList[0]; // default to dumbbell
  }

  // Reset selection
  void reset() {
    _selectedExercise = null;
    _warmups = 0;
    _worksets = 1;
    exerciseController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    exerciseController.dispose();
    super.dispose();
  }
}
