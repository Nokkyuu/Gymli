/// service for handling authentication using Auth0.
/// It initializes the Auth0 client, manages user credentials, and provides methods to update authentication state
/// and listen for changes in authentication status.
///
library;

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
//import 'user_service.dart';
import 'app_initializer.dart';
import 'package:Gymli/utils/services/service_container.dart';

class Auth0Service extends ChangeNotifier {
  /// Class for managing authentication using Auth0.
  /// It initializes the Auth0 client, manages user credentials, and provides methods to update authentication
  /// getters:
  /// - [credentials]: Returns the current user credentials.
  /// - [auth0]: Returns the Auth0 client instance.
  /// methods:
  /// - [initialize]: Initializes the Auth0 client and loads stored authentication state.
  /// - [updateCredentials]: Updates the current user credentials and notifies listeners.
  /// - [dispose]: Cleans up resources when the service is no longer needed.
  Credentials? _credentials;
  late Auth0Web _auth0;
  final ServiceContainer _serviceContainer;
  //final UserService _userService;

  Auth0Service(this._serviceContainer);

  Credentials? get credentials => _credentials;
  Auth0Web get auth0 => _auth0;

  Future<void> initialize() async {
    _auth0 = AppInitializer.getAuth0();

    // Set up Auth0 callback
    _auth0.onLoad().then((credentials) {
      _setCredentials(credentials);
    }).catchError((error) {
      if (kDebugMode) {
        print('Auth0 onLoad error: $error');
      }
    });

    // Try to load stored auth state
    await _loadStoredAuthState();
  }

  Future<void> _loadStoredAuthState() async {
    try {
      final credentials =
          await _serviceContainer.authService.loadStoredAuthState();
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

  void _setCredentials(Credentials? credentials) {
    _credentials = credentials;

    // Single source of truth: let AuthService handle all credential setting
    // This will also handle ApiConfig.setAccessToken internally
    _serviceContainer.authService.setCredentials(credentials);

    if (kDebugMode) {
      print(
          'Auth0Service: Credentials ${credentials != null ? "set" : "cleared"}');
      if (credentials != null) {
        print(
            'Auth0Service: Token preview: ${credentials.accessToken.substring(0, 20)}...');
      }
    }

    notifyListeners();
  }

  void updateCredentials(Credentials? credentials) {
    ///exposure of _setCredentials method to allow updating credentials from outside
    _setCredentials(credentials);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
