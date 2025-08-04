import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/food_management_controller.dart';

/// Widget for custom food creation form
class CustomFoodFormWidget extends StatelessWidget {
  final VoidCallback onSubmit;

  const CustomFoodFormWidget({
    super.key,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodManagementController>(
      builder: (context, controller, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Custom Food',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.customFoodNameController,
                  decoration: const InputDecoration(
                    labelText: 'Food Name',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Homemade Chicken Salad',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.customFoodCaloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calories per 100g',
                          border: OutlineInputBorder(),
                          suffixText: 'kcal',
                          hintText: '250',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: controller.customFoodProteinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Protein per 100g',
                          border: OutlineInputBorder(),
                          suffixText: 'g',
                          hintText: '20',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.customFoodCarbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Carbs per 100g',
                          border: OutlineInputBorder(),
                          suffixText: 'g',
                          hintText: '15',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: controller.customFoodFatController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fat per 100g',
                          border: OutlineInputBorder(),
                          suffixText: 'g',
                          hintText: '10',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.customFoodNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Additional information about this food',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Food'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
