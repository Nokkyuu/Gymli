/// Activity Screen - Refactored Cardio and Activity Tracking Interface
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'activity/controllers/activity_controller.dart';
import 'activity/controllers/activity_form_controller.dart';
import 'activity/widgets/activity_log_tab.dart';
import 'activity/widgets/activity_history_tab.dart';
import 'activity/widgets/activity_manage_tab.dart';
import '../utils/themes/responsive_helper.dart';
import '../utils/info_dialogues.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  late ActivityController _activityController;
  late ActivityFormController _formController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _activityController = ActivityController();
    _formController = ActivityFormController();

    // TabController will be initialized in didChangeDependencies
    // Load initial data
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize TabController here where MediaQuery is available
    if (_tabController == null) {
      _tabController = TabController(length: _getTabCount(), vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _activityController.dispose();
    _formController.dispose();
    super.dispose();
  }

  int _getTabCount() {
    return ResponsiveHelper.isMobile(context)
        ? 3
        : 2; // Log, History (mobile only), Manage
  }

  Future<void> _loadInitialData() async {
    try {
      await _activityController.loadData();

      // Set default selected activity if available
      if (_activityController.activities.isNotEmpty &&
          _formController.selectedActivityName == null) {
        _formController
            .setSelectedActivity(_activityController.activities.first.name);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load activity data: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure TabController is initialized
    if (_tabController == null) {
      _tabController = TabController(length: _getTabCount(), vsync: this);
    }

    // Rebuild tab controller if screen size changes
    final currentTabCount = _getTabCount();
    if (_tabController!.length != currentTabCount) {
      _tabController?.dispose();
      _tabController = TabController(length: currentTabCount, vsync: this);
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _activityController),
        ChangeNotifierProvider.value(value: _formController),
      ],
      child: Consumer<ActivityController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Activity Tracker'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showInfoDialogActivitySetup(context),
                ),
              ],
              bottom: TabBar(
                controller: _tabController!,
                tabs: _buildTabs(),
              ),
            ),
            body: TabBarView(
              controller: _tabController!,
              children: _buildTabViews(),
            ),
          );
        },
      ),
    );
  }

  List<Tab> _buildTabs() {
    final List<Tab> tabs = [
      const Tab(icon: Icon(FontAwesomeIcons.plus), text: 'Log'),
      if (ResponsiveHelper.isMobile(context))
        const Tab(icon: Icon(FontAwesomeIcons.list), text: 'History'),
      const Tab(icon: Icon(FontAwesomeIcons.gear), text: 'Manage'),
    ];
    return tabs;
  }

  List<Widget> _buildTabViews() {
    final List<Widget> tabViews = [
      const ActivityLogTab(),
      if (ResponsiveHelper.isMobile(context)) const ActivityHistoryTab(),
      const ActivityManageTab(),
    ];
    return tabViews;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
