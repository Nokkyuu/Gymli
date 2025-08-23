/// Statistics Mobile Layout Widget
/// Mobile-specific layout for statistics screen
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/statistics_main_controller.dart';
import '../widgets/statistics_date_picker.dart';
import '../widgets/statistics_trainings_chart.dart';
import '../widgets/statistics_muscle_heatmap.dart';
import '../widgets/statistics_activities_view.dart';
import '../widgets/statistics_overview.dart';

class StatisticsMobileLayout extends StatelessWidget {
  const StatisticsMobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsMainController>(
      builder: (context, controller, child) {
        return ListView(
          children: <Widget>[
            const SizedBox(height: 5),
            const StatisticsDatePicker(),
            const SizedBox(height: 20),
            StatisticTexts(
              numberOfTrainingDays: controller.numberOfTrainingDays,
              trainingDuration: controller.trainingDuration,
              freeWeightsCount: controller.freeWeightsCount,
              machinesCount: controller.machinesCount,
              cablesCount: controller.cablesCount,
              bodyweightCount: controller.bodyweightCount,
              activityStats: controller.activityStats,
              getCaloriesDisplayValue: controller.getCaloriesDisplayValue,
              totalWeightLiftedKg: controller.totalWeightLiftedKg,
            ),
            const Divider(),
            ExpansionTile(
              title: Text(
                "Number of Trainings per Week",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              initiallyExpanded: true,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.15,
                  child: const Padding(
                    padding: EdgeInsets.only(
                      right: 10.0,
                      top: 15.0,
                      left: 0.0,
                    ),
                    child: StatisticsTrainingsChart(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 5),
            const SizedBox(height: 20),
            ExpansionTile(
              title: Text(
                "Heatmap: relative to most used muscle",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              initiallyExpanded: false,
              children: [
                StatisticsMuscleHeatmap(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height,
                ),
              ],
            ),
            ExpansionTile(
              title: Text(
                "Activities Overview",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              initiallyExpanded: false,
              children: const [
                StatisticsActivitiesView(),
              ],
            ),
          ],
        );
      },
    );
  }
}
