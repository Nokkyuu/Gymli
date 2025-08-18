import 'dart:convert';

class ApiCache {
  static final ApiCache _instance = ApiCache._internal();
  factory ApiCache() => _instance;
  ApiCache._internal();

  final Map<String, CacheEntry> _cache = {};
  final Duration _defaultTtl = const Duration(minutes: 5);

  void put(String endpoint, dynamic data, {Duration? ttl}) {
    _cache[endpoint] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTtl,
    );
  }

  T? get<T>(String endpoint) {
    final entry = _cache[endpoint];

    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > entry.ttl) {
      _cache.remove(endpoint);
      return null;
    }

    return entry.data as T?;
  }

  void invalidate(String endpoint) {
    _cache.remove(endpoint);
  }

  void invalidateByPattern(String pattern) {
    _cache.removeWhere((key, value) => key.contains(pattern));
  }

  // Clear all cache - call this on login/logout
  void clear() {
    _cache.clear();
  }

  int get size => _cache.length;
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });
}
