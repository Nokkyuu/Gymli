/// FoodService - Manages food items and food logs
///
/// This service handles all CRUD operations for food items and food logs,
/// which are used for nutrition tracking and calorie management.
///
library;

import 'dart:convert';
import '../api/api_base.dart';
import '../models/data_models.dart';

class FoodService {
  /// Retrieves all food items for a user
  /// Returns a list of food item objects
  Future<List<FoodItem>> getFoods() async {
    final raw = await getData<List<dynamic>>('foods');
    final foodItems = raw.map((item) => FoodItem.fromJson(item)).toList();
    return foodItems;
  }

  /// Creates a new food item
  Future<FoodItem> createFood({
    required FoodItem foodItem,
  }) async {
    final responseBody = await createData('foods', foodItem.toJson());
    return FoodItem.fromJson(json.decode(responseBody));
  }

  /// Creates multiple food items in a single batch operation
  Future<List<FoodItem>> createFoodsBulk({
    required List<FoodItem> foods,
  }) async {
    if (foods.isEmpty) {
      throw Exception('Food items list cannot be empty');
    }

    if (foods.length > 1000) {
      throw Exception(
          'Cannot create more than 1000 food items in a single request');
    }

    final responseBody = await createData(
        'foods/bulk', foods.map((item) => item.toJson()).toList());
    final List<dynamic> decoded = json.decode(responseBody);
    return decoded.map((item) => FoodItem.fromJson(item)).toList();
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
  Future<List<FoodLog>> getFoodLogs({
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
    final raw = await getData<List<dynamic>>(url);
    return raw.map((item) => FoodLog.fromJson(item)).toList();
  }

  /// Creates a new food log entry
  Future<FoodLog> createFoodLog({
    required FoodLog foodLog,
  }) async {
    final responseBody = await createData('food_logs', foodLog.toJson());
    return FoodLog.fromJson(json.decode(responseBody));
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

  Future<List<Map<String, dynamic>>> getDailyFoodLogStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await getFoodLogs(
      startDate: startDate,
      endDate: endDate,
    );

    // Group logs by date
    Map<String, Map<String, double>> dailyStats = {};

    for (var log in logs) {
      final dateString = log.date as String;
      final date = DateTime.parse(dateString);
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final grams = (log.grams as num).toDouble();
      final kcalPer100g = (log.kcalPer100g as num).toDouble();
      final proteinPer100g = (log.proteinPer100g as num).toDouble();
      final carbsPer100g = (log.carbsPer100g as num).toDouble();
      final fatPer100g = (log.fatPer100g as num).toDouble();

      final multiplier = grams / 100.0;
      final calories = kcalPer100g * multiplier;
      final protein = proteinPer100g * multiplier;
      final carbs = carbsPer100g * multiplier;
      final fat = fatPer100g * multiplier;

      if (!dailyStats.containsKey(dateKey)) {
        dailyStats[dateKey] = {
          'calories': 0.0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
        };
      }

      dailyStats[dateKey]!['calories'] =
          dailyStats[dateKey]!['calories']! + calories;
      dailyStats[dateKey]!['protein'] =
          dailyStats[dateKey]!['protein']! + protein;
      dailyStats[dateKey]!['carbs'] = dailyStats[dateKey]!['carbs']! + carbs;
      dailyStats[dateKey]!['fat'] = dailyStats[dateKey]!['fat']! + fat;
    }

    // Convert to list format and fill in missing dates
    List<Map<String, dynamic>> result = [];

    if (startDate != null && endDate != null) {
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final dateKey =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

        result.add({
          'date': dateKey,
          'calories': dailyStats[dateKey]?['calories'] ?? 0.0,
          'protein': dailyStats[dateKey]?['protein'] ?? 0.0,
          'carbs': dailyStats[dateKey]?['carbs'] ?? 0.0,
          'fat': dailyStats[dateKey]?['fat'] ?? 0.0,
        });

        currentDate = currentDate.add(const Duration(days: 1));
      }
    } else {
      // If no date range specified, just return the days we have data for
      for (var entry in dailyStats.entries) {
        result.add({
          'date': entry.key,
          'calories': entry.value['calories'],
          'protein': entry.value['protein'],
          'carbs': entry.value['carbs'],
          'fat': entry.value['fat'],
        });
      }
      // Sort by date
      result.sort((a, b) => a['date'].compareTo(b['date']));
    }

    return result;
  }

  Future<Map<String, double>> getFoodLogStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await getFoodLogs(
      startDate: startDate,
      endDate: endDate,
    );

    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;

    for (var log in logs) {
      final grams = (log.grams as num).toDouble();
      final kcalPer100g = (log.kcalPer100g as num).toDouble();
      final proteinPer100g = (log.proteinPer100g as num).toDouble();
      final carbsPer100g = (log.carbsPer100g as num).toDouble();
      final fatPer100g = (log.fatPer100g as num).toDouble();

      final multiplier = grams / 100.0;
      totalCalories += kcalPer100g * multiplier;
      totalProtein += proteinPer100g * multiplier;
      totalCarbs += carbsPer100g * multiplier;
      totalFat += fatPer100g * multiplier;
    }

    return {
      'total_calories': double.parse(totalCalories.toStringAsFixed(1)),
      'total_protein': double.parse(totalProtein.toStringAsFixed(1)),
      'total_carbs': double.parse(totalCarbs.toStringAsFixed(1)),
      'total_fat': double.parse(totalFat.toStringAsFixed(1)),
    };
  }
}
