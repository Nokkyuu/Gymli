import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/food_data_controller.dart';
import '../controllers/food_logging_controller.dart';

/// Widget to display calculated nutrition for entered portion
class CalculatedNutritionWidget extends StatelessWidget {
  const CalculatedNutritionWidget({super.key});

  Widget _buildNutrientChip(
      String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '$value$unit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FoodDataController, FoodLoggingController>(
      builder: (context, dataController, loggingController, child) {
        final grams = double.tryParse(loggingController.gramsController.text);
        final selectedFood = dataController.selectedFood;

        if (grams == null || grams <= 0 || selectedFood == null) {
          return const SizedBox.shrink();
        }

        final nutrition =
            loggingController.calculateNutrition(selectedFood, grams);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculated Nutrition (for ${grams.toStringAsFixed(0)}g)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientChip(
                        'Calories',
                        '${nutrition['calories']!.toStringAsFixed(0)}',
                        'kcal',
                        Colors.orange),
                    _buildNutrientChip(
                        'Protein',
                        '${nutrition['protein']!.toStringAsFixed(1)}',
                        'g',
                        Colors.red),
                    _buildNutrientChip(
                        'Carbs',
                        '${nutrition['carbs']!.toStringAsFixed(1)}',
                        'g',
                        Colors.green),
                    _buildNutrientChip(
                        'Fat',
                        '${nutrition['fat']!.toStringAsFixed(1)}',
                        'g',
                        Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
