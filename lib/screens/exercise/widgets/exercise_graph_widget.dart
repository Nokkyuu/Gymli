import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/exercise_graph_controller.dart';
import '../../../responsive_helper.dart';

/// Widget for displaying exercise progress graph
class ExerciseGraphWidget extends StatelessWidget {
  final ExerciseGraphController graphController;
  final List<String> groupExercises;

  const ExerciseGraphWidget({
    super.key,
    required this.graphController,
    this.groupExercises = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: graphController,
      builder: (context, child) {
        return Column(
          children: [
            _buildGraphSection(context),
            _buildGraphLegend(),
          ],
        );
      },
    );
  }

  Widget _buildGraphSection(BuildContext context) {
    final barData = graphController.generateLineChartBarData(groupExercises);

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: ResponsiveHelper.isWebMobile(context)
          ? MediaQuery.of(context).size.height * 0.20
          : MediaQuery.of(context).size.height * 0.50,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Padding(
          padding: const EdgeInsets.only(right: 10.0, top: 10.0, left: 0.0),
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
                    interval: graphController.maxHistoryDistance > 30 ? 14 : 7,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return _buildDateTitle(value);
                    },
                  ),
                ),
              ),
              clipData: const FlClipData.all(),
              lineBarsData: barData,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  //tooltipRoundedRadius: 0.0,
                  showOnTopOfTheChartBoxArea: false,
                  fitInsideVertically: true,
                  tooltipMargin: 0,
                  getTooltipItems: (value) {
                    return value
                        .map((e) {
                          final tooltip =
                              graphController.graphToolTip[e.x.toInt()];
                          if (tooltip != null && e.barIndex < tooltip.length) {
                            return LineTooltipItem(
                              tooltip[e.barIndex],
                              const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            );
                          }
                          return null;
                        })
                        .where((item) => item != null)
                        .cast<LineTooltipItem>()
                        .toList();
                  },
                ),
              ),
              minY: graphController.minScore - 5.0,
              maxY: graphController.maxScore + 5.0,
              minX: -graphController.maxHistoryDistance,
              maxX: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTitle(double value) {
    final mostRecentDate = graphController.mostRecentTrainingDate;
    if (mostRecentDate == null) return const Text('');

    final daysAgo = value.abs().round();
    final date = mostRecentDate.subtract(Duration(days: daysAgo));

    return Transform.rotate(
      angle: -0.5,
      child: Text(
        '${date.day}/${date.month}',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildGraphLegend() {
    return Row(
      children: [
        const SizedBox(width: 20),
        const Text("Sets", style: TextStyle(fontSize: 8.0)),
        const SizedBox(width: 10),
        ..._buildSetLegendItems(),
        ..._buildGroupExerciseLegendItems(),
      ],
    );
  }

  List<Widget> _buildSetLegendItems() {
    const double boxDim = 8.0;
    final List<Widget> widgets = [];

    for (int i = 0; i < 4; i++) {
      widgets.add(
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: boxDim,
              height: boxDim,
              color: ExerciseGraphController.graphColors[i],
            ),
            Text("  $i", style: const TextStyle(fontSize: 8.0)),
            const SizedBox(width: 10),
          ],
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildGroupExerciseLegendItems() {
    const double boxDim = 8.0;
    final List<Widget> widgets = [];

    for (int i = 0; i < groupExercises.length; ++i) {
      widgets.add(
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: boxDim,
              height: boxDim,
              color: ExerciseGraphController.additionalColors[i],
            ),
            Text("  ${groupExercises[i]}",
                style: const TextStyle(fontSize: 8.0)),
            const SizedBox(width: 10),
          ],
        ),
      );
    }

    return widgets;
  }
}
