import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:go_router/go_router.dart';
import 'package:Gymli/utils/services/service_container.dart';
import 'package:Gymli/config/app_router.dart';
import '../../utils/themes/themes.dart';
import '../../utils/globals.dart' as globals;

class AppDrawer extends StatefulWidget {
  final Credentials? credentials;
  final Auth0Web auth0;
  final ServiceContainer container;
  final String? drawerImage;
  final List<String> drawerImages;
  final bool isDarkMode;
  final Brightness mode;
  final Function(Brightness) onModeChanged;
  final Function(Credentials?) onCredentialsChanged;
  final VoidCallback onReloadUserData;
  final Function() getExerciseList;

  const AppDrawer({
    super.key,
    required this.credentials,
    required this.auth0,
    required this.container,
    required this.drawerImage,
    required this.drawerImages,
    required this.isDarkMode,
    required this.mode,
    required this.onModeChanged,
    required this.onCredentialsChanged,
    required this.onReloadUserData,
    required this.getExerciseList,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    const redirectUrl =
        kDebugMode ? 'http://localhost:3000' : 'https://gymli.brgmnn.de/';
    final imageToShow = widget.drawerImage ?? widget.drawerImages[0];

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: ThemeColors.themeOrange,
            ),
            child: Image(
              image: AssetImage(
                widget.isDarkMode
                    ? '$imageToShow-dark.png'
                    : '$imageToShow.png',
              ),
            ),
          ),
          Text(
            "Gymli Gainson",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Start'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.main);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Exercise Setup'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.exerciseSetup);

              for (var i in globals.muscle_val.keys) {
                globals.muscle_val[i] = 0;
              }
            },
          ),
          ListTile(
            title: const Text('Workout Setup'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.workoutSetup);
            },
          ),
          ListTile(
            title: const Text('Activity Tracker'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.activity);
            },
          ),
          ListTile(
            title: const Text('Food Tracker'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.food);
            },
          ),
          ListTile(
            title: const Text('Statistics'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.statistics);
            },
          ),
          ListTile(
            title: const Text('Calendar'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.calendar);
            },
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRouter.settings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.light),
            tooltip: 'Light/Dark Mode',
            onPressed: () async {
              final newMode = widget.mode == Brightness.light
                  ? Brightness.dark
                  : Brightness.light;
              widget.onModeChanged(newMode);

              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('isDarkMode', newMode == Brightness.dark);
            },
          ),
          // if (widget.credentials == null)
          //   Column(
          //     children: [
          //       _coloredDivider(),
          //       // ListTile(
          //       //   title: const Text('Login'),
          //       //   onTap: () async {
          //       //     Navigator.pop(context);
          //       //     widget.auth0.loginWithRedirect(redirectUrl: redirectUrl);
          //       //     // After login, data will be reloaded in the onLoad callback
          //       //   },
          //       // ),
          //     ],
          //   )
          // else
          Column(
            children: [
              _coloredDivider(),
              ListTile(
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await widget.auth0.logout(returnToUrl: redirectUrl);
                  // Clear user data after logout
                  widget.onCredentialsChanged(null);
                  // Reload data for default user
                  widget.onReloadUserData();
                },
              ),
              _buildUserDataIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  Divider _coloredDivider() {
    return Divider(
      color: widget.mode == Brightness.dark
          ? ThemeColors.themeWhite
          : ThemeColors.themeBlack,
    );
  }

  Widget _buildUserDataIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.container.authService.authStateNotifier,
      builder: (context, isLoggedIn, child) {
        return FutureBuilder<Map<String, int>>(
          future: _getUserDataCounts(),
          builder: (context, snapshot) {
            final exerciseCount = snapshot.data?['exercises'] ?? 0;
            final workoutCount = snapshot.data?['workouts'] ?? 0;

            return Container(
              padding: const EdgeInsets.all(12.0),
              margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: widget.container.authService.isLoggedIn
                    ? ThemeColors.themeBlue
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: widget.container.authService.isLoggedIn
                      ? widget.isDarkMode
                          ? Colors.white
                          : Colors.white
                      : Colors.grey,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.container.authService.isLoggedIn
                            ? Icons.person
                            : Icons.person_outline,
                        color: widget.container.authService.isLoggedIn
                            ? widget.isDarkMode
                                ? Colors.white
                                : Colors.white
                            : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.container.authService.isLoggedIn
                              ? 'Logged in as: ${widget.container.authService.userName}'
                              : 'Not logged in (viewing defaults)',
                          style: TextStyle(
                            color: widget.container.authService.isLoggedIn
                                ? widget.isDarkMode
                                    ? Colors.white
                                    : Colors.white
                                : Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (exerciseCount > 0 || workoutCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$exerciseCount exercises • $workoutCount workouts',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.white,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, int>> _getUserDataCounts() async {
    try {
      final exercises = await widget.container.exerciseService.getExercises();
      final workouts = await widget.container.workoutService.getWorkouts();
      return {
        'exercises': exercises.length,
        'workouts': workouts.length,
      };
    } catch (e) {
      return {'exercises': 0, 'workouts': 0};
    }
  }
}
