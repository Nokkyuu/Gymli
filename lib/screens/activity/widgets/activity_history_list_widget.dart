/// Activity History List Widget - Displays list of activity logs
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../utils/models/data_models.dart';

class ActivityHistoryListWidget extends StatelessWidget {
  final List<ActivityLog> activityLogs;
  final Function(ActivityLog) onDelete;

  const ActivityHistoryListWidget({
    super.key,
    required this.activityLogs,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (activityLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.clipboard, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No activity logs yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Start logging your activities in the Log tab',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activityLogs.length,
      itemBuilder: (context, index) {
        final log = activityLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getActivityColor(log.activityName),
              child: Icon(
                _getActivityIcon(log.activityName),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(log.activityName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMM dd, yyyy').format(log.date)),
                Text(
                    '${log.durationMinutes} min • ${log.caloriesBurned.toStringAsFixed(1)} kcal'),
                if (log.notes != null && log.notes!.isNotEmpty)
                  Text(
                    log.notes!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, log),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, ActivityLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity Log'),
        content: Text(
            'Are you sure you want to delete this ${log.activityName} activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(log);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String activityName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[activityName.hashCode % colors.length];
  }

  IconData _getActivityIcon(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('walk')) return FontAwesomeIcons.personWalking;
    if (name.contains('run')) return FontAwesomeIcons.personRunning;
    if (name.contains('cycling') || name.contains('bike'))
      return FontAwesomeIcons.bicycle;
    if (name.contains('swim')) return FontAwesomeIcons.personSwimming;
    if (name.contains('row')) return Icons.rowing;
    if (name.contains('yoga')) return FontAwesomeIcons.om;
    if (name.contains('basketball')) return Icons.sports_basketball;
    if (name.contains('soccer')) return FontAwesomeIcons.futbol;
    if (name.contains('tennis')) return FontAwesomeIcons.baseballBatBall;
    if (name.contains('hik')) return FontAwesomeIcons.mountain;
    if (name.contains('stair')) return FontAwesomeIcons.stairs;

    return Icons.sports;
  }
}
