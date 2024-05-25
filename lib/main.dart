import 'package:flutter/material.dart';
import 'package:yafa_app/landingScreen.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yafa_app/exerciseSetupScreen.dart';
import 'package:yafa_app/workoutSetupScreen.dart';
import 'package:yafa_app/jim.dart';
import 'dart:async';
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


Future<int> populateExercises() async {
  final exerciseBox = await Hive.openBox<Exercise>('Exercises');
  if (exerciseBox.isEmpty) {
    exerciseBox.clear();
    exerciseBox.add(Exercise(
        name: "Benchpress",
        type: 0,
        muscleGroups: ["Pectoralis major", "Front Deltoids", "Triceps"],
        defaultRepBase: 8,
        defaultRepMax: 12,
        defaultIncrement: 5.0));
    exerciseBox.add(Exercise(
        name: "Benchpress (Machine)",
        type: 0,
        muscleGroups: ["Pectoralis major", "Front Deltoids", "Triceps"],
        defaultRepBase: 8,
        defaultRepMax: 12,
        defaultIncrement: 5.0));
    exerciseBox.add(Exercise(
        name: "Squat (Machine)",
        type: 1,
        muscleGroups: ["Quadriceps", "Gluteus maximus"],
        defaultRepBase: 15,
        defaultRepMax: 18,
        defaultIncrement: 5.9));
    exerciseBox.add(Exercise(
        name: "Squat",
        type: 0,
        muscleGroups: ["Quadriceps", "Abdominals", "Gluteus maximus"],
        defaultRepBase: 15,
        defaultRepMax: 18,
        defaultIncrement: 5.9));
    exerciseBox.add(Exercise(
        name: "Deadlift",
        type: 0,
        muscleGroups: [
          "Latissimus dorsi",
          "Trapezius",
          "Gluteus maximus",
          "Quadriceps",
          "Hamstrings"
        ],
        defaultRepBase: 15,
        defaultRepMax: 18,
        defaultIncrement: 5.0));
    exerciseBox.add(Exercise(
        name: "Triceps (Cable)",
        type: 2,
        muscleGroups: ["Triceps"],
        defaultRepBase: 15,
        defaultRepMax: 20,
        defaultIncrement: 5.0));
    exerciseBox.add(Exercise(
        name: "Biceps (Cable)",
        type: 2,
        muscleGroups: ["Biceps"],
        defaultRepBase: 10,
        defaultRepMax: 15,
        defaultIncrement: 5.0));
    exerciseBox.add(Exercise(
        name: "Biceps Curls",
        type: 0,
        muscleGroups: ["Biceps"],
        defaultRepBase: 10,
        defaultRepMax: 15,
        defaultIncrement: 1.25));
    exerciseBox.add(Exercise(
        name: "Side Delt Raises",
        type: 0,
        muscleGroups: ["Side Deltoids"],
        defaultRepBase: 15,
        defaultRepMax: 20,
        defaultIncrement: 5.0));
    exerciseBox.add(Exercise(
        name: "Face Pulls",
        type: 0,
        muscleGroups: ["Rear Deltoids", "Trapezius", "Side Deltoids"],
        defaultRepBase: 15,
        defaultRepMax: 20,
        defaultIncrement: 5.0));
    exerciseBox.add(Exercise(
        name: "Face Pulls (Cable)",
        type: 2,
        muscleGroups: ["Rear Deltoids", "Trapezius", "Side Deltoids"],
        defaultRepBase: 15,
        defaultRepMax: 20,
        defaultIncrement: 5.0));
    exerciseBox.add(Exercise(
        name: "Rows (Machine)",
        type: 1,
        muscleGroups: ["Rear Deltoids", "Trapezius", "Latissimus dorsi"],
        defaultRepBase: 10,
        defaultRepMax: 15,
        defaultIncrement: 5.0));
      exerciseBox.add(Exercise(
        name: "Pec Flys (Machine)",
        type: 1,
        muscleGroups: ["Front Deltoids", "Pectoralis Major"],
        defaultRepBase: 10,
        defaultRepMax: 15,
        defaultIncrement: 5.0));
      exerciseBox.add(Exercise(
        name: "Pec Flys (Cable)",
        type: 2,
        muscleGroups: ["Front Deltoids", "Pectoralis Major"],
        defaultRepBase: 10,
        defaultRepMax: 15,
        defaultIncrement: 5.0));
      exerciseBox.add(Exercise(
        name: "Lat Pulldowns (Machine)",
        type: 1,
        muscleGroups: ["Biceps", "Latissimus dorsi"],
        defaultRepBase: 10,
        defaultRepMax: 15,
        defaultIncrement: 5.0));
      exerciseBox.add(Exercise(
        name: "Pullups",
        type: 0,
        muscleGroups: ["Biceps", "Latissimus dorsi"],
        defaultRepBase: 8,
        defaultRepMax: 12,
        defaultIncrement: 5.0));
      exerciseBox.add(Exercise(
        name: "Hamstrings (Machine)",
        type: 1,
        muscleGroups: ["Hamstrings"],
        defaultRepBase: 8,
        defaultRepMax: 12,
        defaultIncrement: 5.0));
  }
  add_sets_jim();
  return 1;
}

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(TrainingSetAdapter());


  runApp(FutureBuilder(
    future: populateExercises(),
    builder: (_, snap) {
      if (snap.hasData) {
        //here you can use the MyService singleton and its members
      return MainApp();
      }
      return CircularProgressIndicator();
    },
  ));

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
  Color themecolor = Colors.blue;
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
    body: LandingScreen(),
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
              child: Text('Where you wanna go, Amigo'),
            ),
          ListTile(
            title: const Text('Exercise Setup'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciseSetupScreen()));
            },
          ),
          ListTile(
            title: const Text('Workout Setup'),
            onTap: () {
              setState(() {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutSetupScreen()));
            });},
          ),
          IconButton(
              icon: const Icon(Icons.light),
              tooltip: 'Increase volume by 10',
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

