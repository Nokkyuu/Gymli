// ignore_for_file: non_constant_identifier_names

import 'package:Gymli/groupScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:Gymli/landingScreen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Gymli/DataModels.dart';
import 'package:Gymli/exerciseSetupScreen.dart';
import 'package:Gymli/settingsScreen.dart';
import 'package:Gymli/workoutSetupScreen.dart';
import 'package:Gymli/statisticsScreen.dart';
import 'package:Gymli/apiTestScreen.dart';
import 'globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'themeColors.dart';
import 'profile_view.dart';

bool state = false;

void get_exercise_list() async {
  final box = await Hive.openBox<Exercise>('Exercises');
  var boxmap = box.values.toList();
  List<String> exerciseList = [];
  for (var e in boxmap) {
    exerciseList.add(e.name);
  }
  globals.exerciseList = exerciseList;
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
  await Hive.initFlutter();
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(TrainingSetAdapter());
  Hive.registerAdapter(WorkoutAdapter());
  Hive.registerAdapter(WorkoutUnitAdapter());
  Hive.registerAdapter(GroupAdapter());
  getPreferences();
  // preopen all boxes
  await Hive.openBox<TrainingSet>('TrainingSets');
  await Hive.openBox<Exercise>('Exercises');
  await Hive.openBox<Workout>('Workouts');
  await Hive.openBox<Group>('Groups');
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
  Brightness mode = Brightness.light;
  Color themecolor = const Color(0xE6FF6A00);
  bool isDarkMode = false;
  Credentials? _credentials;
  late Auth0Web auth0;

  @override
  void initState() {
    super.initState();
    loadThemePreference();
    isDarkMode = Theme.of(context).brightness == Brightness.dark;

    auth0 = Auth0Web('dev-aqz5a2g54oer01tk.us.auth0.com',
        'MAxJUti2T7TkLagzT7SdeEzCTZsHyuOa');

    auth0.onLoad().then((final credentials) => setState(() {
          _credentials = credentials;
        }));

    // if (kIsWeb) {
    //   triggerLoad<TrainingSet>(context, "TrainingSets");
    //   triggerLoad<Exercise>(context, "Exercises");
    // }
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
      theme: themeData,
      title: 'Navigation Basics',
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
              centerTitle: true,
            ),
            body: landingScreen,
            drawer: _buildDrawer(context),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final redirectUrl =
        kDebugMode ? 'http://localhost:3000' : 'https://gymli.brgmnn.de/';
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorOrange,
            ),
            child: Image(
                image: AssetImage(
              isDarkMode
                  ? 'images/Icon-App_3_Darkmode.png'
                  : 'images/Icon-App_3.png',
            )),
          ),
          const Text("Gymli Gainson",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: "Times New Roman", fontSize: 30)),
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
          ListTile(
            title: const Text('API Test'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const apiTestScreen()));
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
                  onTap: () {
                    setState(() {
                      Navigator.pop(context);
                      auth0.loginWithRedirect(redirectUrl: redirectUrl);
                    });
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
                  },
                ),
                ProfileView(user: _credentials!.user),
              ],
            ),
        ],
      ),
    );
  }
}
