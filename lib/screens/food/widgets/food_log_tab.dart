import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/food_data_controller.dart';
import '../controllers/food_logging_controller.dart';
import 'food_autocomplete_widget.dart';
import 'nutritional_info_widget.dart';
import 'calculated_nutrition_widget.dart';
import 'date_weight_input_widget.dart';
import 'food_stats_widget.dart';
import 'food_history_widget.dart';
import '../../../utils/themes/responsive_helper.dart';

/// Complete food logging tab with form and history
class FoodLogTab extends StatelessWidget {
  const FoodLogTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Log form takes 2/3 of the width
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Log Food',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Today's stats
                        const FoodStatsWidget(),

                        // Food selection autocomplete
                        const FoodAutocompleteWidget(),
                        const SizedBox(height: 16),

                        // Show nutritional info for selected food
                        Consumer<FoodDataController>(
                          builder: (context, dataController, child) {
                            if (dataController.selectedFoodName != null) {
                              return const Column(
                                children: [
                                  NutritionalInfoWidget(),
                                  SizedBox(height: 16),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // Date and weight input with log button
                        const DateWeightInputWidget(),
                        const SizedBox(height: 16),

                        // Show calculated nutrition for the portion
                        Consumer2<FoodDataController, FoodLoggingController>(
                          builder: (context, dataController, loggingController,
                              child) {
                            if (loggingController
                                    .gramsController.text.isNotEmpty &&
                                dataController.selectedFoodName != null) {
                              return const Column(
                                children: [
                                  CalculatedNutritionWidget(),
                                  SizedBox(height: 16),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(width: 24),
          // History panel takes 1/3 of the width (only on non-mobile)
          if (!ResponsiveHelper.isMobile(context))
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const FoodHistoryWidget(),
                  ),
                  const Divider(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
