import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/food_data_controller.dart';
import '../controllers/food_management_controller.dart';
import 'custom_food_form_widget.dart';
import 'ingredient_recipe_widget.dart';
import 'food_list_widget.dart';

/// Complete food management tab
class FoodManageTab extends StatelessWidget {
  const FoodManageTab({super.key});

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _handleCreateCustomFood(BuildContext context) async {
    final managementController =
        Provider.of<FoodManagementController>(context, listen: false);
    final dataController =
        Provider.of<FoodDataController>(context, listen: false);

    try {
      await managementController.createCustomFood();
      await dataController.loadData();
      if (context.mounted) {
        _showSuccessSnackBar(context, 'Custom food created successfully!');
      }
    } catch (e) {
      if (kDebugMode) print('Error creating custom food: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Custom food creation section
          Consumer<FoodManagementController>(
            builder: (context, controller, child) {
              return CustomFoodFormWidget(
                onSubmit: () => _handleCreateCustomFood(context),
              );
            },
          ),
          const SizedBox(height: 16),

          // Create food from ingredients section
          Consumer<FoodManagementController>(
            builder: (context, controller, child) {
              return const IngredientRecipeWidget();
            },
          ),
          const SizedBox(height: 16),

          // Food list section
          Consumer<FoodDataController>(
            builder: (context, controller, child) {
              return const FoodListWidget();
            },
          ),
        ],
      ),
    );
  }
}
