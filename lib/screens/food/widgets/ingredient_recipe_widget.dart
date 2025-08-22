import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/food_data_controller.dart';
import '../controllers/food_management_controller.dart';
import '../../../utils/models/data_models.dart';
import '../../../utils/api/api_export.dart';
import 'package:get_it/get_it.dart';

/// Widget for creating food from ingredients/recipe
class IngredientRecipeWidget extends StatelessWidget {
  const IngredientRecipeWidget({super.key});

  void _showCreateDialog(BuildContext context, Map<String, double> nutrition) {
    String newName = '';
    String newNote = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Name your dish'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Dish name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        newName = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        newNote = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Per 100g: ${nutrition['kcal100']!.toStringAsFixed(0)} kcal, '
                    '${nutrition['protein100']!.toStringAsFixed(1)}g protein, '
                    '${nutrition['carbs100']!.toStringAsFixed(1)}g carbs, '
                    '${nutrition['fat100']!.toStringAsFixed(1)}g fat',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: newName.isNotEmpty
                      ? () => Navigator.pop(context, {
                            'name': newName,
                            'note': newNote,
                          })
                      : null,
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result != null) {
        try {
          final dataController =
              Provider.of<FoodDataController>(context, listen: false);
          final managementController =
              Provider.of<FoodManagementController>(context, listen: false);

          await GetIt.I<FoodService>().createFood(
            name: result['name'],
            kcalPer100g: nutrition['kcal100']!,
            proteinPer100g: nutrition['protein100']!,
            carbsPer100g: nutrition['carbs100']!,
            fatPer100g: nutrition['fat100']!,
            notes: result['note'].isNotEmpty ? result['note'] : null,
          );

          await dataController.loadData();
          managementController.resetFoodComponents();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Created food item!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create food: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
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
                  'Create Food item from Ingredients',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: managementController.foodComponents.length,
                  itemBuilder: (context, index) {
                    final component =
                        managementController.foodComponents[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Autocomplete<ApiFood>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return dataController.foods;
                                }
                                return dataController.foods.where(
                                    (ApiFood food) => food.name
                                        .toLowerCase()
                                        .contains(textEditingValue.text
                                            .toLowerCase()));
                              },
                              displayStringForOption: (ApiFood food) =>
                                  food.name,
                              initialValue: component.food != null
                                  ? TextEditingValue(text: component.food!.name)
                                  : const TextEditingValue(),
                              onSelected: (ApiFood selected) {
                                managementController.updateFoodComponent(index,
                                    food: selected);
                              },
                              fieldViewBuilder: (context, controller, focusNode,
                                  onFieldSubmitted) {
                                if (component.food != null &&
                                    controller.text != component.food!.name) {
                                  controller.text = component.food!.name;
                                }
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Type to search foods...',
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Grams',
                                suffixText: 'g',
                              ),
                              onChanged: (value) {
                                final grams = double.tryParse(value) ?? 0;
                                managementController.updateFoodComponent(index,
                                    grams: grams);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              managementController.removeFoodComponent(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    managementController.addFoodComponent();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Ingredient'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final nutrition = managementController
                        .calculateNutritionFromIngredients();
                    if (nutrition != null) {
                      _showCreateDialog(context, nutrition);
                    }
                  },
                  child: const Text('Name the dish and create'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
