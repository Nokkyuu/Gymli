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

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ExerciseAdapter());
  final box = await Hive.openBox<Exercise>('Exercises');
  if (box.isEmpty) {
    box.clear();
    box.add(Exercise(id:2, name: "Benchpress", type: 0, muscleGroups: "0", defaultRepBase: 10, defaultRepMax: 15, defaultIncrement: 2.5));
    box.add(Exercise(id:0, name: "Squat", type: 0, muscleGroups: "0", defaultRepBase: 10, defaultRepMax: 15, defaultIncrement: 2.5));
    box.add(Exercise(id:1, name: "Deadlift", type: 0, muscleGroups: "2", defaultRepBase: 10, defaultRepMax: 15, defaultIncrement: 2.5));
    box.add(Exercise(id:1, name: "Curl", type: 0, muscleGroups: "2", defaultRepBase: 10, defaultRepMax: 15, defaultIncrement: 2.5));
  }
  
  
  runApp(MaterialApp(
      title: 'Navigation Basics',
      // home: ExerciseListScreen(),
      home: LandingScreen(),
    ));
}
