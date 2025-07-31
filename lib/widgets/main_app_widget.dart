///main app widget, combines the navigation drawer and the landing screen
///main app bar with the app logo and title is also included
///handles user authentication and theme management

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../screens/landing_screen.dart';
import '../utils/themes/themes.dart';
import '../utils/services/user_service.dart';
import '../utils/info_dialogues.dart';
import '../utils/services/auth_service.dart';
import '../utils/services/theme_service.dart';
import 'navigation_drawer.dart';

class MainAppWidget extends StatefulWidget {
  const MainAppWidget({super.key});

  @override
  State<MainAppWidget> createState() => _MainAppWidgetState();
}

class _MainAppWidgetState extends State<MainAppWidget> {
  String? _drawerImage;
  late AuthService _authService;
  late ThemeService _themeService;
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
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _authService = AuthService(userService);
    _themeService = ThemeService();

    await _themeService.loadThemePreference();
    await _authService.initialize();

    // Listen to auth changes for reloading user data
    _authService.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_authService.credentials != null) {
      _reloadUserData();
    }
  }

  Future<void> _reloadUserData() async {
    _getExerciseList();
    setState(() {}); // Trigger rebuild
    await Future.delayed(const Duration(milliseconds: 100));
    userService.notifyAuthStateChanged();
  }

  void _getExerciseList() async {
    // ... existing exercise loading logic
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _themeService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          final ThemeData themeData =
              buildAppTheme(themeService.mode, themeService.primaryColor);

          return Theme(
            data: themeData,
            child: Consumer<AuthService>(
              builder: (context, authService, _) {
                return Scaffold(
                  appBar: _buildAppBar(context, themeService.isDarkMode),
                  body: LandingScreen(
                      onPhaseColorChanged: themeService.setPrimaryColor),
                  drawer: AppDrawer(
                    credentials: authService.credentials,
                    auth0: authService.auth0,
                    userService: userService,
                    drawerImage: _drawerImage,
                    drawerImages: drawerImages,
                    isDarkMode: themeService.isDarkMode,
                    mode: themeService.mode,
                    onModeChanged: themeService.setMode,
                    onCredentialsChanged: authService.updateCredentials,
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
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDarkMode) {
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
  // ... rest of the methods remain similar but simplified
}
