// ignore_for_file: non_constant_identifier_names
library my_prj.globals;
import 'package:yafa_app/DataModels.dart';
import 'package:hive_flutter/hive_flutter.dart';

  var muscle_val = {
    "Pectoralis major": 0.0,
    "Trapezius": 0.0, 
    "Biceps": 0.0,
    "Abdominals": 0.0, 
    "Deltoids": 0.0, 
    "Latissimus dorsi": 0.0, 
    "Triceps": 0.0, 
    "Gluteus maximus": 0.0, 
    "Hamstrings": 0.0, 
    "Quadriceps": 0.0, 
    "Forearms": 0.0, 
    "Calves": 0.0
  };

  var exercise_twins = {
    "Benchpress": ["Benchpress (Machine)"],
    "Benchpress (Machine)": ["Benchpress"],
    "Squat (Machine)": ["Squat"],
    "Squat": ["Squat (Machine)"],
    "Deadlift": [],
    "Triceps (Cable)": ["Triceps Overhead", "Triceps"],
    "Triceps": ["Triceps (Cable)", "Triceps Overhead"],
    "Triceps Overhead": ["Triceps (Cable)", "Triceps"],
    "Biceps (Cable)": ["Biceps Curls"],
    "Biceps Curls": ["Biceps (Cable)"],
    "Side Delt Raises": [],
    "Face Pulls": ["Face Pulls (Cable)"],
    "Face Pulls (Cable)": ["Face Pulls"],
    "Rows (Machine)": [],
    "Pec Flys (Machine)": ["Pec Flys (Cable)"],
    "Pec Flys (Cable)": ["Pec Flys (Machine)"],
    "Lat Pulldowns (Machine)": ["Pullups"],
    "Pullups": ["Lat Pulldowns (Machine)"],
    "Hamstrings (Machine)": [],
    "Pushup": [],
    "Jackknife": [],
    "Back Extension": []
  };

  List<String> exerciseList = [];


  Exercise get_exercise(String exerciseName) {
    var box = Hive.box<Exercise>('Exercises');
    var exerciseFilter = box.values.toList().where((item) => item.name == exerciseName);
    return exerciseFilter.first;
  }



  
