/// FoodService - Manages food items and food logs
///
/// This service handles all CRUD operations for food items and food logs,
/// which are used for nutrition tracking and calorie management.
///
library;

import 'dart:convert';
import 'api_base.dart';

class FoodService {
  /// Retrieves all food items for a user
  /// Returns a list of food item objects
  Future<List<dynamic>> getFoods() async {
    return getData<List<dynamic>>('foods');
  }

  /// Creates a new food item
  Future<Map<String, dynamic>> createFood({
    required String name,
    required double kcalPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    String? notes,
  }) async {
    return json.decode(await createData('foods', {
      'name': name,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'notes': notes,
    }));
  }

  /// Creates multiple food items in a single batch operation
  Future<List<Map<String, dynamic>>> createFoodsBulk({
    required List<Map<String, dynamic>> foods,
  }) async {
    if (foods.isEmpty) {
      throw Exception('Food items list cannot be empty');
    }

    if (foods.length > 1000) {
      throw Exception(
          'Cannot create more than 1000 food items in a single request');
    }

    return json.decode(await createData('foods/bulk', foods));
  }

  Future<Map<String, dynamic>> clearFoods() async {
    final response = await deleteData('foods/bulk_clear');
    if (response.statusCode == 200 || response.statusCode == 204) {
      final result = response.body.isNotEmpty
          ? json.decode(response.body)
          : {'message': 'Food items cleared successfully'};
      return result;
    } else {
      throw Exception(
          'Failed to clear food items: ${response.statusCode} ${response.body}');
    }
  }

  /// Deletes a food item
  Future<void> deleteFood({
    required int foodId,
  }) async {
    final response = await deleteData('foods/$foodId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete food: ${response.body}');
    }
  }

  /// Retrieves food logs with optional filtering
  Future<List<dynamic>> getFoodLogs({
    String? foodName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '/food_logs?';

    if (foodName != null) {
      url += '&food_name=${Uri.encodeComponent(foodName)}';
    }
    if (startDate != null) {
      url += '&start_date=${startDate.toIso8601String()}';
    }
    if (endDate != null) {
      url += '&end_date=${endDate.toIso8601String()}';
    }

    return getData<List<dynamic>>(url);
  }

  /// Creates a new food log entry
  Future<Map<String, dynamic>> createFoodLog({
    required String foodName,
    required DateTime date,
    required double grams,
    required double kcalPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
  }) async {
    return json.decode(await createData('food_logs', {
      'food_name': foodName,
      'date': date.toIso8601String(),
      'grams': grams,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
    }));
  }

  /// Deletes a food log entry
  Future<void> deleteFoodLog({
    required int logId,
  }) async {
    final response = await deleteData('food_logs/$logId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete food log: ${response.body}');
    }
  }
}
