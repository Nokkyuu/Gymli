// Create a new file: lib/config/api_config.dart
import 'dart:io';

class ApiConfig {
  static String? _apiKey;

  static String? get apiKey => _apiKey;

  static void initialize() {
    // For web builds, the API key should be injected at build time
    // For development, use environment variable
    _apiKey = const String.fromEnvironment('GYMLI_API_KEY');

    if (_apiKey == null || _apiKey!.isEmpty) {
      // Fallback to runtime environment (for local development)
      _apiKey = Platform.environment['GYMLI_API_KEY'];
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key not found. Please configure GYMLI_API_KEY');
    }
  }
}
