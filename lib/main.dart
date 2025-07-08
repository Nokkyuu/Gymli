import 'package:flutter/material.dart';
import 'package:Gymli/landingScreen.dart';
import 'package:Gymli/exerciseSetupScreen.dart';
import 'package:Gymli/settingsScreen.dart';
import 'package:Gymli/workoutSetupScreen.dart';
import 'package:Gymli/statisticsScreen.dart';
import 'package:Gymli/activityScreen.dart';
import 'package:Gymli/foodScreen.dart';
import 'globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'themeColors.dart';
import 'user_service.dart';
import 'config/api_config.dart';
import 'info.dart';
import 'calendarScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math';

final userService = UserService();
bool state = false;

void get_exercise_list() async {
  try {
    // Check if API is configured before making calls
    if (!ApiConfig.isConfigured) {
      print('API not configured, skipping exercise list load');
      globals.exerciseList = [];
      return;
    }

    // Add a small delay to ensure UserService singleton is properly initialized
    await Future.delayed(const Duration(milliseconds: 100));

    final userService = UserService();
    final exercises = await userService.getExercises();
    List<String> exerciseList = [];
    for (var e in exercises) {
      exerciseList.add(e['name']);
    }
    globals.exerciseList = exerciseList;
    print(
        'Exercise list loaded successfully: ${exerciseList.length} exercises');
  } catch (e) {
    print('Error loading exercise list: $e');
    // Set a fallback empty list to prevent null reference errors
    globals.exerciseList = [];
  }
}

Future<void> getPreferences() async {
  Future<SharedPreferences> prefs0 = SharedPreferences.getInstance();
  final SharedPreferences prefs = await prefs0;
  if (prefs.getInt('idleWakeTime') != null) {
    globals.idleTimerWakeup = prefs.getInt('idleWakeTime')!;
  }
  if (prefs.getInt('graphNumberOfDays') != null) {
    globals.graphNumberOfDays = prefs.getInt('graphNumberOfDays')!;
  }
  if (prefs.getBool('detailedGraph') != null) {
    globals.detailedGraph = prefs.getBool('detailedGraph')!;
  }
  // print(prefs.getInt('counter'));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await getPreferences();
    ApiConfig.initialize(); // Initialize API configuration
  } catch (e) {
    print('Initialization error: $e');
    // Continue app startup even if API config fails in debug mode
    if (!kDebugMode) {
      rethrow;
    }
  }

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String? _drawerImage;
  Brightness mode = Brightness.light;
  Color themecolor = const Color(0xE6FF6A00);
  bool isDarkMode = false;
  Credentials? _credentials;
  late Auth0Web auth0;
  final userService = UserService();
  bool _authInitialized = false;
  final List<String> drawerImages = [
    'images/drawerlogo/gymli-biceps',
    'images/drawerlogo/gymli-curl1',
    'images/drawerlogo/gymli-curl2',
    'images/drawerlogo/gymli-squat',
    'images/drawerlogo/gymli-face',
  ];

  @override
  void initState() {
    super.initState();
    loadThemePreference();
    isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (!_authInitialized) {
      auth0 = Auth0Web('dev-aqz5a2g54oer01tk.us.auth0.com',
          'MAxJUti2T7TkLagzT7SdeEzCTZsHyuOa');

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

      _authInitialized = true;
    }

    // Load stored authentication state on app initialization
    _loadStoredAuthState();

    // Load initial exercise list after a delay to ensure initialization
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Only load exercise list if it hasn't been loaded yet or is empty
    if (globals.exerciseList.isEmpty) {
      // Wait a bit to ensure all widgets are initialized
      await Future.delayed(const Duration(milliseconds: 300));
      get_exercise_list();
    }
  }

  Future<void> _reloadUserData() async {
    // Refresh exercise list
    get_exercise_list();

    // Force refresh of the landing screen by rebuilding the entire app
    setState(() {
      // This will trigger a rebuild and the landing screen will reload its data
    });

    // Small delay to ensure state is updated before notifying listeners
    await Future.delayed(const Duration(milliseconds: 100));

    // Notify all listeners that auth state has changed
    userService.notifyAuthStateChanged();
  }

  Future<void> _loadStoredAuthState() async {
    try {
      final credentials = await userService.loadStoredAuthState();
      if (credentials != null) {
        setState(() {
          _credentials = credentials;
        });
        userService.setCredentials(credentials);
        print('Loaded stored authentication state successfully');
        // Reload user data after restoring auth state
        _reloadUserData();
      } else {
        print('No stored authentication state found');
      }
    } catch (e) {
      print('Error loading stored authentication state: $e');
      // Continue without stored auth state
    }
  }

  Widget _buildUserDataIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: userService.authStateNotifier,
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
                color: userService.isLoggedIn
                    ? ThemeColors.themeBlue
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: userService.isLoggedIn
                      ? isDarkMode
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
                        userService.isLoggedIn
                            ? Icons.person
                            : Icons.person_outline,
                        color: userService.isLoggedIn
                            ? isDarkMode
                                ? Colors.white
                                : Colors.white
                            : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userService.isLoggedIn
                              ? 'Logged in as: ${userService.userName}'
                              : 'Not logged in (viewing defaults)',
                          style: TextStyle(
                            color: userService.isLoggedIn
                                ? isDarkMode
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
                        color: isDarkMode ? Colors.white : Colors.white,
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
      final exercises = await userService.getExercises();
      final workouts = await userService.getWorkouts();
      return {
        'exercises': exercises.length,
        'workouts': workouts.length,
      };
    } catch (e) {
      return {'exercises': 0, 'workouts': 0};
    }
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      mode = isDark ? Brightness.dark : Brightness.light;
    });
  }

  LandingScreen landingScreen = const LandingScreen();
  // StatisticsScreen landingScreen = const StatisticsScreen();
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = buildAppTheme(mode);

    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('en', 'GB'),
        const Locale('de', 'DE'),
      ],
      theme: themeData,
      title: 'Gymli Gainson',
      home: Builder(
        builder: (context) {
          isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            appBar: AppBar(
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
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
            ),
            body: landingScreen,
            drawer: _buildDrawer(context),
            onDrawerChanged: (isOpened) {
    if (isOpened) {
      setState(() {
        _drawerImage = drawerImages[Random().nextInt(drawerImages.length)];
      });
    }
  },
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    const redirectUrl =
        kDebugMode ? 'http://localhost:3000' : 'https://gymli.brgmnn.de/';
    final imageToShow = _drawerImage ?? drawerImages[0];
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: colorOrange,
            ),
            child: Image(
                image: AssetImage(
              isDarkMode
                  ? '$imageToShow-dark.png'
                  : '$imageToShow.png',
            )),
          ),
          Text(
            "Gymli Gainson",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ListTile(
            title: const Text('Exercise Setup'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ExerciseSetupScreen("")));
              get_exercise_list();
              for (var i in globals.muscle_val.keys) {
                globals.muscle_val[i] = 0;
              }
            },
          ),
          ListTile(
            title: const Text('Workout Setup'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WorkoutSetupScreen("")));
              });
            },
          ),
          // ListTile(
          //   title: const Text('Group Setup'),
          //   onTap: () {
          //     setState(() {
          //       Navigator.pop(context);
          //       Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //               builder: (context) => const GroupScreen()));
          //     });
          //   },
          // ),
          ListTile(
            title: const Text('Activity Tracker'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ActivityScreen()));
              });
            },
          ),
          ListTile(
            title: const Text('Food Tracker'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FoodScreen()));
              });
            },
          ),
          ListTile(
            title: const Text('Statistics'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StatisticsScreen()));
              });
            },
          ),
          ListTile(
            title: const Text('Calendar'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              });
            },
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()));
              });
            },
          ),

          IconButton(
            icon: const Icon(Icons.light),
            tooltip: 'Light/Dark Mode',
            onPressed: () async {
              setState(() {
                if (mode == Brightness.light) {
                  mode = Brightness.dark;
                } else {
                  mode = Brightness.light;
                }
              });
              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('isDarkMode', mode == Brightness.dark);
            },
          ),
          if (_credentials == null)
            Column(
              children: [
                Divider(
                  color: mode == Brightness.dark ? colorWhite : colorBlack,
                ),
                ListTile(
                  title: const Text('Login'),
                  onTap: () async {
                    setState(() {
                      Navigator.pop(context);
                      auth0.loginWithRedirect(redirectUrl: redirectUrl);
                    });
                    // After login, data will be reloaded in the onLoad callback
                  },
                ),
              ],
            )
          else
            Column(
              children: [
                Divider(
                  color: mode == Brightness.dark ? colorWhite : colorBlack,
                ),
                ListTile(
                  title: const Text('Logout'),
                  onTap: () async {
                    Navigator.pop(context);
                    await auth0.logout(returnToUrl: redirectUrl);
                    // Clear user data after logout
                    setState(() {
                      _credentials = null;
                      userService.setCredentials(null);
                    });
                    // Reload data for default user
                    _reloadUserData();
                  },
                ),
                _buildUserDataIndicator(),
              ],
            ),
        ],
      ),
    );
  }
}

// Widget _buildInfoButton(context) {
//   return IconButton(
//     icon: const Icon(Icons.info_outline),
//     tooltip: 'About Gymli',
//     onPressed: () => showInfoDialogMain(context),
//   );
// }
