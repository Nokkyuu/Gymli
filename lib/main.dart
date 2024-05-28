// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:yafa_app/landingScreen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yafa_app/exerciseSetupScreen.dart';
import 'package:yafa_app/settingsScreen.dart';
import 'package:yafa_app/workoutSetupScreen.dart';
import 'globals.dart' as globals;
bool state = false;

// Pectoralis major
// Trapezius
// Biceps
// Abdominals
// Front Deltoids
// Side Deltoids
// Rear Deltoids
// Latissimus dorsi
// Triceps
// Gluteus maximus
// Hamstrings
// Quadriceps
// Forearms
// Calves
void get_exercise_list() async {
  final box = await Hive.openBox<Exercise>('Exercises');
  var boxmap = box.values.toList();
  List<String> exerciseList = [];
  for (var e in boxmap) {
    exerciseList.add(e.name);
  }
  globals.exerciseList = exerciseList;
}

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(TrainingSetAdapter());
  // populateExercises();
  await Hive.openBox<TrainingSet>('TrainingSets');
  await Hive.openBox<Exercise>('Exercises');

  runApp(const MainApp()
  );
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Brightness mode =  Brightness.light;
  Color themecolor = const Color.fromARGB(255, 0, 7, 42);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themecolor,
          brightness: mode,
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
    title: const Text("Fitness Tracker"),
    centerTitle: true,),
    body: const LandingScreen(),
    drawer: Builder(
      builder: (context) {
        return Drawer(
                child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
              decoration: BoxDecoration(
                //color: Colors.blueAccent
              ),
              child: Image(image: AssetImage('images/menu2.png')),
            ),
          ListTile(
            title: const Text('Exercise Setup'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciseSetupScreen()));
              get_exercise_list();
              for (var i in globals.muscle_val.keys)
                {globals.muscle_val[i] = 0;}
            },
          ),
          ListTile(
            title: const Text('Workout Setup'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutSetupScreen()));
            });},
          
          ),
          ListTile(
            title: const Text('Statistics'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutSetupScreen()));
            });},
          
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: () {
              setState(() {
                Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            });},
          
          ),
          IconButton(
              icon: const Icon(Icons.light),
              tooltip: 'Light/Dark Mode',
              onPressed: () {
                setState(() {
                  if (mode == Brightness.light){
                  mode = Brightness.dark;}
                  else{ mode = Brightness.light;}
                });
              },
            ),
        ],
                ),
              );
      }
    ),),
      
    );
  }
}

