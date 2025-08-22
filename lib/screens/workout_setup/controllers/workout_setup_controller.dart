import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../utils/services/temp_service.dart';
import '../../../utils/api/api_models.dart';
import 'package:get_it/get_it.dart';
import '../../../utils/api/api.dart';
import '../../../utils/services/auth_service.dart';

class WorkoutSetupController extends ChangeNotifier {
  final TempService _container = GetIt.I<TempService>();
  final ExerciseService exerciseService = GetIt.I<ExerciseService>();
  // Workout data
  String _workoutName = '';
  ApiWorkout? _currentWorkout;
  List<ApiExercise> _allExercises = [];
  List<ApiWorkoutUnit> _addedExercises = [];

  // Form controller
  final TextEditingController workoutNameController = TextEditingController();

  // Loading state
  bool _isLoading = true;
  String? _errorMessage;

  // Notifier for exercise list updates
  final ValueNotifier<bool> _exerciseListNotifier = ValueNotifier<bool>(true);

  // Getters
  String get workoutName => _workoutName;
  ApiWorkout? get currentWorkout => _currentWorkout;
  List<ApiExercise> get allExercises => _allExercises;
  List<ApiWorkoutUnit> get addedExercises => _addedExercises;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ValueNotifier<bool> get exerciseListNotifier => _exerciseListNotifier;

  // Initialize with workout name
  void initialize(String workoutName) {
    _workoutName = workoutName;
    workoutNameController.text = workoutName;
    _loadData();
  }

  // Load workout and exercise data
  Future<void> _loadData() async {
    _setLoading(true);
    try {
      // Load all exercises
      final exerciseData = await exerciseService.getExercises();
      _allExercises = exerciseData..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (_workoutName.isNotEmpty) {
        final workoutData = await _container.getWorkouts();
        final workouts =
            workoutData.map((item) => ApiWorkout.fromJson(item)).toList();

        _currentWorkout = workouts.firstWhere(
          (workout) => workout.name == _workoutName,
          orElse: () => ApiWorkout(
              id: 0, userName: "DefaultUser", name: _workoutName, units: []),
        );

        if (_currentWorkout != null) {
          _addedExercises = List.from(_currentWorkout!.units);
          _exerciseListNotifier.value = !_exerciseListNotifier.value;
        }
      } else {
        workoutNameController.text = "";
      }

      _clearError();
    } catch (e) {
      _setError('Error loading data: $e');
      if (kDebugMode) print('Error loading data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add exercise to workout
  void addExercise(ApiExercise exercise, int warmups, int worksets) {
    // Check if exercise already exists
    for (int i = 0; i < _addedExercises.length; ++i) {
      if (_addedExercises[i].exerciseName == exercise.name) {
        return;
      }
    }

    _addedExercises.add(ApiWorkoutUnit(
        id: 0,
        userName: "DefaultUser",
        workoutId: 0,
        exerciseId: exercise.id ?? 0,
        exerciseName: exercise.name,
        warmups: warmups,
        worksets: worksets,
        type: exercise.type));

    _exerciseListNotifier.value = !_exerciseListNotifier.value;
    notifyListeners();
  }

  // Remove exercise from workout
  void removeExercise(ApiWorkoutUnit exercise) {
    _addedExercises.remove(exercise);
    _exerciseListNotifier.value = !_exerciseListNotifier.value;
    notifyListeners();
  }

  // Save workout
  Future<bool> saveWorkout() async {
    if (workoutNameController.text.isEmpty) {
      _setError('Workout name cannot be empty');
      return false;
    }

    _setLoading(true);
    try {
      if (_currentWorkout != null &&
          _currentWorkout!.id != null &&
          _currentWorkout!.id! > 0) {
        // Delete existing workout (this should also delete associated workout units)
        await GetIt.I<WorkoutService>().deleteWorkout(_currentWorkout!.id!);

        // Create new workout with the updated data
        await _container.createWorkout(
          name: workoutNameController.text,
          units: _addedExercises.map((unit) => unit.toJson()).toList(),
        );

        // Reset currentWorkout since we've created a new one
        _currentWorkout = null;
      } else {
        // Create new workout
        await _container.createWorkout(
          name: workoutNameController.text,
          units: _addedExercises.map((unit) => unit.toJson()).toList(),
        );
      }

      // Notify that data has changed
      GetIt.I<AuthService>().notifyAuthStateChanged();
      _clearError();
      return true;
    } catch (e) {
      _setError('Error saving workout: $e');
      if (kDebugMode) print('Error saving workout: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete workout
  Future<bool> deleteWorkout() async {
    if (_currentWorkout?.id == null) return false;

    _setLoading(true);
    try {
      await GetIt.I<WorkoutService>().deleteWorkout(_currentWorkout!.id!);
      _clearError();
      return true;
    } catch (e) {
      _setError('Error deleting workout: $e');
      if (kDebugMode) print('Error deleting workout: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
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

  @override
  void dispose() {
    workoutNameController.dispose();
    _exerciseListNotifier.dispose();
    super.dispose();
  }
}
