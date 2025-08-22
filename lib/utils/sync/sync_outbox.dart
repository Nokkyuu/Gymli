import 'package:get_it/get_it.dart';
import 'package:Gymli/utils/api/api.dart';
import 'package:Gymli/utils/api/api_models.dart';

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'dart:convert' show jsonEncode;

typedef TrainingSetReconcileHook = void Function(int exerciseId, int clientId, int serverId);
TrainingSetReconcileHook? trainingSetReconcileHook;
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
            print('OUTBOX: drop ${op.type} after $_maxRetries attempts. Error: $e');
          }
          _queue.removeFirst();
        } else {
          final backoff = _baseDelay * (1 << (op.attempts - 1));
          op.nextAt = DateTime.now().add(backoff);
          if (kDebugMode) {
            print('OUTBOX: retry ${op.type} in ${backoff.inSeconds}s (attempt ${op.attempts})');
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
  static const String createWorkout  = 'workout.create_workout';
  static const String deleteWorkout  = 'workout.delete_workout';
  static const String createTrainingSet = 'training.create_set';
  static const String deleteTrainingSet = 'training.delete_set';
}

// ----------- Builders (cache uses these to enqueue ops) ----------- //
SyncOp buildCreateExerciseOp(ApiExercise e) {
  final Map<String, dynamic> map = (e as dynamic).toJson?.call() ?? {
    'name': e.name,
    'default_rep_base': e.defaultRepBase,
    'default_rep_max': e.defaultRepMax,
    'default_increment': e.defaultIncrement,
  };
  return SyncOp(WorkoutOpType.createExercise, map);
}

SyncOp buildDeleteExerciseOp(String id) => SyncOp(WorkoutOpType.deleteExercise, id);

SyncOp buildCreateWorkoutOp(ApiWorkout w) {
  final Map<String, dynamic> map = (w as dynamic).toJson?.call() ?? {
    'name': w.name,
  };
  return SyncOp(WorkoutOpType.createWorkout, map);
}

SyncOp buildDeleteWorkoutOp(String id) => SyncOp(WorkoutOpType.deleteWorkout, id);

SyncOp buildCreateTrainingSetOp(Map<String, dynamic> map) {
  // map should contain: exercise_id, date (ISO string), weight, repetitions, set_type, optional: phase, myoreps
  return SyncOp(WorkoutOpType.createTrainingSet, map);
}

SyncOp buildDeleteTrainingSetOp(int id) => SyncOp(WorkoutOpType.deleteTrainingSet, id);

// ----------- Performer (wired into SyncOutbox) ----------- //
Future<void> performWorkoutOp(SyncOp op) async {
  final exService = GetIt.I<ExerciseService>();
  final woService = GetIt.I<WorkoutService>();
  final tsService = GetIt.I<TrainingSetService>();

  switch (op.type) {
    case WorkoutOpType.createExercise:
      await exService.createExercise(op.payload as Map<String, dynamic>);
      return;
    case WorkoutOpType.deleteExercise:
      final id = int.tryParse(op.payload.toString());
      if (id == null) throw Exception('Invalid exercise id ${op.payload}');
      await exService.deleteExercise(id);
      return;

    case WorkoutOpType.createWorkout:
      final map = op.payload as Map<String, dynamic>;
      final name = (map['name'] ?? map['workout_name'] ?? map['title'] ?? '').toString();
      if (name.isEmpty) throw Exception('Workout create requires a name');
      await woService.createWorkout(name: name);
      return;
    case WorkoutOpType.deleteWorkout:
      final id2 = int.tryParse(op.payload.toString());
      if (id2 == null) throw Exception('Invalid workout id ${op.payload}');
      await woService.deleteWorkout(id2);
      return;
    case WorkoutOpType.createTrainingSet:
      final payload = op.payload as Map<String, dynamic>;
      try {
        if (kDebugMode) {
          print('OUTBOX DEBUG: sending create_set payload=${jsonEncode(payload)}');
        }
        final res = await tsService.createTrainingSet(
          exerciseId: payload['exercise_id'] as int,
          date: payload['date'] as String,
          weight: (payload['weight'] as num).toDouble(),
          repetitions: payload['repetitions'] as int,
          setType: payload['set_type'] as int,
          phase: payload['phase'] as String?,
          myoreps: payload['myoreps'] as bool?,
        );
        if (kDebugMode) {
          print('OUTBOX DEBUG: response=${res.runtimeType} $res');
        }
        // Reconcile client temp id with server id, if provided
        final clientId = (payload['client_id'] as num?)?.toInt();
        final exerciseId = payload['exercise_id'] as int;
        final serverId = (res is Map && res['id'] != null) ? (res['id'] as num).toInt() : null;
        if (clientId != null && serverId != null) {
          // Delegate to hook to avoid cyclic import between cache and outbox
          final hook = trainingSetReconcileHook;
          if (hook != null) {
            hook(exerciseId, clientId, serverId);
          } else if (kDebugMode) {
            print('OUTBOX: missing trainingSetReconcileHook; cannot reconcile clientId=$clientId');
          }
        } else if (kDebugMode) {
          print('OUTBOX WARN: unexpected response for create_set (clientId=$clientId, serverId=$serverId)');
        }
      } catch (e, st) {
        if (kDebugMode) {
          print('OUTBOX ERROR create_set: $e');
          print(st);
        }
        rethrow;
      }
      return;
    case WorkoutOpType.deleteTrainingSet:
      final id3 = int.tryParse(op.payload.toString());
      if (id3 == null) throw Exception('Invalid training set id ${op.payload}');
      if (kDebugMode) {
        print('OUTBOX DEBUG: sending delete_set id=$id3');
      }
      await tsService.deleteTrainingSet(id3);
      if (kDebugMode) {
        print('OUTBOX DEBUG: delete_set OK id=$id3');
      }
      return;
    default:
      throw UnimplementedError('Unknown op ${op.type}');
  }
}