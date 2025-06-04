/// Statistics Coordinator - Orchestrates interactions between services
///
/// This coordinator manages the interaction between different statistics services
/// and provides a unified interface for the StatisticsScreen.

import 'statistics_data_service.dart';
import 'statistics_calculation_service.dart';
import 'statistics_filter_service.dart';
import '../../../api_models.dart';

class StatisticsCoordinator {
  final StatisticsDataService _dataService;
  final StatisticsCalculationService _calculationService;
  final StatisticsFilterService _filterService;

  StatisticsCoordinator({
    required StatisticsDataService dataService,
    required StatisticsCalculationService calculationService,
    required StatisticsFilterService filterService,
  })  : _dataService = dataService,
        _calculationService = calculationService,
        _filterService = filterService;

  /// Get filtered training sets and exercises for statistics calculations
  Future<Map<String, dynamic>> getFilteredData({
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) async {
    try {
      // Get raw data from data service
      final trainingSets = await _dataService.getTrainingSets();
      final exercises = await _dataService.getExercises();

      // Apply filtering
      final filteredTrainingSets = _filterService.filterTrainingSets(
        trainingSets: trainingSets,
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: useDefaultFilter,
      );

      return {
        'trainingSets': filteredTrainingSets,
        'exercises': exercises,
      };
    } catch (e) {
      print('Error in StatisticsCoordinator.getFilteredData: $e');
      rethrow;
    }
  }

  /// Get heat map data for muscle visualization
  List<double> getHeatMapData(List<List<double>> muscleHistoryScore) {
    try {
      return _calculationService.calculateHeatMapData(muscleHistoryScore);
    } catch (e) {
      print('Error getting heat map data: $e');
      return List.filled(14, 0.0);
    }
  }

  /// Get equipment usage statistics
  Future<Map<String, int>> getEquipmentUsage({
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) async {
    try {
      final data = await getFilteredData(
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: useDefaultFilter,
      );

      final equipmentUsage = _calculationService.calculateEquipmentUsage(
        data['trainingSets'],
        data['exercises'],
      );

      return {
        'freeWeights': equipmentUsage.freeWeights,
        'machines': equipmentUsage.machines,
        'cables': equipmentUsage.cables,
        'bodyweight': equipmentUsage.bodyweight,
      };
    } catch (e) {
      print('Error getting equipment usage: $e');
      return {'freeWeights': 0, 'machines': 0, 'cables': 0, 'bodyweight': 0};
    }
  }

  /// Get activity statistics
  Future<Map<String, dynamic>> getActivityStatistics() async {
    try {
      return await _dataService.getActivityStats();
    } catch (e) {
      print('Error getting activity statistics: $e');
      return {};
    }
  }

  /// Calculate comprehensive bar statistics using the calculation service
  Future<StatisticsCalculationResult> calculateBarStatistics({
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) async {
    try {
      // Get filtered data
      final data = await getFilteredData(
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: useDefaultFilter,
      );

      final trainingSets = data['trainingSets'] as List<Map<String, dynamic>>;
      final exercises = data['exercises'] as List<ApiExercise>;

      // Extract filtered training dates
      Set<DateTime> uniqueDates = {};
      for (var trainingSet in trainingSets) {
        try {
          final date = DateTime.parse(trainingSet['date']);
          if (trainingSet['set_type'] > 0) {
            uniqueDates.add(DateTime(date.year, date.month, date.day));
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
      final filteredTrainingDates = uniqueDates.toList()..sort();

      // Use calculation service to get comprehensive results
      return await _calculationService.calculateBarStatistics(
        trainingSets: trainingSets,
        exercises: exercises,
        filteredTrainingDates: filteredTrainingDates,
      );
    } catch (e) {
      print('Error in StatisticsCoordinator.calculateBarStatistics: $e');
      return StatisticsCalculationResult.empty();
    }
  }

  /// Load activity data using the data service
  Future<ActivityDataResult> loadActivityData({
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) async {
    try {
      return await _dataService.loadActivityData(
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: useDefaultFilter,
      );
    } catch (e) {
      print('Error in StatisticsCoordinator.loadActivityData: $e');
      return ActivityDataResult.empty();
    }
  }

  /// Load exercise graph data using the calculation service
  Future<ExerciseGraphDataResult> loadExerciseGraphData({
    required String exerciseName,
    String? startingDate,
    String? endingDate,
    bool useDefaultFilter = true,
  }) async {
    try {
      final allTrainingSets = await _dataService.getTrainingSets();
      return await _calculationService.loadExerciseGraphData(
        exerciseName: exerciseName,
        allTrainingSets: allTrainingSets,
        startingDate: startingDate,
        endingDate: endingDate,
        useDefaultFilter: useDefaultFilter,
      );
    } catch (e) {
      print('Error in StatisticsCoordinator.loadExerciseGraphData: $e');
      return ExerciseGraphDataResult.empty();
    }
  }
}
