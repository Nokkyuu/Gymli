/// Statistics Screen - Workout Analytics and Progress Visualization
///
/// This screen provides comprehensive workout analytics and progress tracking
/// through various charts, graphs, and statistical visualizations using fl_chart.
///
/// Key features:
/// - Muscle group activation bar charts and heatmaps
/// - Training volume analysis over time
/// - One Rep Max (1RM) progression tracking
/// - Exercise-specific performance metrics
/// - Weekly/monthly workout frequency analysis
/// - Visual progress indicators and trend analysis
/// - Customizable date ranges for data analysis
/// - Interactive charts with detailed data points
/// - Muscle group balance assessment
/// - Training load distribution visualization
///
/// The screen helps users understand their training patterns, identify
/// imbalances, track progress, and make data-driven decisions about their
/// fitness routines through comprehensive visual analytics.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/themes/responsive_helper.dart';
import '../utils/info_dialogues.dart';
import 'statistics/statistics_exports.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late StatisticsMainController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StatisticsMainController();

    // Initialize the controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initialize();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Add this method to be called when navigating back to the screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Refresh data when navigating back from other screens
    if (mounted) {
      _controller.loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<StatisticsMainController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(Icons.arrow_back_ios),
              ),
              title: const Text("Statistics"),
              actions: [
                buildInfoButton(
                  'Statistics Info',
                  context,
                  () => showInfoDialogStatistics(context),
                ),
              ],
            ),
            body: _buildBody(controller),
          );
        },
      ),
    );
  }

  Widget _buildBody(StatisticsMainController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.errorMessage != null) {
      return StatisticsErrorWidget(
        message: controller.errorMessage!,
        onRetry: () => controller.initialize(),
      );
    }

    return ResponsiveHelper.isMobile(context)
        ? const StatisticsMobileLayout()
        : const StatisticsDesktopLayout();
  }
}
