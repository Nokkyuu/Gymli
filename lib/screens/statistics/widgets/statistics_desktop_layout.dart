/// Statistics Desktop Layout Widget
/// Desktop-specific layout for statistics screen with sidebar navigation
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/statistics_main_controller.dart';
import '../widgets/statistics_date_picker.dart';
import '../widgets/statistics_trainings_chart.dart';
import '../widgets/statistics_muscle_heatmap.dart';
import '../widgets/statistics_activities_view.dart';
import '../widgets/statistics_exercise_progress.dart';
import '../widgets/statistics_overview.dart';
import '../widgets/food.dart';
import '../widgets/calorie_balance.dart';
import '../widgets/workout_analyzer.dart';

class StatisticsDesktopLayout extends StatelessWidget {
  const StatisticsDesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsMainController>(
      builder: (context, controller, child) {
        return Row(
          children: [
            // Left side - 1/3 of screen width
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    const StatisticsDatePicker(),
                    const SizedBox(height: 20),
                    const Divider(),
                    // List of selectable widgets
                    Text(
                      "Statistics Views",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildListTile(
                            context,
                            controller,
                            "Statistics Overview",
                            0,
                          ),
                          _buildListTile(
                            context,
                            controller,
                            "Trainings per Week",
                            1,
                          ),
                          _buildListTile(
                            context,
                            controller,
                            "Muscle Heatmap",
                            3,
                          ),
                          _buildListTile(
                            context,
                            controller,
                            "Exercise Progress",
                            4,
                          ),
                          _buildListTile(
                            context,
                            controller,
                            "Workout Analyzer",
                            8,
                          ),
                          _buildListTile(
                            context,
                            controller,
                            "Activities",
                            5,
                          ),
                          _buildListTile(
                            context,
                            controller,
                            "Nutrition",
                            6,
                          ),
                          _buildListTile(
                            context,
                            controller,
                            "Calorie Balance",
                            7,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right side - 2/3 of screen width
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: _buildSelectedWidget(context, controller),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListTile(
    BuildContext context,
    StatisticsMainController controller,
    String title,
    int index,
  ) {
    return ListTile(
      title: Text(title),
      selected: controller.selectedWidgetIndex == index,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      onTap: () {
        controller.setSelectedWidget(index);
      },
      trailing: controller.selectedWidgetIndex == index
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
    );
  }

  Widget _buildSelectedWidget(
    BuildContext context,
    StatisticsMainController controller,
  ) {
    switch (controller.selectedWidgetIndex) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Statistics Overview",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
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
          ],
        );
      case 1:
        return Column(
          children: [
            Text(
              "Number of Trainings per Week",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 10.0, top: 15.0, left: 0.0),
                child: StatisticsTrainingsChart(),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Text(
              "Heatmap: relative to most used muscle",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: StatisticsMuscleHeatmap(
                width: 400,
                height: 600,
              ),
            ),
          ],
        );
      case 4:
        return const StatisticsExerciseProgress();
      case 5:
        return const StatisticsActivitiesView();
      case 6:
        return FoodStatsScreen(
          key: ValueKey(
            '${controller.startingDate}_${controller.endingDate}_${controller.useDefaultDateFilter}',
          ),
          startingDate: controller.startingDate,
          endingDate: controller.endingDate,
          useDefaultDateFilter: controller.useDefaultDateFilter,
        );
      case 7:
        return CalorieBalanceScreen(
          key: ValueKey(
            '${controller.startingDate}_${controller.endingDate}_${controller.useDefaultDateFilter}',
          ),
          startingDate: controller.startingDate,
          endingDate: controller.endingDate,
          useDefaultDateFilter: controller.useDefaultDateFilter,
        );
      case 8:
        return WorkoutAnalyzerScreen(
          key: ValueKey(
            '${controller.startingDate}_${controller.endingDate}_${controller.useDefaultDateFilter}',
          ),
          startingDate: controller.startingDate,
          endingDate: controller.endingDate,
          useDefaultDateFilter: controller.useDefaultDateFilter,
        );
      default:
        return Container();
    }
  }
}
