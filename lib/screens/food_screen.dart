/// Food Screen - Nutrition Tracking Interface
/// Screen for logging food consumption and managing food items.
///
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../utils/themes/responsive_helper.dart';
import '../utils/info_dialogues.dart';
import 'food/food_setup_exports.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  late FoodDataController _dataController;
  late FoodLoggingController _loggingController;
  late FoodManagementController _managementController;

  @override
  void initState() {
    super.initState();
    _dataController = FoodDataController();
    _loggingController = FoodLoggingController();
    _managementController = FoodManagementController();

    // TabController will be initialized in didChangeDependencies
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dataController.loadData();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _dataController.dispose();
    _loggingController.dispose();
    _managementController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize TabController here where MediaQuery is available
    if (_tabController == null) {
      _tabController = TabController(length: _getTabCount(), vsync: this);
    }

    // Rebuild tab controller if screen size changes
    final currentTabCount = _getTabCount();
    if (_tabController!.length != currentTabCount) {
      _tabController?.dispose();
      _tabController = TabController(length: currentTabCount, vsync: this);
    }
  }

  int _getTabCount() {
    return ResponsiveHelper.isMobile(context)
        ? 3
        : 2; // Log, History (mobile only), Manage
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
      const FoodLogTab(),
      if (ResponsiveHelper.isMobile(context)) const FoodHistoryWidget(),
      const FoodManageTab(),
    ];
    return tabViews;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure TabController is initialized
    if (_tabController == null) {
      _tabController = TabController(length: _getTabCount(), vsync: this);
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _dataController),
        ChangeNotifierProvider.value(value: _loggingController),
        ChangeNotifierProvider.value(value: _managementController),
      ],
      child: Consumer<FoodDataController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Food Tracker'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showInfoDialogFoodSetup(context),
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
}
