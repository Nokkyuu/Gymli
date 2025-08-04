/// Statistics Exercise Progress Widget
/// Displays exercise progress charts and selection dropdown
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../controllers/statistics_main_controller.dart';

class StatisticsExerciseProgress extends StatelessWidget {
  const StatisticsExerciseProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsMainController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Exercise dropdown
            if (controller.availableExercises.isNotEmpty)
              Container(
                width: 300,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: controller.selectedExerciseForGraph,
                  hint: const Text("Select an exercise"),
                  items: controller.availableExercises.map((exercise) {
                    return DropdownMenuItem<String>(
                      value: exercise.name,
                      child: Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.selectExerciseForGraph(newValue);
                    }
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Graph section
            if (controller.selectedExerciseForGraph != null)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: LineChart(
                          LineChartData(
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
                                  reservedSize: 30,
                                  interval: controller
                                              .exerciseGraphMaxHistoryDistance >
                                          30
                                      ? 14
                                      : 7,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    if (controller
                                            .exerciseGraphMostRecentDate ==
                                        null) {
                                      return const Text('');
                                    }
                                    final daysAgo = value.abs().round();
                                    final date = controller
                                        .exerciseGraphMostRecentDate!
                                        .subtract(Duration(days: daysAgo));
                                    return Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        '${date.day}/${date.month}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            clipData: const FlClipData.all(),
                            lineBarsData: controller.exerciseGraphData,
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                showOnTopOfTheChartBoxArea: false,
                                fitInsideVertically: true,
                                tooltipMargin: 0,
                                getTooltipItems: (value) {
                                  return value.map((e) {
                                    final tooltips = controller
                                        .exerciseGraphTooltip[e.x.toInt()];
                                    if (tooltips != null &&
                                        e.barIndex < tooltips.length) {
                                      return LineTooltipItem(
                                        tooltips[e.barIndex],
                                        const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      );
                                    }
                                    return null;
                                  }).toList();
                                },
                              ),
                            ),
                            minY: controller.exerciseGraphMinScore - 5.0,
                            maxY: controller.exerciseGraphMaxScore + 5.0,
                            minX: -controller.exerciseGraphMaxHistoryDistance,
                            maxX: 0,
                          ),
                        ),
                      ),
                    ),
                    // Graph legend
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          const Text(
                            "Best Set Per Day",
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 12,
                            height: 12,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Progress",
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text("Select an exercise to view progress"),
                ),
              ),
          ],
        );
      },
    );
  }
}
