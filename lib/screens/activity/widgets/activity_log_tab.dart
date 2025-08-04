/// Activity Log Tab - Complete tab for logging activities
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/activity_controller.dart';
import '../controllers/activity_form_controller.dart';
import 'activity_log_form_widget.dart';
import 'activity_history_list_widget.dart';
import '../../../utils/themes/responsive_helper.dart';

class ActivityLogTab extends StatelessWidget {
  const ActivityLogTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Log form takes 2/3 of the width
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Consumer2<ActivityController, ActivityFormController>(
                  builder:
                      (context, activityController, formController, child) {
                    return ActivityLogFormWidget(
                      activities: activityController.activities,
                      selectedActivityName: formController.selectedActivityName,
                      selectedDate: formController.selectedDate,
                      durationController: formController.durationController,
                      onActivityChanged: formController.setSelectedActivity,
                      onDateChanged: formController.setSelectedDate,
                      onSubmit: () => _handleSubmit(
                          context, activityController, formController),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // History panel takes 1/3 of the width (only on non-mobile)
          if (!ResponsiveHelper.isMobile(context))
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Consumer<ActivityController>(
                      builder: (context, controller, child) {
                        return ActivityHistoryListWidget(
                          activityLogs: controller.sortedActivityLogs,
                          onDelete: (log) =>
                              _handleDeleteLog(context, controller, log),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    ActivityController activityController,
    ActivityFormController formController,
  ) async {
    // Validate form
    final validationError = formController.validateActivityLogForm();
    if (validationError != null) {
      if (context.mounted) {
        _showErrorSnackBar(context, validationError);
      }
      return;
    }

    try {
      final formData = formController.getActivityLogData();
      await activityController.logActivity(
        activityName: formData['activityName'],
        date: formData['date'],
        durationMinutes: formData['durationMinutes'],
        notes: formData['notes'],
      );

      // Clear form on success
      formController.clearActivityLogForm();

      // Check if context is still valid before showing success message
      if (context.mounted) {
        _showSuccessSnackBar(context, 'Activity logged successfully!');
      }
    } catch (e) {
      // Check if context is still valid before showing error message
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to log activity');
      }
    }
  }

  Future<void> _handleDeleteLog(
    BuildContext context,
    ActivityController controller,
    dynamic log,
  ) async {
    if (log.id == null) return;

    try {
      await controller.deleteActivityLog(log.id!);
      if (context.mounted) {
        _showSuccessSnackBar(context, 'Activity log deleted');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to delete activity log');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }
}
