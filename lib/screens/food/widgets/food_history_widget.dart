import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../controllers/food_data_controller.dart';
import '../../../utils/models/data_models.dart';

/// Widget to display food history/logs
class FoodHistoryWidget extends StatelessWidget {
  const FoodHistoryWidget({super.key});

  void _showDeleteConfirmation(
      BuildContext context, FoodLog log, FoodDataController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Food Log'),
        content:
            Text('Are you sure you want to delete this ${log.foodName} entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await controller.deleteFoodLog(log);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Food log deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete food log: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getFoodColor(String foodName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[foodName.hashCode % colors.length];
  }

  IconData _getFoodIcon(String foodName) {
    final name = foodName.toLowerCase();

    // Add comprehensive food icons logic
    if (name.contains('apple') ||
        name.contains('fruit') ||
        name.contains('obst') ||
        name.contains('apfel') ||
        name.contains('banana') ||
        name.contains('banane') ||
        name.contains('orange') ||
        name.contains('beere') ||
        name.contains('berry')) return FontAwesomeIcons.appleWhole;

    if (name.contains('bread') ||
        name.contains('grain') ||
        name.contains('brot') ||
        name.contains('brötchen')) return FontAwesomeIcons.breadSlice;

    if (name.contains('chicken') ||
        name.contains('meat') ||
        name.contains('huhn') ||
        name.contains('hähnchen') ||
        name.contains('fleisch')) return FontAwesomeIcons.drumstickBite;

    if (name.contains('fish') ||
        name.contains('fisch') ||
        name.contains('lachs') ||
        name.contains('salmon')) return FontAwesomeIcons.fish;

    if (name.contains('cheese') ||
        name.contains('käse') ||
        name.contains('milk') ||
        name.contains('milch')) return FontAwesomeIcons.cheese;

    if (name.contains('egg') || name.contains('ei') || name.contains('eier'))
      return FontAwesomeIcons.egg;

    return FontAwesomeIcons.utensils;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodDataController>(
      builder: (context, controller, child) {
        // Sort logs by date (newest first)
        final sortedLogs = List<FoodLog>.from(controller.foodLogs);
        sortedLogs.sort((a, b) => b.date.compareTo(a.date));

        if (sortedLogs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.utensils, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No food logs yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Start logging your meals in the Log tab',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedLogs.length,
          itemBuilder: (context, index) {
            final log = sortedLogs[index];
            final multiplier = log.grams / 100.0;
            final totalCalories = log.kcalPer100g * multiplier;
            final totalProtein = log.proteinPer100g * multiplier;
            final totalCarbs = log.carbsPer100g * multiplier;
            final totalFat = log.fatPer100g * multiplier;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getFoodColor(log.foodName),
                  child: Icon(
                    _getFoodIcon(log.foodName),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(log.foodName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('MMM dd, yyyy').format(log.date)),
                    Text(
                        '${log.grams.toStringAsFixed(0)}g • ${totalCalories.toStringAsFixed(0)} kcal'),
                    Text(
                      'P: ${totalProtein.toStringAsFixed(1)}g • C: ${totalCarbs.toStringAsFixed(1)}g • F: ${totalFat.toStringAsFixed(1)}g',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _showDeleteConfirmation(context, log, controller),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
