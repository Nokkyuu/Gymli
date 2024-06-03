// ignore_for_file: non_constant_identifier_names
library my_prj.globals;
import 'package:Gymli/DataModels.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tuple/tuple.dart';
import 'package:intl/intl.dart';

  int idleTimerWakeup = 90;
  int graphNumberOfDays = 40;

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

List<TrainingSet> getExerciseTrainings(String exercise) {
  var items = Hive.box<TrainingSet>('TrainingSets').values;
  return items.where((item) => item.exercise == exercise).toList();

}

List<TrainingSet> getTrainings(DateTime day) {
  var items = Hive.box<TrainingSet>('TrainingSets').values;
  return items.where((item) => item.date.day == day.day &&item.date.month == day.month &&item.date.year == day.year).toList();
}

List<DateTime> getTrainingDates(String exercise) {
  var box = Hive.box<TrainingSet>('TrainingSets');
  var items = box.values;
  if (exercise != "") {
    items = items.where((item) => item.exercise == exercise).toList();
  }
  final dates = items
      .map((e) => DateFormat('yyyy-MM-dd').format(e.date))
      .toSet()
      .toList();
  dates.sort((a, b) {
    return a.toLowerCase().compareTo(b.toLowerCase());
  }); // wiederum etwas hacky
  List<DateTime> trainingDates = [];
  for (var d in dates) {
    trainingDates.add(DateFormat('yyyy-MM-dd').parse(d));
  }
  return trainingDates;
}

DateTime getLastTrainingDay(String exercise) {
  var trainingDates = getTrainingDates(exercise);
  if (trainingDates.isEmpty) { return DateTime.now(); }
  // absolutely horrible solutions
  var best_element = 0;
  var best_element_distance = -999;
  for (var i = 0; i < trainingDates.length; i++) {
    final dayDiff = trainingDates[i].difference(DateTime.now()).inDays;
    if (dayDiff > best_element_distance) {
      best_element = i;
      best_element_distance = dayDiff;
    }
  }
  return trainingDates[best_element];
}


Tuple2<double, int> getLastTrainingInfo(String exercise) {
  var trainings = Hive.box<TrainingSet>('TrainingSets').values.toList();
  trainings = trainings.where((item) => item.exercise == exercise).toList();
  var trainingDates = getTrainingDates(exercise);
  if (trainingDates.isEmpty) {
    return const Tuple2<double, int>(20.0, 10);
  }

  var d = getLastTrainingDay(exercise);
  var latest_trainings = trainings.where((item) =>
      item.date.day == d.day &&
      item.date.month == d.month &&
      item.date.year == d.year);
  var best_weight = -100.0;
  var best_reps = 1;
  for (var s in latest_trainings) {
    if (s.weight > best_weight) {
      best_weight = s.weight;
      best_reps = s.repetitions;
    }
  }
  return Tuple2<double, int>(best_weight, best_reps);
}

  List<List> muscleHistoryScore = [];
