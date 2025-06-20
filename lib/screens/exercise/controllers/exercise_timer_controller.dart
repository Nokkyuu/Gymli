import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import '../../../globals.dart' as globals;
import 'package:web/web.dart' as html;

/// Controller for managing timer functionality and idle notifications
class ExerciseTimerController extends ChangeNotifier {
  Timer? _timer;
  DateTime _lastActivity = DateTime
      .now(); // TODO: change to a function getting the true last activity for the day?
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

  /// Send browser notification for idle notification (Web only)
  void _notifyIdle() {
    // Check if Notification API is available
    if (html.Notification.permission == 'granted') {
      try {
        final notification = html.Notification(
          'Idle Alert',
          html.NotificationOptions(
            body: 'You have been idle for 90 seconds!',
            icon: '/favicon.ico', // Optional: add an icon
            tag: 'idle-alert', // Prevents duplicate notifications
            requireInteraction:
                true, // Keeps notification visible until user interacts
          ),
        );

        // Add event handlers to debug
        notification.onclick = (html.Event event) {
          notification.close();
        }.toJS;
      } catch (e) {
        print('Error creating notification: $e');
      }
    } else if (html.Notification.permission == 'default') {
      html.Notification.requestPermission().toDart.then((permission) {
        print('Permission granted: $permission');
        if (permission == 'granted') {
          _notifyIdle(); // Recursively call to create notification
        }
      });
    } else {
      print('Notification permission denied or unsupported');
    }
  }

  /// Dispose the timer
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
