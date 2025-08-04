/// Statistics Trainings Per Week Chart Widget
/// Displays a line chart showing training frequency over time
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../controllers/statistics_main_controller.dart';

class StatisticsTrainingsChart extends StatelessWidget {
  const StatisticsTrainingsChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsMainController>(
      builder: (context, controller, child) {
        return LineChart(
          LineChartData(
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                ),
              ),
            ),
            lineBarsData: controller.trainingsPerWeekChart,
            maxY: 7,
            minY: 0,
          ),
        );
      },
    );
  }
}
