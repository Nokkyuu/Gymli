/// ServiceContainer is a singleton that manages all services in the application.
/// Replacement for the deprecated UserService.
/// please see the seperate service files for more details on each service.
library;

import 'auth_service.dart';
import 'auth0_service.dart';
import 'data_service.dart';
import 'domain_services/exercise_service.dart';
import 'domain_services/workout_service.dart';
import 'domain_services/training_set_service.dart';
import 'domain_services/activity_service.dart';
import 'domain_services/food_service.dart';
import 'domain_services/calendar_service.dart';

class ServiceContainer {
  /// Singleton instance for ServiceContainer
  static ServiceContainer? _instance;

  factory ServiceContainer() {
    _instance ??= ServiceContainer._internal();
    return _instance!;
  }

  ServiceContainer._internal() {
    _setupServices();
  }

  // Core services
  late final AuthService authService;
  late final DataService dataService;

  // Domain services
  late final ExerciseService exerciseService;
  late final WorkoutService workoutService;
  late final TrainingSetService trainingSetService;
  late final ActivityService activityService;
  late final FoodService foodService;
  late final CalendarService calendarService;

  void _setupServices() {
    // Initialize core services first
    authService = AuthService();
    dataService = DataService();

    // Initialize domain services (they depend on core services)
    exerciseService = ExerciseService();
    workoutService = WorkoutService();
    trainingSetService = TrainingSetService();
    activityService = ActivityService();
    foodService = FoodService();
    calendarService = CalendarService();
  }

  // Convenience getters for common operations
  bool get isLoggedIn => authService.isLoggedIn;
  String get userName => authService.userName;
  String get userEmail => authService.userEmail;

  // Initialize all services (call this at app startup)
  Future<void> initialize() async {
    await authService.initializeAuth();
  }

  // Notification method for data changes
  void notifyDataChanged() {
    //TODO: more helper methods or always referencing the services in the container directly ?
    dataService.notifyDataChanged();
  }

  // Clear all data (for settings/logout)
  Future<void> clearAllData() async {
    //TODO: is this method ever used and does it make sense?
    await Future.wait([
      exerciseService.clearExercises(),
      workoutService.clearWorkouts(),
      trainingSetService.clearTrainingSets(),
      foodService.clearFoodData(),
      calendarService.clearAllCalendarData(),
    ]);

    // Clear in-memory data
    dataService.clearInMemoryData();

    print('All data cleared from ServiceContainer');
  }

  // Bulk operations helper methods
  Future<List<Map<String, dynamic>>> createTrainingSetsBulk(
    List<Map<String, dynamic>> trainingSets,
  ) async {
    return await trainingSetService.createTrainingSetsBulk(trainingSets);
  }

  Future<List<Map<String, dynamic>>> createFoodsBulk(
    List<Map<String, dynamic>> foods,
  ) async {
    return await foodService.createFoodsBulk(foods);
  }

  // Analytics helper methods
  Future<Map<String, DateTime>> getLastTrainingDatesPerExercise() async {
    return await trainingSetService.getLastTrainingDatesPerExercise();
  }

  Future<Map<String, Map<String, dynamic>>> getLastTrainingDaysForExercises(
    List<String> exerciseNames,
  ) async {
    return await trainingSetService
        .getLastTrainingDaysForExercises(exerciseNames);
  }

  // Import/Export helper methods
  Future<int?> getExerciseIdByName(String exerciseName) async {
    return await exerciseService.getExerciseIdByName(exerciseName);
  }

  Future<String?> getExerciseNameById(int exerciseId) async {
    return await exerciseService.getExerciseNameById(exerciseId);
  }

  // Activity initialization helper
  Future<Map<String, dynamic>> initializeUserActivities() async {
    return await activityService.initializeUserActivities();
  }

  // Calendar convenience methods
  Future<Map<String, dynamic>> getCalendarDataForDate(DateTime date) async {
    return await calendarService.getCalendarDataForDate(date);
  }

  Future<Map<String, dynamic>> getCalendarDataForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await calendarService.getCalendarDataForRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Nutrition stats helper methods
  Future<Map<String, double>> getFoodLogStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await foodService.getFoodLogStats(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<Map<String, dynamic>>> getDailyFoodLogStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await foodService.getDailyFoodLogStats(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Map<String, dynamic>> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await activityService.getActivityStats(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
