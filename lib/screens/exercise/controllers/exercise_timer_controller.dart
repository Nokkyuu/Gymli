import 'dart:async';
import 'dart:js_interop';
import 'package:Gymli/utils/workout_session_state.dart';
import 'package:flutter/material.dart';
import '../../../utils/globals.dart' as globals;
import 'package:web/web.dart' as html;
import 'package:get_it/get_it.dart';


/// Controller for managing timer functionality and idle notifications
class ExerciseTimerController extends ChangeNotifier {
  Timer? _timer;
  // DateTime _lastActivity = GetIt.I<WorkoutSessionManager>().getSession().lastExerciseTime;
  DateTime _lastActivity = DateTime.now(); // Default to now if no session exists


  DateTime _workoutStartTime = DateTime.now();
  String _timerText = "";

  // Getters
  DateTime get lastActivity => _lastActivity;
  DateTime get workoutStartTime => _workoutStartTime;
  String get timerText => _timerText;

  /// Initialize the timer
  void initialize({DateTime? workoutStart, DateTime? lastActivity}) {
    _workoutStartTime = workoutStart ?? DateTime.now();
    final workoutSession = GetIt.I<WorkoutSessionManager>().getSession();
    _lastActivity = workoutSession.lastExerciseTime;

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
  /// Send browser notification for idle notification (Web only)
  void _notifyIdle() {
    // Debug: Log the current permission status
    print('Notification permission: ${html.Notification.permission}');

    // // Check if Notification API is available
    // if (html.Notification.permission == 'granted') {
    //   print('Creating notification...');
    //   try {
    //     final notification = html.Notification(
    //       'Idle Alert',
    //       html.NotificationOptions(
    //         body: 'You have been idle for 90 seconds!',
    //         //icon: '/favicon.ico', // Optional: add an icon
    //         //tag: 'idle-alert', // Prevents duplicate notifications
    //         tag: 'idle-alert-${DateTime.now().millisecondsSinceEpoch}',
    //         requireInteraction:
    //             true, // Keeps notification visible until user interacts
    //       ),
    //     );

    //     // Add event handlers to debug
    //     notification.onclick = (html.Event event) {
    //       print('Notification clicked');
    //       notification.close();
    //     }.toJS;

    //     notification.onshow = (html.Event event) {
    //       print('Notification shown successfully');
    //     }.toJS;

    //     notification.onerror = (html.Event event) {
    //       print('Notification error occurred');
    //     }.toJS;

    //     print('Notification object created: $notification');
    //   } catch (e) {
    //     print('Error creating notification: $e');
    //   }
    // } else if (html.Notification.permission == 'default') {
    //   print('Requesting permission...');
    //   html.Notification.requestPermission().toDart.then((permission) {
    //     print('Permission granted: $permission');
    //     if (permission == 'granted') {
    //       _notifyIdle(); // Recursively call to create notification
    //     }
    //   });
    // } else {
    //   print('Notification permission denied or unsupported');
    // }
  }

  /// Dispose the timer
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
