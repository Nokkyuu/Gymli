/// Base API utilities and common functions
///
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show compute, kDebugMode;
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'api_cache.dart';

const bool useCache = true; // Set to false to disable caching
// Main API base URL - Azure hosted backend service
const String baseUrl = kDebugMode
    //? 'http://127.0.0.1:8000'
    ? 'https://gymliapi-dev-f6c3gzfafgazanbf.germanywestcentral-01.azurewebsites.net'
    : 'https://gymliapi-gyg0ardqh5dadaba.germanywestcentral-01.azurewebsites.net';

final http.Client httpClient = http.Client();
final ApiCache cache = ApiCache();
Map<String, String> get defaultHeaders => ApiConfig.getHeaders();

Future<T> getData<T>(String url) async {
  // Check cache first
  if (useCache) {
    final cached = cache.get<T>(url);
    if (cached != null) {
      if (kDebugMode) {
        print('!!!!!!API CACHE ACTIVE!!!!!!! Cache hit: $url');
      }
      return cached;
    }
  }

  try {
    final response = await httpClient
        .get(Uri.parse('$baseUrl/$url'), headers: defaultHeaders)
        .timeout(const Duration(seconds: 30)); // Add timeout

    if (response.statusCode == 200 || response.statusCode == 204) {
      // Parse JSON in isolate for large responses
      final decoded = await _parseJsonInIsolate(response.body);

      // Cache the result
      if (useCache) {
        cache.put(url, decoded);
      }

      return decoded;
    } else {
      throw Exception("Failed to fetch $url: ${response.statusCode}");
    }
  } catch (e) {
    rethrow;
  }
}

// Add JSON parsing in isolate
Future<dynamic> _parseJsonInIsolate(String jsonString) async {
  if (jsonString.length > 1000) {
    // Parse large JSON in isolate to avoid blocking main thread
    return await compute(json.decode, jsonString);
  } else {
    return json.decode(jsonString);
  }
}

Future deleteData(String url) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/$url'),
    headers: defaultHeaders,
  );
  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception('Failed to delete');
  }

  // Invalidate related cache entries
  invalidateCacheForMutation(url);

  return response;
}

Future updateData<T>(String url, T data) async {
  final response = await http.put(Uri.parse('$baseUrl/$url'),
      headers: defaultHeaders, body: json.encode(data));
  if (response.statusCode != 200) {
    throw Exception('Failed to update');
  }

  // Invalidate related cache entries
  invalidateCacheForMutation(url);

  return response;
}

Future createData<T>(String url, T data) async {
  final response = await http.post(Uri.parse('$baseUrl/$url'),
      headers: defaultHeaders, body: json.encode(data));
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to create');
  }

  // Invalidate related cache entries
  invalidateCacheForMutation(url);

  return response.body;
}

void invalidateCacheForMutation(String url) {
  if (kDebugMode) {
    print('DEBUG API: Invalidating cache for $url');
  }
  // Smart cache invalidation based on the endpoint
  if (url.contains('exercises')) {
    cache.invalidateByPattern('exercises');
  } else if (url.contains('workouts')) {
    cache.invalidateByPattern('workouts');
    cache.invalidateByPattern('workout_units');
  } else if (url.contains('training_sets')) {
    cache.invalidateByPattern('training_sets');
  } else if (url.contains('activities')) {
    cache.invalidateByPattern('activities');
    cache.invalidateByPattern('activity_logs');
  } else if (url.contains('food')) {
    cache.invalidateByPattern('foods');
    cache.invalidateByPattern('food_logs');
  } else if (url.contains('calendar')) {
    cache.invalidateByPattern('calendar');
    cache.invalidateByPattern('periods');
  } else {
    // Fallback: clear everything for unknown endpoints
    cache.clear();
  }
}

// Add this function to be called when user logs in
void clearApiCache() {
  cache.clear();
}
