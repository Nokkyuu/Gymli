import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../utils/globals.dart' as globals;
import '../../../utils/services/temp_service.dart';
import '../../../utils/api/api_models.dart';
import 'package:get_it/get_it.dart';
import '../../../utils/api/api.dart';

enum ExerciseDevice { free, machine, cable, body }

class ExerciseSetupController extends ChangeNotifier {
  final TempService _container = GetIt.I<TempService>();

  final ExerciseService exerciseService = GetIt.I<ExerciseService>();

  // Exercise data
  String _exerciseName = '';
  ExerciseDevice _chosenDevice = ExerciseDevice.free;
  double _minRep = 10;
  double _maxRep = 15;
  RangeValues _repRange = const RangeValues(10, 20);
  double _weightInc = 2.5;
  ApiExercise? _currentExercise;

  // Form controller
  final TextEditingController exerciseTitleController = TextEditingController();

  // Loading state
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String get exerciseName => _exerciseName;
  ExerciseDevice get chosenDevice => _chosenDevice;
  double get minRep => _minRep;
  double get maxRep => _maxRep;
  RangeValues get repRange => _repRange;
  double get weightInc => _weightInc;
  ApiExercise? get currentExercise => _currentExercise;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize with exercise name
  void initialize(String exerciseName) {
    _exerciseName = exerciseName;
    exerciseTitleController.text = exerciseName;
    if (exerciseName.isNotEmpty) {
      _loadExerciseData();
    }
  }

  // Load existing exercise data
  Future<void> _loadExerciseData() async {
    if (_exerciseName.isEmpty) return;

    _setLoading(true);
    try {
      final List<ApiExercise> exercises = await exerciseService.getExercises();
      ApiExercise? exerciseData;
      try {
        exerciseData = exercises.firstWhere(
        (item) => item.name == _exerciseName);
      } catch (e) {
        exerciseData = null;
      }

      if (exerciseData != null) {
        _currentExercise = exerciseData;
        exerciseTitleController.text = exerciseData.name;
        _chosenDevice = ExerciseDevice.values[exerciseData.type];
        _minRep = exerciseData.defaultRepBase.toDouble();
        _maxRep = exerciseData.defaultRepMax.toDouble();
        _repRange = RangeValues(_minRep, _maxRep);
        _weightInc = exerciseData.defaultIncrement;

        // Reset all muscle values
        for (var m in muscleGroupNames) {
          globals.muscle_val[m] = 0.0;
        }

        // Set muscle intensities
        final intensities = exerciseData.muscleIntensities;
        for (int i = 0;
            i < muscleGroupNames.length && i < intensities.length;
            i++) {
          globals.muscle_val[muscleGroupNames[i]] = intensities[i];
        }

        notifyListeners();
      }
    } catch (e) {
      _setError('Error loading exercise data: $e');
      if (kDebugMode) print('Error loading exercise data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update exercise device
  void updateDevice(ExerciseDevice device) {
    _chosenDevice = device;
    notifyListeners();
  }

  // Update rep range
  void updateRepRange(RangeValues range) {
    RangeValues newValues = RangeValues(
        range.start, range.start == range.end ? range.end + 1 : range.end);
    _repRange = newValues;
    _minRep = newValues.start;
    _maxRep = newValues.end;
    notifyListeners();
  }

  // Update weight increment
  void updateWeightIncrement(double increment) {
    _weightInc = increment;
    notifyListeners();
  }

  // Save exercise
  Future<bool> saveExercise() async {
    if (exerciseTitleController.text.isEmpty) {
      _setError('Exercise name cannot be empty');
      return false;
    }

    _setLoading(true);
    try {
      bool added_finished = false;
      if (kDebugMode) print('🔧 Starting exercise save process...');

      added_finished = await _addExercise(
        exerciseTitleController.text,
        _chosenDevice,
        _minRep.toInt(),
        _maxRep.toInt(),
        _weightInc,
      );

      if (kDebugMode) print('🔧 Calling get_exercise_list...');
      await _getExerciseList();

      //if (kDebugMode) print('🔧 Notifying data service...');
      _container.notifyDataChanged();

      // // Wait for cache invalidation to complete by forcing a fresh fetch
      // if (kDebugMode) print('🔧 Ensuring cache is refreshed...');
      // await exerciseService.getExercises();

      await Future.delayed(const Duration(milliseconds: 1500));
      //TODO: workaround to wait for cache invalidation, there must be a better solution

      if (kDebugMode) print('✅ All operations completed successfully');
      _clearError();
      return true;
    } catch (e) {
      _setError('Error saving exercise: $e');
      if (kDebugMode) print('❌ Error in save process: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete exercise
  Future<bool> deleteExercise() async {
    if (_currentExercise?.id == null) return false;

    _setLoading(true);
    try {
      final exerciseId = _currentExercise!.id!;
      //TODO: create specific endpoint to delete a bunch of sets by id
      if (kDebugMode) print('Deleting training sets for exercise $exerciseId');
      final trainingSets = await _container.trainingSetService
          .getTrainingSetsByExerciseID(exerciseId: exerciseId);
      for (var set in trainingSets) {
        await _container.trainingSetService.deleteTrainingSet(set['id']);
      }
      final workoutUnits =
          await _container.workoutUnitService.getWorkoutUnits();
      for (var unit in workoutUnits) {
        if (unit['exercise_id'] == exerciseId) {
          await _container.workoutUnitService.deleteWorkoutUnit(unit['id']);
        }
      }
      if (kDebugMode) print('Deleting exercise $exerciseId');
      await exerciseService.deleteExercise(exerciseId);

      _container.notifyDataChanged();
      _clearError();
      return true;
    } catch (e) {
      _setError('Error deleting exercise: $e');
      if (kDebugMode) print('Error deleting exercise: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  Future _addExercise(String exerciseName, ExerciseDevice chosenDevice,
      int minRep, int maxRep, double weightInc) async {
    if (kDebugMode) print('🔧 add_exercise: Starting with name: $exerciseName');

    int exerciseType = chosenDevice.index;
    if (kDebugMode) print('🔧 add_exercise: Exercise type: $exerciseType');

    // Get muscle group intensities
    final muscleIntensities = <double>[];
    for (var m in muscleGroupNames) {
      muscleIntensities.add(globals.muscle_val[m] ?? 0.0);
    }
    if (kDebugMode)
      print(
          '🔧 add_exercise: Muscle intensities collected: ${muscleIntensities.length}');

    // Pad or trim to match expected muscle groups (14 total)
    while (muscleIntensities.length < 14) {
      muscleIntensities.add(0.0);
    }

    if (kDebugMode) print('🔧 add_exercise: Getting existing exercises...');
    // Check if exercise exists
    final exercises = await exerciseService.getExercises();
    ApiExercise? existing;
    try {
      existing = exercises.firstWhere((e) => e.name == exerciseName);
    } catch (e) {
      existing = null;
    }

    if (existing != null && existing.id != null) {
      if (kDebugMode)
        print(
            '🔧 add_exercise: Updating existing exercise with ID: ${existing.id}');
      // Update existing exercise
      await exerciseService.updateExercise(existing.id!, {
        'user_name': _container.authService.userName,
        'name': exerciseName,
        'type': exerciseType,
        'default_rep_base': minRep,
        'default_rep_max': maxRep,
        'default_increment': weightInc,
        'pectoralis_major': muscleIntensities[0],
        'trapezius': muscleIntensities[1],
        'biceps': muscleIntensities[2],
        'abdominals': muscleIntensities[3],
        'front_delts': muscleIntensities[4],
        'deltoids': muscleIntensities[5],
        'back_delts': muscleIntensities[6],
        'latissimus_dorsi': muscleIntensities[7],
        'triceps': muscleIntensities[8],
        'gluteus_maximus': muscleIntensities[9],
        'hamstrings': muscleIntensities[10],
        'quadriceps': muscleIntensities[11],
        'forearms': muscleIntensities[12],
        'calves': muscleIntensities[13],
      });
      if (kDebugMode) print('✅ add_exercise: Exercise updated successfully');
    } else {
      if (kDebugMode) print('🔧 add_exercise: Creating new exercise...');
      // Create new exercise
      await exerciseService.createExercise({
        'name': exerciseName,
        'type': exerciseType,
        'defaultRepBase': minRep,
        'defaultRepMax': maxRep,
        'defaultIncrement': weightInc,
        'pectoralisMajor': muscleIntensities[0],
        'trapezius': muscleIntensities[1],
        'biceps': muscleIntensities[2],
        'abdominals': muscleIntensities[3],
        'frontDelts': muscleIntensities[4],
        'deltoids': muscleIntensities[5],
        'backDelts': muscleIntensities[6],
        'latissimusDorsi': muscleIntensities[7],
        'triceps': muscleIntensities[8],
        'gluteusMaximus': muscleIntensities[9],
        'hamstrings': muscleIntensities[10],
        'quadriceps': muscleIntensities[11],
        'forearms': muscleIntensities[12],
        'calves': muscleIntensities[13],
      });
      if (kDebugMode)
        print('✅ add_exercise: New exercise created successfully');
    }
    return true;
  }

  Future<void> _getExerciseList() async {
    try {
      final exercises = await exerciseService.getExercises();
      List<String> exerciseList = [];
      for (var e in exercises) {
        exerciseList.add(e.name);
      }
      globals.exerciseList = exerciseList;
    } catch (e) {
      if (kDebugMode) print('Error loading exercise list: $e');
      globals.exerciseList = [];
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Utility methods
  String getDeviceName(ExerciseDevice device) {
    switch (device) {
      case ExerciseDevice.free:
        return 'Free Weights';
      case ExerciseDevice.machine:
        return 'Machine';
      case ExerciseDevice.cable:
        return 'Cable';
      case ExerciseDevice.body:
        return 'Bodyweight';
    }
  }

  String getActiveMuscleGroups() {
    final activeMuscles = <String>[];
    for (var entry in globals.muscle_val.entries) {
      if (entry.value > 0) {
        activeMuscles.add('${entry.key} (${(entry.value * 100).round()}%)');
      }
    }
    return activeMuscles.isEmpty ? 'None selected' : activeMuscles.join(', ');
  }

  @override
  void dispose() {
    exerciseTitleController.dispose();
    super.dispose();
  }
}
