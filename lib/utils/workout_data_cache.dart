import 'dart:async';

import 'package:Gymli/utils/services/temp_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:Gymli/utils/services/authentication_service.dart';
import 'package:Gymli/utils/api/api.dart';
import 'package:Gymli/utils/api/api_models.dart';
import 'package:Gymli/utils/sync/sync_outbox.dart';

/// WorkoutDataCache: local source of truth for exercises & workouts
/// – keeps local state and notifies listeners
/// – delegates background syncing to a generic SyncOutbox
class WorkoutDataCache extends ChangeNotifier {
  WorkoutDataCache() : _outbox = SyncOutbox(perform: performWorkoutOp);

  // Local state
  List<ApiExercise> _exercises = [];
  List<ApiWorkout> _workouts = [];

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // Read-only views
  List<ApiExercise> get exercises => List.unmodifiable(_exercises);
  List<ApiWorkout> get workouts => List.unmodifiable(_workouts);

  // Background outbox (retry/backoff lives there)
  final SyncOutbox _outbox;

  // ------------------------- Init ------------------------- //
  Future<void> init() async {
    if (_initialized) return;
    if (!GetIt.I<AuthenticationService>().isLoggedIn) return;

    _exercises = await GetIt.I<ExerciseService>().getExercises();
    final raw = await GetIt.I<TempService>().getWorkouts();
    _workouts = raw.map((e) => ApiWorkout.fromJson(e)).toList();

    _initialized = true;
    if (kDebugMode) {
      print(
          'WorkoutDataCache initialized with ${_exercises.length} exercises and ${_workouts.length} workouts');
    }
    notifyListeners();
  }

  // ------------------- Optimistic mutations ------------------- //
  Future<void> addExercise(ApiExercise exercise) async {
    _exercises = List.of(_exercises)..add(exercise);
    notifyListeners();
    _outbox.enqueue(buildCreateExerciseOp(exercise));
  }

  Future<void> removeExerciseById(String id) async {
    _exercises = List.of(_exercises)
      ..removeWhere((e) => e.id.toString() == id.toString());
    notifyListeners();
    _outbox.enqueue(buildDeleteExerciseOp(id));
  }

  Future<void> addWorkout(ApiWorkout workout) async {
    _workouts = List.of(_workouts)..add(workout);
    notifyListeners();
    _outbox.enqueue(buildCreateWorkoutOp(workout));
  }

  Future<void> removeWorkoutById(String id) async {
    _workouts = List.of(_workouts)
      ..removeWhere((w) => w.id.toString() == id.toString());
    notifyListeners();
    _outbox.enqueue(buildDeleteWorkoutOp(id));
  }

  // Replace all (e.g., after a full refresh)
  void setExercises(List<ApiExercise> list) {
    _exercises = List.of(list);
    notifyListeners();
  }

  void setWorkouts(List<ApiWorkout> list) {
    _workouts = List.of(list);
    notifyListeners();
  }
}
