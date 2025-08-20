import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/services/temp_service.dart';
import '../../../utils/api/api_models.dart';
import 'package:get_it/get_it.dart';

/// Controller for managing food data, loading, and search functionality
class FoodDataController extends ChangeNotifier {
  final TempService container = GetIt.I<TempService>();

  // Data lists
  List<ApiFood> foods = [];
  List<ApiFoodLog> foodLogs = [];
  Map<String, double> nutritionStats = {};

  // Loading states
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Search functionality
  String _foodSearchQuery = '';
  String get foodSearchQuery => _foodSearchQuery;

  // Selected food for logging
  String? selectedFoodName;

  // Chart data
  List<FlSpot> caloriesTrendData = [];
  List<FlSpot> proteinTrendData = [];

  // Date selection
  DateTime selectedDate = DateTime.now();

  // Filtered foods getter
  List<ApiFood> get filteredFoods {
    if (_foodSearchQuery.isEmpty) return foods;
    return foods
        .where((food) =>
            food.name.toLowerCase().contains(_foodSearchQuery.toLowerCase()))
        .toList();
  }

  /// Initialize and load all food data
  Future<void> loadData() async {
    _setLoading(true);

    try {
      // Load all data
      final foodsData = await container.foodService.getFoods();
      final logsData = await container.foodService.getFoodLogs();
      final statsData = await container.getFoodLogStats();

      foods = foodsData.map((data) => ApiFood.fromJson(data)).toList();
      foodLogs = logsData.map((data) => ApiFoodLog.fromJson(data)).toList();
      nutritionStats = statsData;

      // Set default selected food by name
      if (foods.isNotEmpty && selectedFoodName == null) {
        selectedFoodName = foods.first.name;
      }

      // Verify selected food still exists
      if (selectedFoodName != null) {
        final foodExists = foods.any((f) => f.name == selectedFoodName);
        if (!foodExists && foods.isNotEmpty) {
          selectedFoodName = foods.first.name;
        }
      }

      _updateChartData();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading food data: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _foodSearchQuery = query;
    notifyListeners();
  }

  /// Set selected food by name
  void setSelectedFood(String foodName) {
    selectedFoodName = foodName;
    notifyListeners();
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  /// Get selected food object
  ApiFood? get selectedFood {
    if (selectedFoodName == null) return null;
    try {
      return foods.firstWhere((f) => f.name == selectedFoodName);
    } catch (e) {
      return foods.isNotEmpty ? foods.first : null;
    }
  }

  /// Update chart data for trends
  void _updateChartData() {
    // Sort logs by date for chart data
    final sortedLogs = List<ApiFoodLog>.from(foodLogs);
    sortedLogs.sort((a, b) => a.date.compareTo(b.date));

    // Create chart data points
    caloriesTrendData.clear();
    proteinTrendData.clear();

    for (int i = 0; i < sortedLogs.length; i++) {
      final log = sortedLogs[i];
      final dayIndex = log.date
          .difference(DateTime.now().subtract(const Duration(days: 30)))
          .inDays
          .toDouble();

      if (dayIndex >= 0) {
        final multiplier = log.grams / 100.0;
        final calories = log.kcalPer100g * multiplier;
        final protein = log.proteinPer100g * multiplier;

        caloriesTrendData.add(FlSpot(dayIndex, calories));
        proteinTrendData.add(FlSpot(dayIndex, protein));
      }
    }
  }

  /// Delete a food log entry
  Future<void> deleteFoodLog(ApiFoodLog log) async {
    if (log.id == null) return;

    try {
      await container.foodService.deleteFoodLog(logId: log.id!);
      await loadData(); // Reload data after deletion
    } catch (e) {
      if (kDebugMode) print('Error deleting food log: $e');
      rethrow;
    }
  }

  /// Delete a food item
  Future<void> deleteFood(ApiFood food) async {
    if (food.id == null) return;

    try {
      await container.foodService.deleteFood(foodId: food.id!);
      await loadData(); // Reload data after deletion
    } catch (e) {
      if (kDebugMode) print('Error deleting food: $e');
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
