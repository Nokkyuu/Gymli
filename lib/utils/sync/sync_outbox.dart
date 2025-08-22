import 'package:get_it/get_it.dart';
import 'package:Gymli/utils/api/api_export.dart';
import 'package:Gymli/utils/models/data_models.dart';
import 'package:Gymli/utils/sync/sync_outbox.dart';

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'dart:convert' show jsonEncode;

typedef TrainingSetReconcileHook = void Function(
    int exerciseId, int clientId, int serverId);
TrainingSetReconcileHook? trainingSetReconcileHook;

int _toInt(Object? o) =>
    int.tryParse(o.toString()) ??
    (throw Exception('Invalid int: $o')); // safe int parse

class _Svc {
  // bundle DI services to pass to handlers
  _Svc(this.ex, this.wo, this.ts);
  final ExerciseService ex; // exercises API
  final WorkoutService wo; // workouts API
  final TrainingSetService ts; // training sets API
}

/// Generic operation type for the outbox.
class SyncOp {
  SyncOp(this.type, this.payload);

  final String type;
  final Object? payload;

  int attempts = 0;
  DateTime? nextAt;
}

/// Reusable background outbox with retry & exponential backoff.
/// Provide a [perform] callback that executes a [SyncOp].
class SyncOutbox {
  SyncOutbox({
    required Future<void> Function(SyncOp op) perform,
    int maxRetries = 5,
    Duration baseDelay = const Duration(seconds: 1),
  })  : _perform = perform,
        _maxRetries = maxRetries,
        _baseDelay = baseDelay;

  final Future<void> Function(SyncOp op) _perform;
  final int _maxRetries;
  final Duration _baseDelay;

  final Queue<SyncOp> _queue = Queue<SyncOp>();
  bool _draining = false;

  void enqueue(SyncOp op) {
    _queue.add(op);
    if (kDebugMode) {
      print('OUTBOX: enqueued ${op.type} (attempts=${op.attempts})');
    }
    _ensureDraining();
  }

  void _ensureDraining() {
    if (_draining) return;
    _draining = true;
    unawaited(_drainLoop());
  }

  Future<void> _drainLoop() async {
    while (_queue.isNotEmpty) {
      final op = _queue.first;
      final now = DateTime.now();
      if (op.nextAt != null && now.isBefore(op.nextAt!)) {
        await Future.delayed(op.nextAt!.difference(now));
      }

      try {
        await _perform(op);
        if (kDebugMode) print('OUTBOX: success ${op.type}');
        _queue.removeFirst();
      } catch (e) {
        op.attempts += 1;
        if (op.attempts > _maxRetries) {
          if (kDebugMode) {
            print(
                'OUTBOX: drop ${op.type} after $_maxRetries attempts. Error: $e');
          }
          _queue.removeFirst();
        } else {
          final backoff = _baseDelay * (1 << (op.attempts - 1));
          op.nextAt = DateTime.now().add(backoff);
          if (kDebugMode) {
            print(
                'OUTBOX: retry ${op.type} in ${backoff.inSeconds}s (attempt ${op.attempts})');
          }
          _queue.removeFirst();
          _queue.add(op);
        }
      }
    }
    _draining = false;
  }
}

/// Domain-specific operation types for workout/exercise syncing.
class WorkoutOpType {
  static const String createExercise = 'workout.create_exercise';
  static const String deleteExercise = 'workout.delete_exercise';
  static const String createWorkout = 'workout.create_workout';
  static const String deleteWorkout = 'workout.delete_workout';
  static const String createTrainingSet = 'training.create_set';
  static const String deleteTrainingSet = 'training.delete_set';
}

// ----------- Builders (cache uses these to enqueue ops) ----------- //
SyncOp buildCreateExerciseOp(ApiExercise e) {
  final Map<String, dynamic> map = (e as dynamic).toJson?.call() ??
      {
        'name': e.name,
        'default_rep_base': e.defaultRepBase,
        'default_rep_max': e.defaultRepMax,
        'default_increment': e.defaultIncrement,
      };
  return SyncOp(WorkoutOpType.createExercise, map);
}

SyncOp buildDeleteExerciseOp(String id) =>
    SyncOp(WorkoutOpType.deleteExercise, id);

SyncOp buildCreateWorkoutOp(ApiWorkout w) {
  final Map<String, dynamic> map = (w as dynamic).toJson?.call() ??
      {
        'name': w.name,
      };
  return SyncOp(WorkoutOpType.createWorkout, map);
}

SyncOp buildDeleteWorkoutOp(String id) =>
    SyncOp(WorkoutOpType.deleteWorkout, id);

SyncOp buildCreateTrainingSetOp(Map<String, dynamic> map) {
  // map should contain: exercise_id, date (ISO string), weight, repetitions, set_type, optional: phase, myoreps
  return SyncOp(WorkoutOpType.createTrainingSet, map);
}

SyncOp buildDeleteTrainingSetOp(int id) =>
    SyncOp(WorkoutOpType.deleteTrainingSet, id);

// ----------- Performer (wired into SyncOutbox) ----------- //
Future<void> performWorkoutOp(SyncOp op) async {
  final svc = _Svc(
    // resolve per-op to avoid stale singletons
    GetIt.I<ExerciseService>(),
    GetIt.I<WorkoutService>(),
    GetIt.I<TrainingSetService>(),
  );

  // Handler registry keeps perform logic compact and readable
  final Map<String, Future<void> Function(SyncOp)> handlers = {
    WorkoutOpType.createExercise: (o) async {
      await svc.ex
          .createExercise(o.payload as Map<String, dynamic>); // create exercise
    },
    WorkoutOpType.deleteExercise: (o) async {
      await svc.ex.deleteExercise(_toInt(o.payload)); // delete exercise by id
    },
    WorkoutOpType.createWorkout: (o) async {
      final m = o.payload as Map<String, dynamic>; // payload map
      final name = (m['name'] ?? m['workout_name'] ?? m['title'] ?? '')
          .toString(); // support legacy keys

      if (name.isEmpty)
        throw Exception('Workout create requires a name'); // guard
      //TODO WORKOUT UNITS ÜBERGEBEN
      await svc.wo.createWorkout(name: name, units: []); // create workout
    },
    WorkoutOpType.deleteWorkout: (o) async {
      await svc.wo.deleteWorkout(_toInt(o.payload)); // delete workout by id
    },
    WorkoutOpType.createTrainingSet: (o) async {
      final p = o.payload as Map<String, dynamic>; // typed payload
      if (kDebugMode)
        print(
            'OUTBOX DEBUG: sending create_set payload=${jsonEncode(p)}'); // trace
      final res = await svc.ts.createTrainingSet(
        // server call
        exerciseId: p['exercise_id'] as int,
        date: p['date'] as String,
        weight: (p['weight'] as num).toDouble(),
        repetitions: p['repetitions'] as int,
        setType: p['set_type'] as int,
        phase: p['phase'] as String?,
        myoreps: p['myoreps'] as bool?,
      );
      if (kDebugMode)
        print('OUTBOX DEBUG: response=${res.runtimeType} $res'); // trace
      final clientId = (p['client_id'] as num?)?.toInt(); // temp id from client
      final exerciseId = p['exercise_id'] as int; // exercise id
      final serverId = (res is Map && res['id'] != null)
          ? (res['id'] as num).toInt()
          : null; // server id
      if (clientId != null && serverId != null) {
        final hook = trainingSetReconcileHook; // injected reconcile
        if (hook != null) {
          hook(exerciseId, clientId, serverId); // update cache ids
          if (kDebugMode) {
            print(
                'OUTBOX DEBUG: reconciled clientId=$clientId -> serverId=$serverId for exerciseId=$exerciseId');
          }
        } else if (kDebugMode) {
          print(
              'OUTBOX: missing trainingSetReconcileHook; cannot reconcile clientId=$clientId'); // warn
        }
      } else if (kDebugMode) {
        print(
            'OUTBOX WARN: unexpected response for create_set (clientId=$clientId, serverId=$serverId)'); // warn
      }
    },
    WorkoutOpType.deleteTrainingSet: (o) async {
      final id = _toInt(o.payload); // training set id
      if (kDebugMode) print('OUTBOX DEBUG: sending delete_set id=$id'); // trace
      await svc.ts.deleteTrainingSet(id); // server delete
      if (kDebugMode) print('OUTBOX DEBUG: delete_set OK id=$id'); // trace
    },
  };

  final handler = handlers[op.type]; // lookup
  if (handler == null) {
    throw UnimplementedError('Unknown op ${op.type}'); // explicit failure
  }

  try {
    await handler(op); // run handler
  } catch (e, st) {
    if (kDebugMode) {
      print('OUTBOX ERROR ${op.type}: $e'); // error trace
      print(st);
    }
    rethrow; // let the outbox handle retries/backoff
  }
}
