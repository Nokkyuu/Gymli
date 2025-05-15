// ignore_for_file: non_constant_identifier_names

import 'package:Gymli/groupScreen.dart';
import 'package:flutter/material.dart';
import 'package:Gymli/landingScreen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Gymli/DataModels.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Gymli/exerciseSetupScreen.dart';
import 'package:Gymli/settingsScreen.dart';
import 'package:Gymli/workoutSetupScreen.dart';
import 'package:Gymli/statisticsScreen.dart';
import 'package:Gymli/apiTestScreen.dart';
import 'globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  Color themecolor = Color(0xE6FF6A00);
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // if (kIsWeb) {
    //   triggerLoad<TrainingSet>(context, "TrainingSets");
    //   triggerLoad<Exercise>(context, "Exercises");
    // }
  }

  LandingScreen landingScreen = const LandingScreen();
  // StatisticsScreen landingScreen = const StatisticsScreen();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themecolor,
          brightness: mode,
          primary: Color(0xE6FF6A00),
          primaryContainer: Color(0xE6FF6A00),
          onPrimary: Colors.white,
          onPrimaryContainer: Colors.white,
          secondary: Color(0xE6FF6A00),
          secondaryContainer: Color(0xE6FF6A00),
          onSecondary: Colors.white,
          onSecondaryContainer: Colors.white,
          tertiary: Color(0xE6FF6A00),
          tertiaryContainer: Color(0xE6FF6A00),
          onTertiary: Colors.white,
          onTertiaryContainer: Colors.white,
          error: Colors.red,
          errorContainer: Colors.white,
          onError: Colors.white,
          onErrorContainer: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          surfaceContainerHighest: Colors.white,
          onSurfaceVariant: Colors.black,
          outline: Colors.black,
          shadow: Colors.black,
          inverseSurface: Colors.black,
          onInverseSurface: Colors.white,
          inversePrimary: Colors.white,
          surfaceContainer: Colors.white,
          surfaceContainerHigh: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainerLowest: Colors.white,
          surfaceTint: Colors.white,
          surfaceBright: Colors.white,
          surfaceDim: Colors.white,
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.oswald(
            fontSize: 30,
            fontStyle: FontStyle.italic,
          ),
          bodyMedium: GoogleFonts.merriweather(),
          displaySmall: GoogleFonts.pacifico(),
        ),
      ),
      title: 'Navigation Basics',
      home: Scaffold(
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
            //alignment: Alignment.center,
            //mainAxisAlignment: MainAxisAlignment.center,
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
              Container(
                  padding: const EdgeInsets.all(0.0),
                  child: const Text(
                    'Gymli',
                    textAlign: TextAlign.center,
                  ))
            ],
          ), //const Text("Weight Wise"),
          //actions: const [ Text("")],
          centerTitle: true,
        ),
        body: landingScreen,
        drawer: Builder(builder: (context) {
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xE6FF6A00),
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
                    style:
                        TextStyle(fontFamily: "Times New Roman", fontSize: 30)),
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
                              builder: (context) =>
                                  const WorkoutSetupScreen("")));
                    });
                  },
                ),
                ListTile(
                  title: const Text('Group Setup'),
                  onTap: () {
                    setState(() {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GroupScreen()));
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
                  onPressed: () {
                    setState(() {
                      if (mode == Brightness.light) {
                        mode = Brightness.dark;
                      } else {
                        mode = Brightness.light;
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
