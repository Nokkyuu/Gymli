/// Statistics Activities View Widget
/// Displays activities overview with trends and statistics
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../controllers/statistics_main_controller.dart';

class StatisticsActivitiesView extends StatelessWidget {
  const StatisticsActivitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsMainController>(
      builder: (context, controller, child) {
        if (controller.isLoadingActivityData) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Activities Overview",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              // Activity statistics cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActivityStatCard(
                    "Total Sessions",
                    controller.activityStats['total_sessions']?.toString() ??
                        "0",
                  ),
                  _buildActivityStatCard(
                    "Total Calories",
                    controller.getCaloriesDisplayValue(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Trends",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              // Calories trend chart
              const Text("Calories Burned Over Time"),
              const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 20,
                    bottom: 20,
                    top: 10,
                  ),
                  child: _buildCaloriesTrendChart(controller),
                ),
              ),
              const SizedBox(height: 20),
              // Duration trend chart
              const Text("Activity Duration Over Time"),
              const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 20,
                    bottom: 20,
                    top: 10,
                  ),
                  child: _buildDurationTrendChart(controller),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityStatCard(String title, String value) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesTrendChart(StatisticsMainController controller) {
    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: controller.caloriesTrendData.length > 10
                  ? (controller.caloriesTrendData.last.x -
                          controller.caloriesTrendData.first.x) /
                      5
                  : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (controller.caloriesTrendData.isEmpty) {
                  return const Text('');
                }

                final dayIndex = value.round();
                if (dayIndex < 0 ||
                    dayIndex >= controller.caloriesTrendData.length) {
                  return const Text('');
                }

                final DateTime baseDate = DateTime.now().subtract(
                  Duration(
                    days: (controller.caloriesTrendData.last.x - value).round(),
                  ),
                );

                return Transform.rotate(
                  angle: -0.3,
                  child: Text(
                    '${baseDate.day}/${baseDate.month}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: controller.caloriesTrendData.isNotEmpty
                  ? (controller.caloriesTrendData.map((e) => e.y).reduce(max) /
                      4)
                  : 50,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: controller.caloriesTrendData,
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
            dotData: const FlDotData(show: false),
          ),
        ],
        minX: controller.caloriesTrendData.isNotEmpty
            ? controller.caloriesTrendData.first.x
            : 0,
        maxX: controller.caloriesTrendData.isNotEmpty
            ? controller.caloriesTrendData.last.x
            : 0,
        minY: 0,
        maxY: controller.caloriesTrendData.isNotEmpty
            ? (controller.caloriesTrendData.map((e) => e.y).reduce(max) * 1.1)
            : 100,
      ),
    );
  }

  Widget _buildDurationTrendChart(StatisticsMainController controller) {
    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: controller.durationTrendData.length > 10
                  ? (controller.durationTrendData.last.x -
                          controller.durationTrendData.first.x) /
                      5
                  : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (controller.durationTrendData.isEmpty) {
                  return const Text('');
                }

                final dayIndex = value.round();
                if (dayIndex < 0 ||
                    dayIndex >= controller.durationTrendData.length) {
                  return const Text('');
                }

                final DateTime baseDate = DateTime.now().subtract(
                  Duration(
                    days: (controller.durationTrendData.last.x - value).round(),
                  ),
                );

                return Transform.rotate(
                  angle: -0.3,
                  child: Text(
                    '${baseDate.day}/${baseDate.month}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: controller.durationTrendData.isNotEmpty
                  ? (controller.durationTrendData.map((e) => e.y).reduce(max) /
                      4)
                  : 20,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}m',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: controller.durationTrendData,
            isCurved: false,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
            dotData: const FlDotData(show: false),
          ),
        ],
        minX: controller.durationTrendData.isNotEmpty
            ? controller.durationTrendData.first.x
            : 0,
        maxX: controller.durationTrendData.isNotEmpty
            ? controller.durationTrendData.last.x
            : 0,
        minY: 0,
        maxY: controller.durationTrendData.isNotEmpty
            ? (controller.durationTrendData.map((e) => e.y).reduce(max) * 1.1)
            : 100,
      ),
    );
  }
}
