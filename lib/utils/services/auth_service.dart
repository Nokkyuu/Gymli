import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../config/api_config.dart'; // Add this import

class AuthService {
  /// Singleton instance for AuthService
  /// getter:
  /// isLoggedIn: returns true if the user is logged in, false otherwise
  /// userName: returns the name of the logged-in user, or 'DefaultUser'
  /// userEmail: returns the email of the logged-in user, or an empty string
  /// authStateNotifier: a ValueNotifier that notifies listeners about authentication state changes
  static AuthService? _instance;

  factory AuthService() {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  AuthService._internal();

  Credentials? _credentials;
  bool get isLoggedIn => _credentials != null;
  String get userName => _credentials?.user.name ?? 'DefaultUser';
  String get userEmail => _credentials?.user.email ?? '';

  // Notifier for authentication state changes
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  void setCredentials(Credentials? credentials) {
    final wasLoggedIn = isLoggedIn;
    _credentials = credentials;
    final isNowLoggedIn = isLoggedIn;

    if (credentials?.accessToken != null && kDebugMode) {
      print("Access Token TYPE: ${credentials?.tokenType}");
      print("Access Token: ${credentials?.accessToken}");
    }
    // Update API config with access token
    ApiConfig.setAccessToken(credentials?.accessToken);

    if (!isLoggedIn) {
      // Clear stored auth state when logging out
      _clearStoredAuthState();
    } else {
      // Save auth state when logging in
      _saveAuthState(credentials!);
    }

    // Notify listeners if auth state changed
    if (wasLoggedIn != isNowLoggedIn) {
      authStateNotifier.value = isNowLoggedIn;
    }
  }

  void notifyAuthStateChanged() {
    /// Notifies listeners about authentication state changes
    authStateNotifier.value = !authStateNotifier.value;

    ///TODO: This is used as a force refresh,
    ///but maybe it should be changed into a different notifier to not
    ///interfere with the actual authentication state
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
          'givenName': credentials.user.givenName,
          'familyName': credentials.user.familyName,
          'middleName': credentials.user.middleName,
          'nickname': credentials.user.nickname,
          'preferredUsername': credentials.user.preferredUsername,
          'pictureUrl': credentials.user.pictureUrl?.toString(),
          'profileUrl': credentials.user.profileUrl?.toString(),
          'websiteUrl': credentials.user.websiteUrl?.toString(),
          'email': credentials.user.email,
          'isEmailVerified': credentials.user.isEmailVerified,
          'gender': credentials.user.gender,
          'birthdate': credentials.user.birthdate,
          'zoneinfo': credentials.user.zoneinfo,
          'locale': credentials.user.locale,
          'phoneNumber': credentials.user.phoneNumber,
          'isPhoneNumberVerified': credentials.user.isPhoneNumberVerified,
          'address': credentials.user.address,
          'updatedAt': credentials.user.updatedAt?.toIso8601String(),
          'customClaims': credentials.user.customClaims,
        }
      };
      await prefs.setString('auth_credentials', json.encode(authData));
      await prefs.setBool('is_logged_in', true);
      print('Auth state saved to persistent storage');
    } catch (e) {
      print('Error saving auth state: $e');
    }
  }

  // Load authentication state from persistent storage
  Future<Credentials?> loadStoredAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) {
        return null;
      }

      final authDataString = prefs.getString('auth_credentials');
      if (authDataString == null) {
        return null;
      }

      final authData = json.decode(authDataString);

      // Check if token is expired
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(authData['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        print('Stored credentials have expired');
        await _clearStoredAuthState();
        return null;
      }

      // Reconstruct credentials with only available UserProfile fields
      final userData = authData['user'];
      final user = UserProfile(
        sub: userData['sub'],
        name: userData['name'],
        givenName: userData['givenName'],
        familyName: userData['familyName'],
        middleName: userData['middleName'],
        nickname: userData['nickname'],
        preferredUsername: userData['preferredUsername'],
        pictureUrl: userData['pictureUrl'] != null
            ? Uri.parse(userData['pictureUrl'])
            : null,
        profileUrl: userData['profileUrl'] != null
            ? Uri.parse(userData['profileUrl'])
            : null,
        websiteUrl: userData['websiteUrl'] != null
            ? Uri.parse(userData['websiteUrl'])
            : null,
        email: userData['email'],
        isEmailVerified: userData['isEmailVerified'],
        gender: userData['gender'],
        birthdate: userData['birthdate'],
        zoneinfo: userData['zoneinfo'],
        locale: userData['locale'],
        phoneNumber: userData['phoneNumber'],
        isPhoneNumberVerified: userData['isPhoneNumberVerified'],
        address: userData['address'] != null
            ? Map<String, String>.from(userData['address'])
            : null,
        updatedAt: userData['updatedAt'] != null
            ? DateTime.parse(userData['updatedAt'])
            : null,
        customClaims: userData['customClaims'] != null
            ? Map<String, dynamic>.from(userData['customClaims'])
            : null,
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

      print('Auth state loaded from persistent storage for user: ${user.name}');
      return credentials;
    } catch (e) {
      print('Error loading stored auth state: $e');
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
      print('Stored auth state cleared');
    } catch (e) {
      print('Error clearing stored auth state: $e');
    }
  }

  // Initialize with stored credentials if available
  Future<void> initializeAuth() async {
    final storedCredentials = await loadStoredAuthState();
    if (storedCredentials != null) {
      _credentials = storedCredentials;
      // Set the access token in ApiConfig
      ApiConfig.setAccessToken(storedCredentials.accessToken);
      authStateNotifier.value = true;
    }
  }
}
