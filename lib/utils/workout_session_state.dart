/// State Management for Workout-Sessions
/// TTL should be adapted
///

class WorkoutSessionState {
  late DateTime startTime;
  late DateTime lastExerciseTime;
  int numExercises = 4;
  int numWorkouts = 4;  // TODO: this needs endpoints!
  List<String> completedExercises = [];
  final Duration ttl; // Time to Live (z. B. 2 Stunden)

  WorkoutSessionState._({
    required this.startTime,
    required this.ttl,
  });

  factory WorkoutSessionState.startNew({Duration ttl = const Duration(hours: 2)}) {
    final now = DateTime.now();
    return WorkoutSessionState._(startTime: DateTime.now(), ttl: ttl)..lastExerciseTime = now;
  }

  bool get isActive => DateTime.now().difference(startTime) < ttl;
  Duration get timeLeft => ttl - DateTime.now().difference(startTime);

  void addExercise(String name) {
    completedExercises.add(name);
    lastExerciseTime = DateTime.now();
  }
}

class WorkoutSessionManager {
  WorkoutSessionState? _session;

  WorkoutSessionState getSession() {
    if (_session == null || !_session!.isActive) {
      _session = WorkoutSessionState.startNew();
    }
    return _session!;
  }
  WorkoutSessionState? get session => _session;
}