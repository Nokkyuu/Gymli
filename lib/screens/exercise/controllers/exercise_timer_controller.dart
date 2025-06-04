import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../globals.dart' as globals;

/// Controller for managing timer functionality and idle notifications
class ExerciseTimerController extends ChangeNotifier {
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();
  DateTime _workoutStartTime = DateTime.now();
  String _timerText = "";

  // Getters
  DateTime get lastActivity => _lastActivity;
  DateTime get workoutStartTime => _workoutStartTime;
  String get timerText => _timerText;

  /// Initialize the timer
  void initialize({DateTime? workoutStart, DateTime? lastActivity}) {
    _workoutStartTime = workoutStart ?? DateTime.now();
    _lastActivity = lastActivity ?? DateTime.now();

    _startTimer();
    _updateTimerText();
  }

  /// Update last activity time (call this when user performs an action)
  void updateActivity() {
    _lastActivity = DateTime.now();
    notifyListeners();
  }

  /// Alias for updateActivity for backward compatibility
  void updateLastActivity() {
    updateActivity();
  }

  /// Start the periodic timer
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final duration = DateTime.now().difference(_lastActivity);

      // Trigger idle notification if needed
      if (duration.inSeconds == globals.idleTimerWakeup) {
        _notifyIdle();
      }

      _updateTimerText();
      notifyListeners();
    });
  }

  /// Update the timer text display
  void _updateTimerText() {
    final duration = DateTime.now().difference(_lastActivity);
    final durationString = duration.toString().split(".")[0];
    _timerText = "Idle: $durationString";
  }

  /// Send haptic feedback for idle notification
  void _notifyIdle() {
    int numberOfNotifies = 3;
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      HapticFeedback.vibrate();
      if (--numberOfNotifies == 0) {
        timer.cancel();
      }
    });
  }

  /// Dispose the timer
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
