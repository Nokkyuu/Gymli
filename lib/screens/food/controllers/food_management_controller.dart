import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../utils/services/service_container.dart';
import '../../../utils/api/api_models.dart';

/// Component for ingredients when creating custom food
class FoodComponent {
  ApiFood? food;
  double grams = 0;
}

/// Controller for custom food creation and management
class FoodManagementController extends ChangeNotifier {
  final ServiceContainer container = ServiceContainer();

  // Form controllers for custom food creation
  final TextEditingController customFoodNameController =
      TextEditingController();
  final TextEditingController customFoodCaloriesController =
      TextEditingController();
  final TextEditingController customFoodProteinController =
      TextEditingController();
  final TextEditingController customFoodCarbsController =
      TextEditingController();
  final TextEditingController customFoodFatController = TextEditingController();
  final TextEditingController customFoodNotesController =
      TextEditingController();

  // Search controller for food list
  final TextEditingController searchController = TextEditingController();

  // Food components for recipe creation
  List<FoodComponent> _foodComponents = [FoodComponent()];
  List<FoodComponent> get foodComponents => _foodComponents;

  /// Create custom food from form data
  Future<void> createCustomFood() async {
    if (kDebugMode) print('Create custom food button pressed');

    // Validate required fields
    if (customFoodNameController.text.isEmpty ||
        customFoodCaloriesController.text.isEmpty ||
        customFoodProteinController.text.isEmpty ||
        customFoodCarbsController.text.isEmpty ||
        customFoodFatController.text.isEmpty) {
      throw Exception('Please fill in all nutritional information');
    }

    final calories = double.tryParse(customFoodCaloriesController.text);
    final protein = double.tryParse(customFoodProteinController.text);
    final carbs = double.tryParse(customFoodCarbsController.text);
    final fat = double.tryParse(customFoodFatController.text);

    if (calories == null ||
        calories < 0 ||
        protein == null ||
        protein < 0 ||
        carbs == null ||
        carbs < 0 ||
        fat == null ||
        fat < 0) {
      throw Exception('Please enter valid nutritional values');
    }

    try {
      if (kDebugMode) print('Calling container.foodService.createFood...');
      final result = await container.foodService.createFood(
        name: customFoodNameController.text,
        kcalPer100g: calories,
        proteinPer100g: protein,
        carbsPer100g: carbs,
        fatPer100g: fat,
        notes: customFoodNotesController.text.isNotEmpty
            ? customFoodNotesController.text
            : null,
      );

      if (kDebugMode) print('Food created successfully: $result');

      // Clear form
      _clearCustomFoodForm();
    } catch (e) {
      if (kDebugMode) print('Error creating custom food: $e');
      rethrow;
    }
  }

  /// Create food from ingredients/recipe
  Map<String, double>? calculateNutritionFromIngredients() {
    final validComponents =
        _foodComponents.where((c) => c.food != null && c.grams > 0).toList();

    if (validComponents.length < 2) {
      throw Exception('Please add at least 2 ingredients');
    }

    // Calculate total nutrition
    final totalGrams =
        validComponents.fold<double>(0, (sum, c) => sum + c.grams);
    if (totalGrams == 0) return null;

    double kcal = 0, protein = 0, carbs = 0, fat = 0;
    for (final c in validComponents) {
      final factor = c.grams / 100.0;
      kcal += c.food!.kcalPer100g * factor;
      protein += c.food!.proteinPer100g * factor;
      carbs += c.food!.carbsPer100g * factor;
      fat += c.food!.fatPer100g * factor;
    }

    // Calculate per 100g values
    final kcal100 = kcal / totalGrams * 100;
    final protein100 = protein / totalGrams * 100;
    final carbs100 = carbs / totalGrams * 100;
    final fat100 = fat / totalGrams * 100;

    return {
      'kcal100': kcal100,
      'protein100': protein100,
      'carbs100': carbs100,
      'fat100': fat100,
      'totalGrams': totalGrams,
    };
  }

  /// Add ingredient to food components
  void addFoodComponent() {
    _foodComponents.add(FoodComponent());
    notifyListeners();
  }

  /// Remove ingredient from food components
  void removeFoodComponent(int index) {
    if (_foodComponents.length > 1) {
      _foodComponents.removeAt(index);
      notifyListeners();
    }
  }

  /// Update food component
  void updateFoodComponent(int index, {ApiFood? food, double? grams}) {
    if (index < _foodComponents.length) {
      if (food != null) _foodComponents[index].food = food;
      if (grams != null) _foodComponents[index].grams = grams;
      notifyListeners();
    }
  }

  /// Reset food components to initial state
  void resetFoodComponents() {
    _foodComponents = [FoodComponent()];
    notifyListeners();
  }

  /// Clear the custom food form
  void _clearCustomFoodForm() {
    customFoodNameController.clear();
    customFoodCaloriesController.clear();
    customFoodProteinController.clear();
    customFoodCarbsController.clear();
    customFoodFatController.clear();
    customFoodNotesController.clear();
  }

  @override
  void dispose() {
    customFoodNameController.dispose();
    customFoodCaloriesController.dispose();
    customFoodProteinController.dispose();
    customFoodCarbsController.dispose();
    customFoodFatController.dispose();
    customFoodNotesController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
