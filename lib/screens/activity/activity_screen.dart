/// Activity Screen - Cardio and Activity Tracking Interface
///
/// This screen provides comprehensive activity tracking and management for
/// cardio exercises and other physical activities outside of weight training.
///
/// Key features:
/// - Activity type management (walking, running, cycling, swimming, etc.)
/// - Activity session logging with duration and automatic calorie calculation
/// - Activity history display with filtering capabilities
/// - Statistics and progress visualization
/// - Custom activity creation and editing
/// - Activity data export and management
/// - Visual feedback with charts and performance indicators
/// - Integration with user authentication and offline storage
///
/// The screen serves as the main interface for tracking cardio activities
/// and provides insights into overall fitness activity beyond weight training.
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../utils/user/user_service.dart';
import '../../utils/api/api_models.dart';
import '../../utils/themes/responsive_helper.dart';
import '../../utils/info_dialogues.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with TickerProviderStateMixin {
  final UserService userService = UserService();
  late TabController _tabController;

  // Data lists
  List<ApiActivity> activities = [];
  List<ApiActivityLog> activityLogs = [];
  Map<String, dynamic> activityStats = {};

  // Loading states
  bool _isLoading = true;
  bool _isInitialized = false;

  // Selected activity for logging - change to String instead of ApiActivity
  String? selectedActivityName;

  // Form controllers
  final TextEditingController durationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController customActivityNameController =
      TextEditingController();
  final TextEditingController customActivityCaloriesController =
      TextEditingController();

  // Date selection
  DateTime selectedDate = DateTime.now();

  // Chart data
  List<FlSpot> caloriesTrendData = [];
  List<FlSpot> durationTrendData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    durationController.dispose();
    notesController.dispose();
    customActivityNameController.dispose();
    customActivityCaloriesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data - getActivities will handle initialization if needed
      final activitiesData = await userService.getActivities();
      final logsData = await userService.getActivityLogs();
      final statsData = await userService.getActivityStats();

      setState(() {
        activities =
            activitiesData.map((data) => ApiActivity.fromJson(data)).toList();
        activityLogs =
            logsData.map((data) => ApiActivityLog.fromJson(data)).toList();
        activityStats = statsData;

        // Set default selected activity by name
        if (activities.isNotEmpty && selectedActivityName == null) {
          selectedActivityName = activities.first.name;
        }

        // Verify selected activity still exists
        if (selectedActivityName != null) {
          final activityExists =
              activities.any((a) => a.name == selectedActivityName);
          if (!activityExists && activities.isNotEmpty) {
            selectedActivityName = activities.first.name;
          }
        }

        _updateChartData();
      });
    } catch (e) {
      print('Error loading activity data: $e');
      _showErrorSnackBar('Failed to load activity data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateChartData() {
    // Sort logs by date for chart data
    final sortedLogs = List<ApiActivityLog>.from(activityLogs);
    sortedLogs.sort((a, b) => a.date.compareTo(b.date));

    // Create chart data points
    caloriesTrendData.clear();
    durationTrendData.clear();

    for (int i = 0; i < sortedLogs.length; i++) {
      final log = sortedLogs[i];
      final dayIndex = log.date
          .difference(DateTime.now().subtract(const Duration(days: 30)))
          .inDays
          .toDouble();

      if (dayIndex >= 0) {
        caloriesTrendData.add(FlSpot(dayIndex, log.caloriesBurned));
        durationTrendData.add(FlSpot(dayIndex, log.durationMinutes.toDouble()));
      }
    }
  }

  Future<void> _logActivity() async {
    if (selectedActivityName == null || durationController.text.isEmpty) {
      _showErrorSnackBar('Please select an activity and enter duration');
      return;
    }

    final duration = int.tryParse(durationController.text);
    if (duration == null || duration <= 0) {
      _showErrorSnackBar('Please enter a valid duration in minutes');
      return;
    }

    try {
      await userService.createActivityLog(
        activityName: selectedActivityName!,
        date: selectedDate,
        durationMinutes: duration,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
      );

      // Clear form
      durationController.clear();
      notesController.clear();
      selectedDate = DateTime.now();

      // Reload data
      await _loadData();

      _showSuccessSnackBar('Activity logged successfully!');
    } catch (e) {
      print('Error logging activity: $e');
      _showErrorSnackBar('Failed to log activity');
    }
  }

  Future<void> _createCustomActivity() async {
    print('Create custom activity button pressed'); // Debug print

    // Check if fields are empty
    if (customActivityNameController.text.isEmpty ||
        customActivityCaloriesController.text.isEmpty) {
      print('Fields are empty - showing error'); // Debug print
      _showErrorSnackBar('Please enter activity name and calories per hour');
      return;
    }

    print('Activity name: ${customActivityNameController.text}'); // Debug print
    print(
        'Calories text: ${customActivityCaloriesController.text}'); // Debug print

    final calories = double.tryParse(customActivityCaloriesController.text);
    if (calories == null || calories <= 0) {
      print('Invalid calories value: $calories'); // Debug print
      _showErrorSnackBar('Please enter valid calories per hour');
      return;
    }

    print('Parsed calories: $calories'); // Debug print

    try {
      print('Calling userService.createActivity...'); // Debug print
      final result = await userService.createActivity(
        name: customActivityNameController.text,
        kcalPerHour: calories,
      );

      print('Activity created successfully: $result'); // Debug print

      customActivityNameController.clear();
      customActivityCaloriesController.clear();

      print('Reloading data...'); // Debug print
      await _loadData();
      _showSuccessSnackBar('Custom activity created successfully!');
      print('Success message shown'); // Debug print
    } catch (e) {
      print('Error creating custom activity: $e'); // Debug print
      _showErrorSnackBar('Failed to create custom activity: ${e.toString()}');
    }
  }

  Future<void> _deleteActivityLog(ApiActivityLog log) async {
    if (log.id == null) return;

    try {
      await userService.deleteActivityLog(log.id!);
      await _loadData();
      _showSuccessSnackBar('Activity log deleted');
    } catch (e) {
      print('Error deleting activity log: $e');
      _showErrorSnackBar('Failed to delete activity log');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Build tabs dynamically
    final List<Tab> tabs = [
      const Tab(icon: Icon(FontAwesomeIcons.plus), text: 'Log'),
      if (ResponsiveHelper.isMobile(context))
        const Tab(icon: Icon(FontAwesomeIcons.list), text: 'History'),
      //const Tab(icon: Icon(FontAwesomeIcons.chartLine), text: 'Stats'),
      const Tab(icon: Icon(FontAwesomeIcons.gear), text: 'Manage'),
    ];

    // Build tab views dynamically
    final List<Widget> tabViews = [
      _buildLogTab(),
      if (ResponsiveHelper.isMobile(context)) _buildHistoryTab(),
      //_buildStatsTab(),
      _buildManageTab(),
    ];

    // Adjust TabController length if needed
    if (_tabController.length != tabs.length) {
      _tabController.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Tracker'),
        actions: [
          buildInfoButton('Activity Screen Info', context,
              () => showInfoDialogActivitySetup(context)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabViews,
      ),
    );
  }

  Widget _buildLogTab() {
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Log Activity',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Activity selection - Updated dropdown
                        const Text('Activity Type',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedActivityName,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: activities.map((activity) {
                            return DropdownMenuItem<String>(
                              value: activity.name,
                              child: Text(
                                  '${activity.name} (${activity.kcalPerHour.toInt()} kcal/hr)'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedActivityName = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date selection
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                const Text('Date',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        selectedDate = date;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('MMM dd, yyyy')
                                            .format(selectedDate)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              children: [
                                const Text('Duration (minutes)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      //hintText: 'Enter duration in minutes',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Duration input

                        //const SizedBox(height: 8),

                        const SizedBox(height: 16),

                        ElevatedButton.icon(
                          onPressed: _logActivity,
                          icon: const Icon(FontAwesomeIcons.plus),
                          label: const Text('Log Activity'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    child: _buildHistoryTab(),
                  ),
                  const Divider(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _calculateCalories() {
    if (selectedActivityName == null || durationController.text.isEmpty)
      return 0.0;

    final selectedActivity = activities.firstWhere(
      (a) => a.name == selectedActivityName,
      orElse: () => activities.first,
    );

    final duration = int.tryParse(durationController.text) ?? 0;
    return (selectedActivity.kcalPerHour * duration) / 60.0;
  }

  Widget _buildHistoryTab() {
    // Sort logs by date (newest first)
    final sortedLogs = List<ApiActivityLog>.from(activityLogs);
    sortedLogs.sort((a, b) => b.date.compareTo(a.date));

    if (sortedLogs.isEmpty) {
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
      itemCount: sortedLogs.length,
      itemBuilder: (context, index) {
        final log = sortedLogs[index];
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
              onPressed: () => _showDeleteConfirmation(log),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(ApiActivityLog log) {
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
              _deleteActivityLog(log);
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

  Widget _buildManageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Create custom activity card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Custom Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customActivityNameController,
                    decoration: const InputDecoration(
                      labelText: 'Activity Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Rock Climbing',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customActivityCaloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories per Hour',
                      border: OutlineInputBorder(),
                      suffixText: 'kcal/hr',
                      hintText: 'e.g., 400',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('Button onPressed called'); // Debug print
                        _createCustomActivity();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Activity'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Activity list card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Available Activities',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // if (userService.isLoggedIn)
                      //   Text(
                      //     'Logged in users can delete any activity',
                      //     style:
                      //         TextStyle(fontSize: 12, color: Colors.grey[600]),
                      //   )
                      // else
                      //   Text(
                      //     'Guest users can only delete custom activities',
                      //     style:
                      //         TextStyle(fontSize: 12, color: Colors.grey[600]),
                      //   ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (activities.isEmpty)
                    const Center(
                      child: Text(
                        'No activities loaded yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else if (!ResponsiveHelper.isMobile(context))
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.8,
                      children: activities.map((activity) {
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.blue.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle:
                                Text('${activity.kcalPerHour.toInt()} kcal/hr'),
                            trailing: _shouldShowDeleteButton(activity)
                                ? IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _showDeleteActivityConfirmation(
                                            activity),
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    )
                  else
                    ...activities.map((activity) => ListTile(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle:
                              Text('${activity.kcalPerHour.toInt()} kcal/hr'),
                          trailing: _shouldShowDeleteButton(activity)
                              ? IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _showDeleteActivityConfirmation(activity),
                                )
                              : null,
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Determines whether the delete button should be shown for an activity
  /// Logged-in users can delete any activity
  /// Non-authenticated users can only delete custom activities (id > 16)
  bool _shouldShowDeleteButton(ApiActivity activity) {
    if (activity.id == null) return false;

    if (userService.isLoggedIn) {
      // Logged-in users can delete any activity
      return true;
    } else {
      // Non-authenticated users can only delete custom activities
      return activity.id! > 16;
    }
  }

  void _showDeleteActivityConfirmation(ApiActivity activity) {
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
                await userService.deleteActivity(activity.id!);
                await _loadData();
                _showSuccessSnackBar('Activity deleted successfully');
              } catch (e) {
                print('Error deleting activity: $e');
                _showErrorSnackBar(
                    'Failed to delete activity: ${e.toString()}');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
