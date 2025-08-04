/// Activity Form Controller - Manages form states and validation
library;

import 'package:flutter/material.dart';

class ActivityFormController extends ChangeNotifier {
  // Form controllers for activity logging
  final TextEditingController durationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Form controllers for custom activity creation
  final TextEditingController customActivityNameController =
      TextEditingController();
  final TextEditingController customActivityCaloriesController =
      TextEditingController();

  // Form state
  String? selectedActivityName;
  DateTime selectedDate = DateTime.now();

  /// Update selected activity
  void setSelectedActivity(String? activityName) {
    selectedActivityName = activityName;
    notifyListeners();
  }

  /// Update selected date
  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  /// Clear activity logging form
  void clearActivityLogForm() {
    durationController.clear();
    notesController.clear();
    selectedDate = DateTime.now();
    notifyListeners();
  }

  /// Clear custom activity form
  void clearCustomActivityForm() {
    customActivityNameController.clear();
    customActivityCaloriesController.clear();
    notifyListeners();
  }

  /// Validate activity log form
  String? validateActivityLogForm() {
    if (selectedActivityName == null) {
      return 'Please select an activity';
    }
    if (durationController.text.isEmpty) {
      return 'Please enter duration';
    }
    final duration = int.tryParse(durationController.text);
    if (duration == null || duration <= 0) {
      return 'Please enter a valid duration in minutes';
    }
    return null; // No errors
  }

  /// Validate custom activity form
  String? validateCustomActivityForm() {
    if (customActivityNameController.text.isEmpty) {
      return 'Please enter activity name';
    }
    if (customActivityCaloriesController.text.isEmpty) {
      return 'Please enter calories per hour';
    }
    final calories = double.tryParse(customActivityCaloriesController.text);
    if (calories == null || calories <= 0) {
      return 'Please enter valid calories per hour';
    }
    return null; // No errors
  }

  /// Get form data for activity logging
  Map<String, dynamic> getActivityLogData() {
    return {
      'activityName': selectedActivityName!,
      'date': selectedDate,
      'durationMinutes': int.parse(durationController.text),
      'notes': notesController.text.isNotEmpty ? notesController.text : null,
    };
  }

  /// Get form data for custom activity creation
  Map<String, dynamic> getCustomActivityData() {
    return {
      'name': customActivityNameController.text,
      'kcalPerHour': double.parse(customActivityCaloriesController.text),
    };
  }

  @override
  void dispose() {
    durationController.dispose();
    notesController.dispose();
    customActivityNameController.dispose();
    customActivityCaloriesController.dispose();
    super.dispose();
  }
}
