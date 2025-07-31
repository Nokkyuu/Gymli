import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/exercise_graph_controller.dart';
import '../../../utils/themes/responsive_helper.dart';

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
            //_buildGraphLegend(),
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
          ? MediaQuery.of(context).size.height * 0.25
          : MediaQuery.of(context).size.height * 0.50,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Padding(
          padding: const EdgeInsets.only(right: 10.0, top: 10.0, left: 0.0),
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    //interval: graphController.maxHistoryDistance > 30 ? 14 : 7,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return _buildDateTitle(value);
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    maxIncluded: true,
                    minIncluded: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value % 1 == 0) {
                        return Text('${value.toInt()}',
                            style: const TextStyle(fontSize: 10));
                      }
                      return const SizedBox.shrink(); // Hide non-integer labels
                    },
                  ),
                ),
              ),
              clipData: const FlClipData.all(),
              lineBarsData: barData,
              betweenBarsData: [
                if (barData.length > 1)
                  BetweenBarsData(
                    fromIndex: 0, // best line
                    toIndex: 1, // lowest line
                    color: Colors.blue.withOpacity(0.15), // fixed area color
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  //tooltipRoundedRadius: 0.0,
                  showOnTopOfTheChartBoxArea: false,
                  fitInsideVertically: true,
                  tooltipMargin: 0,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      // Only show tooltip for the best line (index 0), not the faint lowest line
                      if (touchedSpot.barIndex == 0) {
                        final x = touchedSpot.x.toInt();
                        final tooltipText =
                            graphController.graphToolTip[x]?.first ?? '';
                        return LineTooltipItem(
                          tooltipText,
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        // Return null for the lowest line (index 1) - no tooltip
                        return null;
                      }
                    }).toList();
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
