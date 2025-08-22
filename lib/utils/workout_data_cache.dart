import 'package:Gymli/utils/services/authentication_service.dart';
import 'package:flutter/foundation.dart';
import 'package:Gymli/utils/api/api_models.dart';
import 'package:get_it/get_it.dart';
import 'package:Gymli/utils/api/api.dart';

class WorkoutDataCache extends ChangeNotifier {
  List<ApiExercise> _exercises = [];
  List<ApiWorkout> _workouts = [];
  bool _initialized = false;
  bool get isInitialized => _initialized;

  // Public getter
  List<ApiExercise> get exercises => List.unmodifiable(_exercises);
  List<ApiWorkout> get workouts => List.unmodifiable(_workouts);

  Future<void> init() async {
    // Load initial data from API
    if (_initialized) return;
    if (!GetIt.I<AuthenticationService>().isLoggedIn) return; // dont initialize if not logged in
    
    _exercises = await GetIt.I<ExerciseService>().getExercises();
    final raw = await GetIt.I<WorkoutService>().getWorkouts();
    _workouts = raw.map((e) => ApiWorkout.fromJson(e)).toList();
    _initialized = true;
    print("WorkoutDataCache initialized with ${_exercises.length} exercises and ${_workouts.length} workouts");
  }


  /// Add + sync
  Future<void> addExercise(ApiExercise exercise) async {
    _exercises.add(exercise);
    notifyListeners();
    await _syncExercises();
  }

  Future<void> removeExerciseById(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    notifyListeners();
    await _syncExercises();
  }

  Future<void> addWorkout(ApiWorkout workout) async {
    _workouts.add(workout);
    notifyListeners();
    await _syncWorkouts();
  }

  Future<void> removeWorkoutById(String id) async {
    _workouts.removeWhere((w) => w.id == id);
    notifyListeners();
    await _syncWorkouts();
  }

  /// Replace all (e.g. after sync from server)
  void setExercises(List<ApiExercise> list) {
    _exercises = List.from(list);
    notifyListeners();
  }

  void setWorkouts(List<ApiWorkout> list) {
    _workouts = List.from(list);
    notifyListeners();
  }

  /// Sync API (dummy)
  Future<void> _syncExercises() async {
    // TODO: implement POST/PUT logic
    print('Synced ${_exercises.length} exercises to server');
  }

  Future<void> _syncWorkouts() async {
    // TODO: implement POST/PUT logic
    print('Synced ${_workouts.length} workouts to server');
  }
}