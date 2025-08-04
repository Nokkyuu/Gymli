import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/food_data_controller.dart';

/// Widget to display nutritional information per 100g
class NutritionalInfoWidget extends StatelessWidget {
  const NutritionalInfoWidget({super.key});

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
    return Consumer<FoodDataController>(
      builder: (context, controller, child) {
        final selectedFood = controller.selectedFood;
        if (selectedFood == null) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutritional Info (per 100g)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientChip(
                        'Calories',
                        '${selectedFood.kcalPer100g.toInt()}',
                        'kcal',
                        Colors.orange),
                    _buildNutrientChip(
                        'Protein',
                        '${selectedFood.proteinPer100g.toStringAsFixed(1)}',
                        'g',
                        Colors.red),
                    _buildNutrientChip(
                        'Carbs',
                        '${selectedFood.carbsPer100g.toStringAsFixed(1)}',
                        'g',
                        Colors.green),
                    _buildNutrientChip(
                        'Fat',
                        '${selectedFood.fatPer100g.toStringAsFixed(1)}',
                        'g',
                        Colors.purple),
                  ],
                ),
                if (selectedFood.notes != null &&
                    selectedFood.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(selectedFood.notes!),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
