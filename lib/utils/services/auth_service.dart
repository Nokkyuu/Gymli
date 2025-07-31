/// service for handling authentication using Auth0.
/// It initializes the Auth0 client, manages user credentials, and provides methods to update authentication state
/// and listen for changes in authentication status.
///
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';
import 'app_initializer.dart';

class AuthService extends ChangeNotifier {
  Credentials? _credentials;
  late Auth0Web _auth0;
  final UserService _userService;

  AuthService(this._userService);

  Credentials? get credentials => _credentials;
  Auth0Web get auth0 => _auth0;

  Future<void> initialize() async {
    _auth0 = AppInitializer.getAuth0();

    // Set up Auth0 callback
    _auth0.onLoad().then((credentials) {
      _setCredentials(credentials);
    }).catchError((error) {
      print('Auth0 onLoad error: $error');
    });

    // Try to load stored auth state
    await _loadStoredAuthState();
  }

  Future<void> _loadStoredAuthState() async {
    try {
      final credentials = await _userService.loadStoredAuthState();
      if (credentials != null) {
        _setCredentials(credentials);
        print('Loaded stored authentication state successfully');
      }
    } catch (e) {
      print('Error loading stored authentication state: $e');
    }
  }

  void _setCredentials(Credentials? credentials) {
    _credentials = credentials;
    _userService.setCredentials(credentials);
    notifyListeners();
  }

  void updateCredentials(Credentials? credentials) {
    _setCredentials(credentials);
  }
}
