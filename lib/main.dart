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

void add(taskBox) async {
  taskBox.add(Exercise(id:2, name: "Benchpress", type: 0, muscleGroups: "0", defaultRepBase: 10, defaultRepMax: 15, defaultIncrement: 2.5));
  // taskBox.add(Exercise(id:0, name: "Squat", type: 0, muscleGroups: "0", defaultRepBase: 10, defaultRepMax: 15, defaultIncrement: 2.5));
  taskBox.add(Exercise(id:1, name: "Deadlift", type: 0, muscleGroups: "2", defaultRepBase: 10, defaultRepMax: 15, defaultIncrement: 2.5));
}
void get(taskBox) async {
  for (var e in taskBox.values.toList()) {
    print(e.name);
  }
}

void main() async {
  await Hive.initFlutter();
  final taskBox = await Hive.openBox<Exercise>('Exercises');
  add(taskBox);
  get(taskBox);
  taskBox.close();
  runApp(MaterialApp(
      title: 'Navigation Basics',
      // home: ExerciseListScreen(),
      home: LandingScreen(),
    ));
}
