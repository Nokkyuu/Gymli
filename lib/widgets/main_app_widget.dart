///main app widget, combines the navigation drawer and the landing screen
///main app bar with the app logo and title is also included
///handles user authentication and theme management

import 'package:Gymli/utils/api/api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:get_it/get_it.dart';

import '../screens/landing_screen.dart';
import '../utils/themes/themes.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import '../utils/info_dialogues.dart';

import '../utils/services/theme_service.dart';
import 'navigation_drawer.dart';
import '../utils/services/authentication_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainAppWidget extends ConsumerStatefulWidget {
  const MainAppWidget({super.key});
  @override
  ConsumerState<MainAppWidget> createState() => _MainAppWidgetState();
}

class _MainAppWidgetState extends ConsumerState<MainAppWidget> {
  String? _drawerImage;
  late AuthenticationService _authService;
  final container = GetIt.I<TempService>();
  final exerciseService = GetIt.I<ExerciseService>();
  bool _isInitialized = false; // Add this flag

//drawer images to circles through, without file extensions because they will be added dynamicly and switch for dark mode
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
    _authService = GetIt.I<AuthenticationService>();
    await _authService.initialize();
    _authService.addListener(_onAuthChanged);

    // Set initialization flag and trigger rebuild
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
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
    GetIt.I<AuthenticationService>().notifyAuthStateChanged();
  }

  void _getExerciseList() async {
    // ... existing exercise loading logic
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while services are initializing
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    // THEME: reaktiver Zugriff via Riverpod
    final isDarkMode = ref.watch(isDarkModeProvider);
    final seedColor = ref.watch(seedColorProvider);
    final mode = ref.watch(themeModeProvider);

    // return MultiProvider(
    // providers: [
    //   ChangeNotifierProvider.value(value: _authService),
    // ],
    // child:
    // Consumer<Auth0Service>(
    //   builder: (context, authService, _) {
    //     // Get ThemeService from the parent context
    //     final themeService = Provider.of<ThemeService>(context);

    //     if (authService.auth0 == null) {
    //       return const Scaffold(
    //         body: Center(
    //           child: CircularProgressIndicator(),
    //         ),
    //       );
    //     }
    return Scaffold(
      appBar: _buildAppBar(context, isDarkMode),
      body: LandingScreen(
          onPhaseColorChanged: (c) => ref.themeCtrl.setSeedColor(c)),
      drawer: AppDrawer(
        credentials: _authService.credentials,
        auth0: _authService.auth0,
        drawerImage: _drawerImage,
        drawerImages: drawerImages,
        isDarkMode: isDarkMode,
        mode: mode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light, // falls du Brightness erwartest
        onModeChanged: (b) => ref.themeCtrl.setThemeMode(
          b == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        ),
        //onCredentialsChanged: _authService.setCredentials(null),
        onReloadUserData: _reloadUserData,
        getExerciseList: _getExerciseList,
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          setState(() {
            _drawerImage = drawerImages[Random().nextInt(drawerImages.length)];
          });
        }
      },
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
}
