import 'package:Gymli/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import '../config/app_router.dart';
import '../utils/services/service_container.dart';
import '../utils/services/auth0_service.dart';

class LandingChoiceScreen extends StatefulWidget {
  const LandingChoiceScreen({super.key});

  @override
  State<LandingChoiceScreen> createState() => _LandingChoiceScreenState();
}

class _LandingChoiceScreenState extends State<LandingChoiceScreen> {
  final _container = ServiceContainer();
  late Auth0Service _authService;
  bool _loading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _authService = Auth0Service(_container);
    await _authService.initialize();

    // Listen to auth changes
    _authService.addListener(_onAuthChanged);

    // Set initialization flag and trigger rebuild
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }

    _checkForStoredCredentials();
  }

  Future<void> _onAuthChanged() async {
    if (_authService.credentials != null) {
      // No need to call initializeAuth again - credentials are already set
      // Just verify the token is properly set and proceed
      if (_isTokenProperlySet()) {
        _proceedToMainApp();
      } else {
        print('Warning: Credentials exist but token not set in ApiConfig');
      }
    }
  }

  Future<void> _checkForStoredCredentials() async {
    if (!_isInitialized) return;

    setState(() => _loading = true);

    // The Auth0Service.initialize() already called loadStoredAuthState
    // So we just need to check if we're logged in with a valid token
    if (_container.authService.isLoggedIn && _isTokenProperlySet()) {
      _proceedToMainApp();
      return;
    }
    setState(() => _loading = false);
  }

  bool _isTokenProperlySet() {
    final hasToken = ApiConfig.accessToken != null &&
        ApiConfig.accessToken!.isNotEmpty &&
        ApiConfig.accessToken != 'DEBUG_MODE_NO_API_KEY' &&
        ApiConfig.accessToken != 'DEBUG_MODE_ERROR';

    return hasToken;
  }

  void _proceedToMainApp() {
    context.go(AppRouter.main);
  }

  Future<void> _login() async {
    if (!_isInitialized) {
      print('Auth0 not initialized');
      return;
    }

    setState(() => _loading = true);
    try {
      const redirectUrl =
          kDebugMode ? 'http://localhost:3000' : 'https://gymli.brgmnn.de/';

      // Use the same pattern as NavigationDrawer
      await _authService.auth0.loginWithRedirect(redirectUrl: redirectUrl);

      // The app will be redirected and reloaded, credentials handled by Auth0Service.onLoad
    } catch (e) {
      setState(() => _loading = false);
      print('Login error: $e');
    }
  }

  // void _openDemoMode() {
  //   _container.authService.setCredentials(null); // Ensure logged out
  //   Navigator.of(context).pushReplacement(
  //     MaterialPageRoute(
  //       builder: (_) => const MainAppWidget(),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    if (_isInitialized) {
      _authService.removeListener(_onAuthChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while services are initializing
    if (!_isInitialized || _loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            child: Container(
              width: 400,
              height: 500,
              padding: const EdgeInsets.all(32.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background image with reduced opacity
                  Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'images/Icon-App_3_Darkmode.png'
                          : 'images/Icon-App_3.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Content overlay
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome to',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.color
                                      ?.withValues(alpha: 0.8),
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gymli',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Son of Gain,',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Login'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _login,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: OutlinedButton.icon(
                      //     icon: const Icon(Icons.visibility_off),
                      //     label: const Text('Demo Mode'),
                      //     style: OutlinedButton.styleFrom(
                      //       padding: const EdgeInsets.symmetric(vertical: 16),
                      //     ),
                      //     onPressed: _openDemoMode,
                      //   ),
                      // ),
                      const SizedBox(height: 24),
                      Text(
                        'Ready to join the fellowship of the Gym?',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
