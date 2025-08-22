import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../utils/services/temp_service.dart';
import '../../../utils/models/data_models.dart';
import '../../../utils/api/api_export.dart';
import 'package:get_it/get_it.dart';

/// Controller for food logging functionality
class FoodLoggingController extends ChangeNotifier {
  final TempService container = GetIt.I<TempService>();

  // Form controllers
  final TextEditingController gramsController = TextEditingController();

  FoodLoggingController() {
    // Listen to text changes and notify listeners
    gramsController.addListener(() {
      notifyListeners();
    });
  }

  /// Log food entry
  Future<void> logFood({
    required String selectedFoodName,
    required DateTime selectedDate,
    required List<ApiFood> foods,
  }) async {
    if (gramsController.text.isEmpty) {
      throw Exception('Please enter weight in grams');
    }

    final grams = double.tryParse(gramsController.text);
    if (grams == null || grams <= 0) {
      throw Exception('Please enter a valid weight in grams');
    }

    // Find the selected food to get nutritional data
    final selectedFood = foods.firstWhere(
      (f) => f.name == selectedFoodName,
      orElse: () => foods.first,
    );

    try {
      await GetIt.I<FoodService>().createFoodLog(
        foodName: selectedFoodName,
        date: selectedDate,
        grams: grams,
        kcalPer100g: selectedFood.kcalPer100g,
        proteinPer100g: selectedFood.proteinPer100g,
        carbsPer100g: selectedFood.carbsPer100g,
        fatPer100g: selectedFood.fatPer100g,
      );

      // Clear form after successful logging
      gramsController.clear();
    } catch (e) {
      if (kDebugMode) print('Error logging food: $e');
      rethrow;
    }
  }

  /// Calculate nutrition for given grams and food
  Map<String, double> calculateNutrition(ApiFood food, double grams) {
    final multiplier = grams / 100.0;
    return {
      'calories': food.kcalPer100g * multiplier,
      'protein': food.proteinPer100g * multiplier,
      'carbs': food.carbsPer100g * multiplier,
      'fat': food.fatPer100g * multiplier,
    };
  }

  @override
  void dispose() {
    gramsController.dispose();
    super.dispose();
  }
}
