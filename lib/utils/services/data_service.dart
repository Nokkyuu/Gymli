import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class DataService {
  /// Singleton instance for DataService
  static DataService? _instance;

  factory DataService() {
    _instance ??= DataService._internal();
    return _instance!;
  }

  DataService._internal();

  final AuthService _authService = AuthService();

  // Getters that delegate to AuthService
  bool get isLoggedIn => _authService.isLoggedIn;
  String get userName => _authService.userName;
  String get userEmail => _authService.userEmail;
  ValueNotifier<bool> get authStateNotifier => _authService.authStateNotifier;

  // In-memory storage for non-authenticated users
  Map<String, dynamic> _inMemoryData = {
    'exercises': <Map<String, dynamic>>[],
    'workouts': <Map<String, dynamic>>[],
    'trainingSets': <Map<String, dynamic>>[],
    'workoutUnits': <Map<String, dynamic>>[],
    'groups': <Map<String, dynamic>>[],
    'activities': <Map<String, dynamic>>[],
    'activityLogs': <Map<String, dynamic>>[],
    'foods': <Map<String, dynamic>>[],
    'foodLogs': <Map<String, dynamic>>[],
    'calendarNotes': <Map<String, dynamic>>[],
    'calendarWorkouts': <Map<String, dynamic>>[],
    'periods': <Map<String, dynamic>>[],
  };

  // Generic data access methods
  List<dynamic> getInMemoryData(String dataType) {
    return _inMemoryData[dataType] as List<dynamic>? ?? [];
  }

  void setInMemoryData(String dataType, List<dynamic> data) {
    _inMemoryData[dataType] = data;
  }

  void addToInMemoryData(String dataType, Map<String, dynamic> item) {
    final list = _inMemoryData[dataType] as List<dynamic>? ?? [];
    list.add(item);
    _inMemoryData[dataType] = list;
  }

  void removeFromInMemoryData(String dataType, bool Function(dynamic) test) {
    final list = _inMemoryData[dataType] as List<dynamic>? ?? [];
    list.removeWhere(test);
    _inMemoryData[dataType] = list;
  }

  void updateInMemoryData(
      String dataType, int id, Map<String, dynamic> updates) {
    final list = _inMemoryData[dataType] as List<dynamic>? ?? [];
    final index = list.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      list[index] = {...list[index], ...updates};
    }
  }

  // Generate fake ID for offline mode
  int generateFakeId(String dataType) {
    final list = _inMemoryData[dataType] as List<dynamic>? ?? [];
    if (list.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch;
    }

    // Find the highest existing ID and increment
    int maxId = 0;
    for (var item in list) {
      if (item['id'] is int && item['id'] > maxId) {
        maxId = item['id'];
      }
    }
    return maxId > 0 ? maxId + 1 : DateTime.now().millisecondsSinceEpoch;
  }

  void clearInMemoryData() {
    _inMemoryData = {
      'exercises': <Map<String, dynamic>>[],
      'workouts': <Map<String, dynamic>>[],
      'trainingSets': <Map<String, dynamic>>[],
      'workoutUnits': <Map<String, dynamic>>[],
      'groups': <Map<String, dynamic>>[],
      'activities': <Map<String, dynamic>>[],
      'activityLogs': <Map<String, dynamic>>[],
      'foods': <Map<String, dynamic>>[],
      'foodLogs': <Map<String, dynamic>>[],
      'calendarNotes': <Map<String, dynamic>>[],
      'calendarWorkouts': <Map<String, dynamic>>[],
      'periods': <Map<String, dynamic>>[],
    };
  }

  void clearSpecificInMemoryData(String dataType) {
    _inMemoryData[dataType] = <Map<String, dynamic>>[];
  }

  // Notification methods
  void notifyDataChanged() {
    _authService.notifyAuthStateChanged();
  }

  // Auth-related methods that delegate to AuthService
  Future<void> initializeAuth() async {
    await _authService.initializeAuth();
  }

  void setCredentials(dynamic credentials) {
    _authService.setCredentials(credentials);

    if (!isLoggedIn) {
      // Clear in-memory data when logging out
      clearInMemoryData();
    }
  }

  // Helper method to check if we should use API or in-memory data
  bool shouldUseInMemoryData(String dataType) {
    if (isLoggedIn) {
      return false;
    }

    final inMemoryData = getInMemoryData(dataType);
    return inMemoryData.isNotEmpty;
  }

  // Generic method for handling API vs in-memory data retrieval
  Future<List<dynamic>> getData(
    String dataType,
    Future<List<dynamic>> Function() apiCall,
    Future<List<dynamic>> Function() fallbackApiCall,
  ) async {
    if (isLoggedIn) {
      return await apiCall();
    } else {
      // When not logged in, prioritize in-memory data if it exists
      final inMemoryData = getInMemoryData(dataType);
      if (inMemoryData.isNotEmpty) {
        return inMemoryData;
      } else {
        // Only try API if no in-memory data exists
        try {
          return await fallbackApiCall();
        } catch (e) {
          // If API fails, return empty in-memory data
          return inMemoryData;
        }
      }
    }
  }

  // Generic method for handling API vs in-memory data creation
  Future<Map<String, dynamic>> createData(
    String dataType,
    Map<String, dynamic> data,
    Future<Map<String, dynamic>> Function() apiCall,
  ) async {
    if (isLoggedIn) {
      return await apiCall();
    } else {
      // For non-authenticated users, store in memory only
      final item = {
        'id': generateFakeId(dataType),
        'user_name': 'DefaultUser',
        ...data,
      };
      addToInMemoryData(dataType, item);
      return item;
    }
  }

  // Generic method for handling API vs in-memory data updates
  Future<void> updateData(
    String dataType,
    int id,
    Map<String, dynamic> updates,
    Future<void> Function() apiCall,
  ) async {
    if (isLoggedIn) {
      await apiCall();
    } else {
      updateInMemoryData(dataType, id, updates);
    }
  }

  // Generic method for handling API vs in-memory data deletion
  Future<void> deleteData(
    String dataType,
    int id,
    Future<void> Function() apiCall,
  ) async {
    if (isLoggedIn) {
      await apiCall();
    } else {
      removeFromInMemoryData(dataType, (item) => item['id'] == id);
    }
  }
}
