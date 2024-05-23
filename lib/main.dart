import 'package:flutter/material.dart';
//import 'dart:math';
//import 'package:fl_chart/fl_chart.dart';
//import 'package:yafa_app/exerciseListScreen.dart';
//import 'package:yafa_app/exerciseScreen.dart';
//import 'package:yafa_app/exerciseSetupScreen.dart';
import 'package:yafa_app/landingScreen.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/DataModels.dart';

Future<int> populate() async {
  final box = await Hive.openBox<Exercise>('Exercises');
  if (box.isEmpty) {
    box.clear();
    box.add(Exercise(name: "Benchpress", type: 0, muscleGroups: ["Pectoralis major", "Front Deltoids", "Triceps"], defaultRepBase: 8, defaultRepMax: 12, defaultIncrement: 5.0));
    box.add(Exercise(name: "Squat (Machine)", type: 1, muscleGroups: ["Quadriceps", "Gluteus maximus"], defaultRepBase: 15, defaultRepMax: 18, defaultIncrement: 5.9));
    box.add(Exercise(name: "Squat", type: 0, muscleGroups: ["Quadriceps", "Abdominals", "Gluteus maximus"], defaultRepBase: 15, defaultRepMax: 18, defaultIncrement: 5.9));
    box.add(Exercise(name: "Deadlift", type: 0, muscleGroups: ["Latissimus dorsi", "Trapezius", "Gluteus maximus", "Quadriceps", "Hamstrings"], defaultRepBase: 15, defaultRepMax: 18, defaultIncrement: 5.0));
    box.add(Exercise(name: "Triceps Cable", type: 0, muscleGroups: ["Triceps"], defaultRepBase: 15, defaultRepMax: 20, defaultIncrement: 5.0));
    box.add(Exercise(name: "Side Delts", type: 0, muscleGroups: ["Side Deltoids"], defaultRepBase: 15, defaultRepMax: 20, defaultIncrement: 5.0));
    box.add(Exercise(name: "Face Pulls", type: 0, muscleGroups: ["Rear Deltoids", "Trapezius", "Side Deltoids"], defaultRepBase: 15, defaultRepMax: 20, defaultIncrement: 5.0));
    box.add(Exercise(name: "Face Pulls (Cable)", type: 2, muscleGroups: ["Rear Deltoids", "Trapezius", "Side Deltoids"], defaultRepBase: 15, defaultRepMax: 20, defaultIncrement: 5.0));
    return 1;
  }
  return 0;
}

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ExerciseAdapter());

  // await populate();
  
  runApp(
    FutureBuilder(
      future: populate(),
      builder: (_,snap){
        if(snap.hasData){
          //here you can use the MyService singleton and its members
          return MaterialApp(
            title: 'Navigation Basics',
            // home: ExerciseListScreen(),
            home: LandingScreen(),
          );
        }
        return CircularProgressIndicator();
      },
    )
  );

  // runApp(MaterialApp(
  //   title: 'Navigation Basics',
  //   // home: ExerciseListScreen(),
  //   home: LandingScreen(),
  // ));
}
