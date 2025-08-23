import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:Gymli/utils/services/authentication_service.dart';
import 'package:Gymli/utils/services/service_export.dart';
import 'package:Gymli/utils/models/data_models.dart';
import 'package:Gymli/utils/sync/sync_outbox.dart';

/// WorkoutDataCache: local source of truth for exercises & workouts
/// – keeps local state and notifies listeners
/// – delegates background syncing to a generic SyncOutbox
class WorkoutDataCache extends ChangeNotifier {
  WorkoutDataCache() : _outbox = SyncOutbox(perform: performWorkoutOp) {
    // Hook: allow outbox to reconcile IDs without importing this class (avoid cycles)
    trainingSetReconcileHook = (int exerciseId, int clientId, int serverId) {
      reconcileTrainingSetId(exerciseId, clientId, serverId);
    };
  }
  final int _trainingBufferCapacity = 3;
  int _nextTempTrainingSetId = -1; // negative IDs for optimistic local sets
  /// Create a training set optimistically (local-first, negative id).
  bool _initialized = false;
  bool get isInitialized => _initialized;

  final SyncOutbox _outbox;

  // Local state
  List<Exercise> _exercises = [];
  List<Workout> _workouts = [];
  final LinkedHashMap<int, List<TrainingSet>> _trainingSetBuffers =
      LinkedHashMap<int, List<TrainingSet>>();

  // List<TrainingSet>? getCachedTrainingSets(int exerciseId) =>
  //     _trainingSetBuffers[exerciseId];

  List<TrainingSet> getCachedTrainingSetsSync(int exerciseId) {
    return _trainingSetBuffers[exerciseId] ?? const <TrainingSet>[];
  }

  Future<List<TrainingSet>> getCachedTrainingSets(int exerciseId) async {
    final cached = _trainingSetBuffers[exerciseId];
    if (cached != null) return cached;
    final set = await GetIt.I<TrainingSetService>().getTrainingSetsByExerciseID(exerciseId: exerciseId);
    markActiveExercise(exerciseId);
    setExerciseTrainingSets(exerciseId, set);
    return set;
  }


  /// Should be called when a screen for a given exercise becomes visible/active.
  /// Ensures the exercise is present and becomes MRU in the LRU buffer.
  void markActiveExercise(int exerciseId) {
    if (_trainingSetBuffers.containsKey(exerciseId)) {
      final v = _trainingSetBuffers.remove(exerciseId)!; // remove to reinsert as MRU
      _trainingSetBuffers[exerciseId] = v;
    } else {
      _trainingSetBuffers[exerciseId] = <TrainingSet>[];
      _evictOldestExerciseIfNeeded();
    }
    if (kDebugMode) {
      print('[WorkoutDataCache] markActiveExercise($exerciseId) — buffer keys: ${_trainingSetBuffers.keys.toList()}');
    }
  }

  /// Replace the cached list for an exercise and promote to MRU.
  void setExerciseTrainingSets(int exerciseId, List<TrainingSet> sets) {
    // Promote to MRU by remove+insert
    _trainingSetBuffers.remove(exerciseId);
    final sorted = List<TrainingSet>.of(sets)
      ..sort((a, b) => a.date.compareTo(b.date));
    _trainingSetBuffers[exerciseId] = sorted;
    // _evictOldestExerciseIfNeeded();
    notifyListeners();
    if (kDebugMode) {
      print('[WorkoutDataCache] setExerciseTrainingSets($exerciseId) - cached ${sorted.length} sets');
    }
  }

  /// Insert/update a single set in the buffer (by set.id if present) and promote to MRU.
  void updateTrainingSet(TrainingSet set) {
    final int exerciseId = set.exerciseId;
    final list =
        _trainingSetBuffers.putIfAbsent(exerciseId, () => <TrainingSet>[]);
    final idx = list
        .indexWhere((s) => s.id != null && set.id != null && s.id == set.id);
    if (idx >= 0) {
      list[idx] = set;
    } else {
      list.add(set);
    }
    list.sort((a, b) => a.date.compareTo(b.date));

    // Bump recency by reinsert
    final copy = List<TrainingSet>.from(list);
    _trainingSetBuffers.remove(exerciseId);
    _trainingSetBuffers[exerciseId] = copy;

    _evictOldestExerciseIfNeeded();
    notifyListeners();

    if (kDebugMode) {
      print(
          '[WorkoutDataCache] upsertTrainingSet(e:$exerciseId, setId:${set.id}) — count now ${copy.length}');
    }
  }

  /// Remove a set from the buffer for a given exerciseId. Returns true if removed.
  bool removeTrainingSet(int exerciseId, int setId) {
    final list = _trainingSetBuffers[exerciseId];
    if (list == null) return false;
    final int beforeLen = list.length;
    list.removeWhere((s) => s.id == setId);
    final bool removed = beforeLen != list.length;
    if (removed) {
      final copy = List<TrainingSet>.from(list)
        ..sort((a, b) => a.date.compareTo(b.date));
      _trainingSetBuffers.remove(exerciseId);
      _trainingSetBuffers[exerciseId] = copy;
      notifyListeners();
      if (kDebugMode) {
        print(
            '[WorkoutDataCache] removeTrainingSet(e:$exerciseId, setId:$setId) — remaining ${copy.length}');
      }
      return true;
    }
    return false;
  }

  /// Clears the buffer for a specific exercise, if needed (optional helper).
  void clearTrainingSetCacheForExercise(int exerciseId) {
    if (_trainingSetBuffers.remove(exerciseId) != null) {
      notifyListeners();
      if (kDebugMode) {
        print('[WorkoutDataCache] clearTrainingSetCacheForExercise($exerciseId)');
      }
    }
  }

  void _evictOldestExerciseIfNeeded() {
    while (_trainingSetBuffers.length > _trainingBufferCapacity) {
      final oldestKey = _trainingSetBuffers.keys.first; // LRU by insertion order
      _trainingSetBuffers.remove(oldestKey);
      if (kDebugMode) {
        print('[WorkoutDataCache] evicted exerciseId $oldestKey from training buffer');
      }
    }
  }

  // Read-only views
  List<Exercise> get exercises => List.unmodifiable(_exercises);
  List<Workout> get workouts => List.unmodifiable(_workouts);

  Future<void> init() async {
    if (_initialized) return;
    if (!GetIt.I<AuthenticationService>().isLoggedIn) return;

    _exercises = await GetIt.I<ExerciseService>().getExercises();
    _workouts = await GetIt.I<WorkoutService>().getWorkouts();

    _initialized = true;
    if (kDebugMode) {
      print(
          'WorkoutDataCache initialized with ${_exercises.length} exercises and ${_workouts.length} workouts');
    }
    notifyListeners();
  }


  TrainingSet createTrainingSetOptimistic({
    required String userName,
    required int exerciseId,
    required String exerciseName,
    required DateTime date,
    required double weight,
    required int repetitions,
    required int setType,
    String? phase,
    bool? myoreps,
  }) {
    final int tempId = _nextTempTrainingSetId--;
    final TrainingSet set = TrainingSet(
      id: tempId,
      // userName: userName,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      date: date,
      weight: weight,
      repetitions: repetitions,
      setType: setType,
      phase: phase,
      myoreps: myoreps,
    );
    updateTrainingSet(set);
    if (kDebugMode) {
      print(
          'CACHE: enqueue create_set for exercise=$exerciseId client_id=$tempId');
    }
    _outbox.enqueue(buildCreateTrainingSetOp({
      'client_id': tempId,
      'exercise_id': exerciseId,
      'date': date.toUtc().toIso8601String(),
      'weight': weight,
      'repetitions': repetitions,
      'set_type': setType,
      'phase': phase,
      'myoreps': myoreps,
    }));
    return set;
  }

  /// Delete a training set optimistically; skips server if local-only (negative id).
  void deleteTrainingSetOptimistic({
    required int exerciseId,
    required int setId,
  }) {
    final removed = removeTrainingSet(exerciseId, setId);
    if (!removed) return;
    // If the id is negative, it was never synced; nothing to delete server-side.
    if (setId < 0) return;
    if (kDebugMode) {
      print('CACHE: enqueue delete_set setId=$setId');
    }
    _outbox.enqueue(buildDeleteTrainingSetOp(setId));
  }

  /// Reconcile a previously created optimistic set (clientId) with the server-assigned id.
  bool reconcileTrainingSetId(int exerciseId, int clientId, int serverId) {
    final list = _trainingSetBuffers[exerciseId];
    if (list == null) return false;
    final idx = list.indexWhere((s) => s.id == clientId);
    if (idx < 0) return false;
    final updated = TrainingSet(
      id: serverId,
      //userName: list[idx].userName,
      exerciseId: list[idx].exerciseId,
      exerciseName: list[idx].exerciseName,
      date: list[idx].date,
      weight: list[idx].weight,
      repetitions: list[idx].repetitions,
      setType: list[idx].setType,
      phase: list[idx].phase,
      myoreps: list[idx].myoreps,
    );
    list[idx] = updated;
    list.sort((a, b) => a.date.compareTo(b.date));
    // Bump recency
    final copy = List<TrainingSet>.from(list);
    _trainingSetBuffers.remove(exerciseId);
    _trainingSetBuffers[exerciseId] = copy;
    notifyListeners();
    if (kDebugMode) {
      print(
          '[WorkoutDataCache] reconcileTrainingSetId(e:$exerciseId, clientId:$clientId -> serverId:$serverId)');
    }
    return true;
  }


  // ------------------- Optimistic mutations ------------------- //
  Future<void> addExercise(Exercise exercise) async {
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

  Future<void> addWorkout(Workout workout) async {
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
  void setExercises(List<Exercise> list) {
    _exercises = List.of(list);
    notifyListeners();
  }

  void setWorkouts(List<Workout> list) {
    _workouts = List.of(list);
    notifyListeners();
  }
}
