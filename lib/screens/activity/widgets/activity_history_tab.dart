/// Activity History Tab - Complete tab for viewing activity history
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/activity_controller.dart';
import 'activity_history_list_widget.dart';

class ActivityHistoryTab extends StatelessWidget {
  const ActivityHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityController>(
      builder: (context, controller, child) {
        return ActivityHistoryListWidget(
          activityLogs: controller.sortedActivityLogs,
          onDelete: (log) => _handleDeleteLog(context, controller, log),
        );
      },
    );
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
