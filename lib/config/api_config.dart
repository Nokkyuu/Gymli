///Config file for API key management
///
///This file handles the API key for the app, for the different build environments.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String? _apiKey;
  static String? _accessToken;

  static String? get apiKey => _apiKey;
  static String? get accessToken => _accessToken;

  static void initialize() {
    try {
      // For web builds, use compile-time constant
      if (kIsWeb) {
        _apiKey = const String.fromEnvironment('GYMLI_API_KEY');
      } else {
        // For mobile/desktop, use runtime environment variable
        _apiKey = Platform.environment['GYMLI_API_KEY'];
      }

      // If no API key found, provide a fallback or throw an error
      if (_apiKey == null || _apiKey!.isEmpty) {
        if (kDebugMode) {
          // In debug mode, provide a warning but don't crash
          print('WARNING: GYMLI_API_KEY not found. API calls may fail.');
          print(
              'Please set the GYMLI_API_KEY environment variable or use --dart-define=GYMLI_API_KEY=your_key');
          // Set a placeholder to prevent null errors
          _apiKey = 'DEBUG_MODE_NO_API_KEY';
        } else {
          throw Exception('API key not found. Please configure GYMLI_API_KEY');
        }
      } else {
        print('API configuration initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing API config: $e');
        _apiKey = 'DEBUG_MODE_ERROR';
      } else {
        rethrow;
      }
    }
  }

  static void setAccessToken(String? token) {
    _accessToken = token;
  }

  static Map<String, String> getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_apiKey != null) {
      headers['X-API-Key'] = _apiKey!;
    } else {
      if (kDebugMode) {
        print('WARNING: No API key available!');
      }
    }
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  static bool get isConfigured =>
      _apiKey != null &&
      _apiKey != 'DEBUG_MODE_NO_API_KEY' &&
      _apiKey != 'DEBUG_MODE_ERROR';
}
