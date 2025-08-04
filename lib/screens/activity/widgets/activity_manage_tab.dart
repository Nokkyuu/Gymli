/// Activity Manage Tab - Complete tab for managing activities
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/activity_controller.dart';
import '../controllers/activity_form_controller.dart';
import 'custom_activity_form_widget.dart';
import '../../../utils/api/api_models.dart';
import '../../../utils/themes/responsive_helper.dart';

class ActivityManageTab extends StatelessWidget {
  const ActivityManageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Create custom activity section
          Consumer2<ActivityController, ActivityFormController>(
            builder: (context, activityController, formController, child) {
              return CustomActivityFormWidget(
                nameController: formController.customActivityNameController,
                caloriesController:
                    formController.customActivityCaloriesController,
                onSubmit: () => _handleCreateActivity(
                    context, activityController, formController),
              );
            },
          ),
          const SizedBox(height: 16),

          // Activity list section
          Consumer<ActivityController>(
            builder: (context, controller, child) {
              return _buildActivityListCard(context, controller);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityListCard(
      BuildContext context, ActivityController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (controller.activities.isEmpty)
              const Center(
                child: Text(
                  'No activities loaded yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else if (!ResponsiveHelper.isMobile(context))
              _buildActivityGrid(context, controller)
            else
              _buildActivityList(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityGrid(
      BuildContext context, ActivityController controller) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: controller.activities.map((activity) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getActivityColor(activity.name),
              child: Icon(
                _getActivityIcon(activity.name),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(activity.name)),
                if (activity.id != null && activity.id! <= 16)
                  _buildDefaultBadge(),
              ],
            ),
            subtitle: Text('${activity.kcalPerHour.toInt()} kcal/hr'),
            trailing: controller.shouldShowDeleteButton(activity)
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteActivityConfirmation(
                      context,
                      controller,
                      activity,
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityList(
      BuildContext context, ActivityController controller) {
    return Column(
      children: controller.activities
          .map((activity) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getActivityColor(activity.name),
                  child: Icon(
                    _getActivityIcon(activity.name),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(activity.name)),
                    if (activity.id != null && activity.id! <= 16)
                      _buildDefaultBadge(),
                  ],
                ),
                subtitle: Text('${activity.kcalPerHour.toInt()} kcal/hr'),
                trailing: controller.shouldShowDeleteButton(activity)
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteActivityConfirmation(
                          context,
                          controller,
                          activity,
                        ),
                      )
                    : null,
              ))
          .toList(),
    );
  }

  Widget _buildDefaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        'Default',
        style: TextStyle(
          fontSize: 10,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _handleCreateActivity(
    BuildContext context,
    ActivityController activityController,
    ActivityFormController formController,
  ) async {
    // Validate form
    final validationError = formController.validateCustomActivityForm();
    if (validationError != null) {
      if (context.mounted) {
        _showErrorSnackBar(context, validationError);
      }
      return;
    }

    try {
      final formData = formController.getCustomActivityData();
      await activityController.createCustomActivity(
        name: formData['name'],
        kcalPerHour: formData['kcalPerHour'],
      );

      // Clear form on success
      formController.clearCustomActivityForm();

      if (context.mounted) {
        _showSuccessSnackBar(context, 'Custom activity created successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
            context, 'Failed to create custom activity: ${e.toString()}');
      }
    }
  }

  void _showDeleteActivityConfirmation(
    BuildContext context,
    ActivityController controller,
    ApiActivity activity,
  ) {
    final bool isDefaultActivity = activity.id != null && activity.id! <= 16;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${activity.name}"?'),
            const SizedBox(height: 8),
            if (isDefaultActivity)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a default activity. You can recreate it by logging out and back in.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'This will also delete all associated activity logs.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await controller.deleteActivity(activity.id!);
                if (context.mounted) {
                  _showSuccessSnackBar(
                      context, 'Activity deleted successfully');
                }
              } catch (e) {
                if (kDebugMode) print('Error deleting activity: $e');
                if (context.mounted) {
                  _showErrorSnackBar(
                      context, 'Failed to delete activity: ${e.toString()}');
                }
              }
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
