import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/food_data_controller.dart';

/// Widget to display today's food stats
class FoodStatsWidget extends StatelessWidget {
  const FoodStatsWidget({super.key});

  Widget _buildStatsChip(String label, String value, String unit) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '$value$unit',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodDataController>(
      builder: (context, controller, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Today's nutrition summary
            Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Today:'),
                  const SizedBox(width: 16),
                  FutureBuilder<Map<String, double>>(
                    future: (() {
                      final now = DateTime.now();
                      final startOfDay = DateTime(now.year, now.month, now.day);
                      final endOfDay = startOfDay
                          .add(const Duration(days: 1))
                          .subtract(const Duration(milliseconds: 1));
                      return controller.getFoodLogStats(
                        startDate: startOfDay,
                        endDate: endOfDay,
                      );
                    })(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final stats = snapshot.data!;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatsChip(
                              'kcal',
                              stats['total_calories']?.toStringAsFixed(0) ??
                                  '0',
                              '',
                            ),
                            const SizedBox(width: 8),
                            _buildStatsChip(
                              'Protein',
                              stats['total_protein']?.toStringAsFixed(1) ?? '0',
                              'g',
                            ),
                            const SizedBox(width: 8),
                            _buildStatsChip(
                              'Carbs',
                              stats['total_carbs']?.toStringAsFixed(1) ?? '0',
                              'g',
                            ),
                            const SizedBox(width: 8),
                            _buildStatsChip(
                              'Fat',
                              stats['total_fat']?.toStringAsFixed(1) ?? '0',
                              'g',
                            ),
                          ],
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
