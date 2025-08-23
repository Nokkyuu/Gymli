import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/food_data_controller.dart';
import '../controllers/food_management_controller.dart';
import '../../../utils/models/data_models.dart';
import '../../../utils/themes/responsive_helper.dart';

/// Widget to display and manage food list
class FoodListWidget extends StatelessWidget {
  const FoodListWidget({super.key});

  void _showDeleteFoodConfirmation(
      BuildContext context, FoodItem food, FoodDataController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Food'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${food.name}"?'),
            const SizedBox(height: 8),
            const Text(
              'This will also delete all associated food logs.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await controller.deleteFood(food);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Food deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (kDebugMode) print('Error deleting food: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete food: $e'),
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

    if (name.contains('apple') ||
        name.contains('fruit') ||
        name.contains('banana')) {
      return FontAwesomeIcons.appleWhole;
    }
    if (name.contains('bread') || name.contains('grain')) {
      return FontAwesomeIcons.breadSlice;
    }
    if (name.contains('chicken') || name.contains('meat')) {
      return FontAwesomeIcons.drumstickBite;
    }
    if (name.contains('fish')) {
      return FontAwesomeIcons.fish;
    }
    if (name.contains('cheese') || name.contains('milk')) {
      return FontAwesomeIcons.cheese;
    }
    if (name.contains('egg')) {
      return FontAwesomeIcons.egg;
    }

    return FontAwesomeIcons.utensils;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FoodDataController, FoodManagementController>(
      builder: (context, dataController, managementController, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Foods',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Search bar
                TextField(
                  controller: managementController.searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search foods...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Type to filter foods',
                  ),
                  onChanged: (value) {
                    dataController.updateSearchQuery(value);
                  },
                ),
                const SizedBox(height: 16),

                if (dataController.filteredFoods.isEmpty &&
                    dataController.foodSearchQuery.isNotEmpty)
                  const Center(
                    child: Text(
                      'No foods found matching search',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else if (dataController.foods.isEmpty)
                  const Center(
                    child: Text(
                      'No foods loaded yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else if (!ResponsiveHelper.isMobile(context))
                  SizedBox(
                    height: 300,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: dataController.filteredFoods.length,
                      itemBuilder: (context, index) {
                        final food = dataController.filteredFoods[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getFoodColor(food.name),
                              child: Icon(
                                _getFoodIcon(food.name),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(food.name),
                            subtitle: Text(
                                '${food.kcalPer100g.toInt()} kcal/100g\nP:${food.proteinPer100g.toStringAsFixed(1)}g C:${food.carbsPer100g.toStringAsFixed(1)}g F:${food.fatPer100g.toStringAsFixed(1)}g'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteFoodConfirmation(
                                  context, food, dataController),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: dataController.filteredFoods.length,
                      itemBuilder: (context, index) {
                        final food = dataController.filteredFoods[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getFoodColor(food.name),
                            child: Icon(
                              _getFoodIcon(food.name),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(food.name),
                          subtitle: Text(
                              '${food.kcalPer100g.toInt()} kcal/100g\nP:${food.proteinPer100g.toStringAsFixed(1)}g C:${food.carbsPer100g.toStringAsFixed(1)}g F:${food.fatPer100g.toStringAsFixed(1)}g'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteFoodConfirmation(
                                context, food, dataController),
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
