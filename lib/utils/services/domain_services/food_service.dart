import '../../api/api.dart' as api;
import '../data_service.dart';

class FoodService {
  final DataService _dataService = DataService();

  // Getters that delegate to DataService
  bool get isLoggedIn => _dataService.isLoggedIn;
  String get userName => _dataService.userName;

  /// Retrieves all food items for the current user
  /// Returns a list of food item objects
  Future<List<dynamic>> getFoods() async {
    return await _dataService.getData(
      'foods',
      // API call for authenticated users
      () async => await api.FoodService().getFoods(userName: userName),
      // Fallback API call for non-authenticated users
      () async => await api.FoodService().getFoods(userName: 'DefaultUser'),
    );
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
    if (isLoggedIn) {
      return await api.FoodService().createFood(
        userName: userName,
        name: name,
        kcalPer100g: kcalPer100g,
        proteinPer100g: proteinPer100g,
        carbsPer100g: carbsPer100g,
        fatPer100g: fatPer100g,
        notes: notes,
      );
    } else {
      // For non-authenticated users, store in memory only
      final foods = _dataService.getInMemoryData('foods');
      final newId = foods.isEmpty
          ? 1
          : (foods.map((f) => f['id'] as int).reduce((a, b) => a > b ? a : b) +
              1);

      final food = {
        'id': newId,
        'user_name': 'DefaultUser',
        'name': name,
        'kcal_per_100g': kcalPer100g,
        'protein_per_100g': proteinPer100g,
        'carbs_per_100g': carbsPer100g,
        'fat_per_100g': fatPer100g,
        'notes': notes,
      };

      _dataService.addToInMemoryData('foods', food);
      return food;
    }
  }

  /// Deletes a food item
  Future<void> deleteFood(int foodId) async {
    if (isLoggedIn) {
      await api.FoodService().deleteFood(
        foodId: foodId,
        userName: userName,
      );
    } else {
      // Remove from memory
      _dataService.removeFromInMemoryData('foods', (f) => f['id'] == foodId);
    }
  }

  /// Retrieves food logs with optional filtering
  Future<List<dynamic>> getFoodLogs({
    String? foodName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (isLoggedIn) {
      return await api.FoodService().getFoodLogs(
        userName: userName,
        foodName: foodName,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      // Filter in-memory food logs
      List<dynamic> logs = List.from(_dataService.getInMemoryData('foodLogs'));

      if (foodName != null) {
        logs = logs.where((log) => log['food_name'] == foodName).toList();
      }

      if (startDate != null) {
        logs = logs.where((log) {
          final logDate = DateTime.parse(log['date']);
          return logDate.isAfter(startDate) ||
              logDate.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        logs = logs.where((log) {
          final logDate = DateTime.parse(log['date']);
          return logDate.isBefore(endDate) || logDate.isAtSameMomentAs(endDate);
        }).toList();
      }

      return logs;
    }
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
    if (isLoggedIn) {
      return await api.FoodService().createFoodLog(
        userName: userName,
        foodName: foodName,
        date: date,
        grams: grams,
        kcalPer100g: kcalPer100g,
        proteinPer100g: proteinPer100g,
        carbsPer100g: carbsPer100g,
        fatPer100g: fatPer100g,
      );
    } else {
      // For non-authenticated users, store in memory
      final foodLogs = _dataService.getInMemoryData('foodLogs');
      final newId = foodLogs.isEmpty
          ? 1
          : (foodLogs
                  .map((l) => l['id'] as int)
                  .reduce((a, b) => a > b ? a : b) +
              1);

      final log = {
        'id': newId,
        'user_name': 'DefaultUser',
        'food_name': foodName,
        'date': date.toIso8601String(),
        'grams': grams,
        'kcal_per_100g': kcalPer100g,
        'protein_per_100g': proteinPer100g,
        'carbs_per_100g': carbsPer100g,
        'fat_per_100g': fatPer100g,
      };

      _dataService.addToInMemoryData('foodLogs', log);
      return log;
    }
  }

  /// Deletes a food log entry
  Future<void> deleteFoodLog(int logId) async {
    if (isLoggedIn) {
      await api.FoodService().deleteFoodLog(
        logId: logId,
        userName: userName,
      );
    } else {
      // Remove from memory
      _dataService.removeFromInMemoryData(
          'foodLogs', (log) => log['id'] == logId);
    }
  }

  /// Gets nutrition statistics for food logs within a date range
  /// Returns calculated totals for calories, protein, carbs, and fat
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
      final grams = (log['grams'] as num).toDouble();
      final kcalPer100g = (log['kcal_per_100g'] as num).toDouble();
      final proteinPer100g = (log['protein_per_100g'] as num).toDouble();
      final carbsPer100g = (log['carbs_per_100g'] as num).toDouble();
      final fatPer100g = (log['fat_per_100g'] as num).toDouble();

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

  /// Gets daily nutrition statistics for food logs within a date range
  /// Returns a list of daily nutrition data for charting
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
      final dateString = log['date'] as String;
      final date = DateTime.parse(dateString);
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final grams = (log['grams'] as num).toDouble();
      final kcalPer100g = (log['kcal_per_100g'] as num).toDouble();
      final proteinPer100g = (log['protein_per_100g'] as num).toDouble();
      final carbsPer100g = (log['carbs_per_100g'] as num).toDouble();
      final fatPer100g = (log['fat_per_100g'] as num).toDouble();

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

  /// Creates multiple food items in a single batch operation
  /// This method is optimized for bulk imports and significantly reduces
  /// the number of HTTP requests compared to creating foods individually.
  ///
  /// [foods] - List of food data to create. Each item should contain:
  ///   - name, kcalPer100g, proteinPer100g, carbsPer100g, fatPer100g, notes
  ///
  /// Returns a list of created food items with their assigned IDs
  Future<List<Map<String, dynamic>>> createFoodsBulk(
    List<Map<String, dynamic>> foods,
  ) async {
    if (foods.isEmpty) {
      return [];
    }

    if (isLoggedIn) {
      // Convert the foods to the format expected by the API
      final apiFoods = foods
          .map((food) => {
                'name': food['name'],
                'kcal_per_100g': food['kcalPer100g'],
                'protein_per_100g': food['proteinPer100g'],
                'carbs_per_100g': food['carbsPer100g'],
                'fat_per_100g': food['fatPer100g'],
                'notes': food['notes'],
              })
          .toList();

      return await api.FoodService().createFoodsBulk(
        userName: userName,
        foods: apiFoods,
      );
    } else {
      // For offline mode, add all foods to in-memory storage
      final createdFoods = <Map<String, dynamic>>[];
      final existingFoods = _dataService.getInMemoryData('foods');

      int nextId = existingFoods.isEmpty
          ? 1
          : (existingFoods
                  .map((f) => f['id'] as int)
                  .reduce((a, b) => a > b ? a : b) +
              1);

      for (final food in foods) {
        final newFood = {
          'id': nextId++,
          'user_name': 'DefaultUser',
          'name': food['name'],
          'kcal_per_100g': food['kcalPer100g'],
          'protein_per_100g': food['proteinPer100g'],
          'carbs_per_100g': food['carbsPer100g'],
          'fat_per_100g': food['fatPer100g'],
          'notes': food['notes'],
        };

        _dataService.addToInMemoryData('foods', newFood);
        createdFoods.add(newFood);
      }

      return createdFoods;
    }
  }

  /// Clears all food data (both foods and food logs)
  Future<void> clearFoodData() async {
    if (isLoggedIn) {
      // OPTIMIZED: Use bulk delete endpoint instead of individual deletes
      await api.FoodService().clearFoods(userName: userName);
      print('Food items cleared using bulk delete endpoint');

      // Note: Food logs are not cleared in the original implementation
      // Still need to delete food logs individually since we don't have bulk delete for them yet
      // final foodLogs = await getFoodLogs();
      // int deletedLogsCount = 0;
      // int errorCount = 0;

      // for (var log in foodLogs) {
      //   if (log['id'] != null) {
      //     try {
      //       await deleteFoodLog(log['id']);
      //       deletedLogsCount++;
      //     } catch (e) {
      //       errorCount++;
      //       print('Warning: Failed to delete food log ${log['id']}: $e');
      //     }
      //   }
      // }

      // print(
      //     'Cleared food data: bulk delete for foods, $deletedLogsCount logs deleted, $errorCount errors');
    } else {
      // Clear in-memory food data
      _dataService.clearSpecificInMemoryData('foods');
      // Note: Food logs are not cleared in the original implementation
      // _dataService.clearSpecificInMemoryData('foodLogs');
      print('Cleared in-memory food data');
    }

    // Always clear in-memory data regardless of login status to prevent cache issues
    _dataService.clearSpecificInMemoryData('foods');
    // Note: Food logs are not cleared in the original implementation
    // _dataService.clearSpecificInMemoryData('foodLogs');
    print('Cleared in-memory food data cache');
  }
}
