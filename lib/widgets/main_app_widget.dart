import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'dart:math';

import '../screens/landing_screen.dart';
import '../utils/themes/themes.dart';
import '../utils/user/user_service.dart';
import '../utils/info_dialogues.dart';
import '../utils/services/app_initializer.dart';
import '../config/api_config.dart';
import '../utils/globals.dart' as globals;
import 'navigation_drawer.dart';

class MainAppWidget extends StatefulWidget {
  const MainAppWidget({super.key});

  @override
  State<MainAppWidget> createState() => _MainAppWidgetState();
}

class _MainAppWidgetState extends State<MainAppWidget> {
  String? _drawerImage;
  Brightness mode = Brightness.light;
  Color primaryColor = ThemeColors.themeOrange;
  bool isDarkMode = false;
  Credentials? _credentials;
  late Auth0Web auth0;
  final userService = UserService();

  final List<String> drawerImages = [
    'images/drawerlogo/gymli-biceps',
    'images/drawerlogo/gymli-curl1',
    'images/drawerlogo/gymli-curl2',
    'images/drawerlogo/gymli-squat',
    'images/drawerlogo/gymli-face',
    'images/drawerlogo/gymli-row',
    'images/drawerlogo/gymli-row2',
    'images/drawerlogo/gymli-pullup',
  ];

  @override
  void initState() {
    super.initState();
    _initializeUI();
  }

  Future<void> _initializeUI() async {
    // Get Auth0 instance from initializer
    auth0 = AppInitializer.getAuth0();

    // Load theme preference
    await loadThemePreference();

    // Set up Auth0 callback
    auth0.onLoad().then((final credentials) {
      if (mounted) {
        setState(() {
          _credentials = credentials;
          userService.setCredentials(credentials);
          _reloadUserData();
        });
      }
    }).catchError((error) {
      print('Auth0 onLoad error: $error');
    });

    // Try to load stored auth state
    await _loadStoredAuthState();
  }

  Future<void> _loadStoredAuthState() async {
    try {
      final credentials = await userService.loadStoredAuthState();
      if (credentials != null && mounted) {
        setState(() {
          _credentials = credentials;
        });
        userService.setCredentials(credentials);
        print('Loaded stored authentication state successfully');
        _reloadUserData();
      }
    } catch (e) {
      print('Error loading stored authentication state: $e');
    }
  }

  Future<void> _reloadUserData() async {
    // Refresh exercise list
    _getExerciseList();

    // Force refresh of the landing screen by rebuilding the entire app
    setState(() {
      // This will trigger a rebuild and the landing screen will reload its data
    });

    // Small delay to ensure state is updated before notifying listeners
    await Future.delayed(const Duration(milliseconds: 100));

    // Notify all listeners that auth state has changed
    userService.notifyAuthStateChanged();
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    if (mounted) {
      setState(() {
        mode = isDark ? Brightness.dark : Brightness.light;
      });
    }
  }

  void setPrimaryColor(Color color) {
    setState(() {
      primaryColor = color;
    });
  }

  // Method to load exercise list (from original main.dart)
  void _getExerciseList() async {
    try {
      if (!ApiConfig.isConfigured) {
        print('API not configured, skipping exercise list load');
        globals.exerciseList = [];
        return;
      }

      final exercises = await userService.getExercises();
      globals.exerciseList =
          exercises.map<String>((e) => e['name'] as String).toList();
      print('Exercise list loaded: ${globals.exerciseList.length} exercises');
    } catch (e) {
      print('Error loading exercise list: $e');
      globals.exerciseList = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = buildAppTheme(mode, primaryColor);

    return Theme(
      data: themeData,
      child: Builder(
        builder: (context) {
          isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            appBar: _buildAppBar(context),
            body: LandingScreen(onPhaseColorChanged: setPrimaryColor),
            drawer: AppDrawer(
              credentials: _credentials,
              auth0: auth0,
              userService: userService,
              drawerImage: _drawerImage,
              drawerImages: drawerImages,
              isDarkMode: isDarkMode,
              mode: mode,
              onModeChanged: (newMode) => _onModeChanged(newMode),
              onCredentialsChanged: (credentials) =>
                  _onCredentialsChanged(credentials),
              onReloadUserData: _reloadUserData,
              getExerciseList: _getExerciseList,
            ),
            onDrawerChanged: (isOpened) {
              if (isOpened) {
                setState(() {
                  _drawerImage =
                      drawerImages[Random().nextInt(drawerImages.length)];
                });
              }
            },
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 50.0),
            child: Image.asset(
              isDarkMode
                  ? 'images/Icon-App_3_Darkmode.png'
                  : 'images/Icon-App_3.png',
              fit: BoxFit.contain,
              height: 50,
            ),
          ),
          const Text('Gymli', textAlign: TextAlign.center),
        ],
      ),
      actions: [
        buildInfoButton(
            'About Gymli', context, () => showInfoDialogMain(context)),
      ],
      centerTitle: true,
    );
  }

  Future<void> _onModeChanged(Brightness newMode) async {
    setState(() {
      mode = newMode;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', mode == Brightness.dark);
  }

  void _onCredentialsChanged(Credentials? credentials) {
    setState(() {
      _credentials = credentials;
    });
    userService.setCredentials(credentials);
    _reloadUserData();
  }
}
