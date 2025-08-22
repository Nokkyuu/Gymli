import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../config/api_config.dart';
import '../api/api_export.dart';

class AuthenticationService extends ChangeNotifier {
  // Auth0 Configuration
  static const String _auth0Domain = 'dev-aqz5a2g54oer01tk.us.auth0.com';
  static const String _auth0ClientId = 'MAxJUti2T7TkLagzT7SdeEzCTZsHyuOa';

  // Private fields
  Credentials? _credentials;
  late Auth0Web _auth0;
  bool _isInitialized = false;

  // Notifier for authentication state changes
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  // Getters
  bool get isLoggedIn => _credentials != null;
  String get userName => _credentials?.user.name ?? 'DefaultUser';
  Credentials? get credentials => _credentials;
  Auth0Web get auth0 => _auth0;
  bool get isInitialized => _isInitialized;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Auth0
    _auth0 = Auth0Web(_auth0Domain, _auth0ClientId);

    // Set up Auth0 callback
    _auth0.onLoad().then((credentials) {
      if (credentials != null && credentials.accessToken.isNotEmpty) {
        _setCredentials(credentials);
      }
    }).catchError((error) {
      if (kDebugMode) {
        print('Auth0 onLoad error: $error');
      }
    });

    // Try to load stored auth state
    await _loadStoredAuthState();

    _isInitialized = true;
  }

  // Set credentials and update all related state
  void setCredentials(Credentials? credentials) {
    final wasLoggedIn = isLoggedIn;
    _credentials = credentials;
    final isNowLoggedIn = _credentials != null;

    // Update API configuration
    ApiConfig.setAccessToken(credentials?.accessToken);
    clearApiCache();

    // Handle persistent storage
    if (!isNowLoggedIn) {
      _clearStoredAuthState();
    } else {
      _saveAuthState(credentials!);
    }

    // Notify listeners if state changed
    if (wasLoggedIn != isNowLoggedIn) {
      authStateNotifier.value = isNowLoggedIn;
      notifyListeners();
    }

    if (kDebugMode) {
      print(
          'AuthenticationService: Credentials ${credentials != null ? "set" : "cleared"}');
      if (credentials != null) {
        print(
            'AuthenticationService: Token preview: ${credentials.accessToken.substring(0, 20)}...');
      }
    }
  }

  // Private method for internal credential setting
  void _setCredentials(Credentials? credentials) {
    setCredentials(credentials);
  }

  // Force refresh authentication state (for UI updates)
  // void notifyAuthStateChanged() {
  //   authStateNotifier.value = isLoggedIn;
  // }

  // Perform login with Auth0
  Future<void> login() async {
    if (!_isInitialized) {
      throw StateError('AuthenticationService not initialized');
    }

    const redirectUrl =
        kDebugMode ? 'http://localhost:3000' : 'https://gymli.brgmnn.de/';

    await _auth0.loginWithRedirect(redirectUrl: redirectUrl);
  }

  // Perform logout
  Future<void> logout() async {
    await _clearStoredAuthState();
    setCredentials(null);
  }

  // Load stored authentication state
  Future<void> _loadStoredAuthState() async {
    try {
      final credentials = await loadStoredAuthState();
      if (credentials != null) {
        _setCredentials(credentials);
        if (kDebugMode) {
          print('Loaded stored authentication state successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading stored authentication state: $e');
      }
    }
  }

  // Save authentication state to persistent storage
  Future<void> _saveAuthState(Credentials credentials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authData = {
        'accessToken': credentials.accessToken,
        'idToken': credentials.idToken,
        'refreshToken': credentials.refreshToken,
        'tokenType': credentials.tokenType,
        'expiresAt': credentials.expiresAt.millisecondsSinceEpoch,
        'scopes': credentials.scopes.toList(),
        'user': {
          'sub': credentials.user.sub,
          'name': credentials.user.name,
        }
      };
      await prefs.setString('auth_credentials', json.encode(authData));
      await prefs.setBool('is_logged_in', true);
      if (kDebugMode) print('Auth state saved to persistent storage');
    } catch (e) {
      if (kDebugMode) print('Error saving auth state: $e');
    }
  }

  // Load authentication state from persistent storage
  Future<Credentials?> loadStoredAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) return null;

      final authDataString = prefs.getString('auth_credentials');
      if (authDataString == null) return null;

      final authData = json.decode(authDataString);

      // Check if token is expired
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(authData['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        if (kDebugMode) print('Stored credentials have expired');
        await _clearStoredAuthState();
        return null;
      }

      // Reconstruct credentials with minimal user data
      final userData = authData['user'];
      final user = UserProfile(
        sub: userData['sub'],
        name: userData['name'],
      );

      final credentials = Credentials(
        accessToken: authData['accessToken'],
        idToken: authData['idToken'],
        refreshToken: authData['refreshToken'],
        tokenType: authData['tokenType'],
        expiresAt: expiresAt,
        scopes: Set<String>.from(authData['scopes'] ?? []),
        user: user,
      );

      if (kDebugMode)
        print(
            'Auth state loaded from persistent storage for user: ${user.name}');
      return credentials;
    } catch (e) {
      if (kDebugMode) print('Error loading stored auth state: $e');
      await _clearStoredAuthState();
      return null;
    }
  }

  // Clear stored authentication state
  Future<void> _clearStoredAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_credentials');
      await prefs.setBool('is_logged_in', false);
      if (kDebugMode) print('Stored auth state cleared');
    } catch (e) {
      if (kDebugMode) print('Error clearing stored auth state: $e');
    }
  }

  @override
  void dispose() {
    authStateNotifier.dispose();
    super.dispose();
  }
}
