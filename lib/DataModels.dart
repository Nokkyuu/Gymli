// ignore_for_file: file_names

import 'package:hive/hive.dart';
part 'DataModels.g.dart';


// regenerate flutter pub run build_runner build
final exerciseTypeNames = ["Free", "Machine", "Cable", "Body"];
final muscleGroupNames = ["Pectoralis major", "Trapezius", "Biceps", "Abdominals", "Deltoids", "Latissimus dorsi", "Triceps", "Gluteus maximus", "Hamstrings", "Quadriceps", "Forearms", "Calves"];
final setTypeNames = ["Warm", "Work", "Drop"];

abstract class DataClass extends HiveObject {
  List<String> toCSVString();
}

@HiveType(typeId: 1)
class Exercise extends DataClass {
  Exercise ({ required this.name, required this.type, required this.muscleGroups, required this.muscleIntensities, required this.defaultRepBase, required this.defaultRepMax, required this.defaultIncrement });
  @HiveField(0)
  String name = "";
  @HiveField(1)
  int type = 0;
  @HiveField(2)
  List<String> muscleGroups = [];
  @HiveField(3)
  int defaultRepBase = 0;
  @HiveField(4)
  int defaultRepMax = 0;
  @HiveField(5)
  double defaultIncrement = 0.0;
  @HiveField(6)
  List<double> muscleIntensities = [];

  @override
  List<String> toCSVString() {
    String muscleString = "";
    String intensitiesString = "";
    for (var s in muscleGroups) {
      muscleString += "$s;";
    }
    for (var s in muscleIntensities) {
      intensitiesString += "$s;";
    }
    return [name, "$type", muscleString, intensitiesString, "$defaultRepBase", "$defaultRepMax", "$defaultIncrement"];
  }

}

@HiveType(typeId: 2)
class TrainingSet extends DataClass {
  TrainingSet ({required this.exercise, required this.date, required this.weight, required this.repetitions, required this.setType, required this.baseReps, required this.maxReps, required this.increment, required this.machineName});
  @HiveField(0)
  String exercise = "";
  @HiveField(1)
  DateTime date = DateTime.now();
  @HiveField(2)
  double weight = 0.0;
  @HiveField(3)
  int repetitions = 0;
  @HiveField(4)
  int setType = 0;
  @HiveField(5)
  int baseReps = 0;
  @HiveField(6)
  int maxReps = 0;
  @HiveField(7)
  double increment = 0.0;
  @HiveField(8)
  String machineName = "";

  @override
  List<String> toCSVString() {
    return [exercise, date.toString(), "$weight", "$repetitions", "$setType", "$baseReps", "$maxReps", "$increment", machineName];
  }
}


@HiveType(typeId: 3)
class WorkoutUnit extends HiveObject {
  WorkoutUnit ({required this.exercise, required this.warmups, required this.worksets, required this.dropsets, required this.type});
  @HiveField(0)
  String exercise = ""; 
  @HiveField(1)
  int warmups = 0;
  @HiveField(2)
  int worksets = 0;
  @HiveField(3)
  int dropsets = 0;
  @HiveField(4)
  int type = 0;
}

@HiveType(typeId: 4)
class Workout extends DataClass {
  Workout({required this.name, required this.units});
  @HiveField(0)
  String name = "";
  @HiveField(1)
  List<WorkoutUnit> units = [];


  @override
  List<String> toCSVString() {
    List<String> row = [name];
    for (WorkoutUnit unit in units) { row.add("${unit.exercise}, ${unit.warmups}, ${unit.worksets}, ${unit.dropsets}, ${unit.type}"); }
    return row;
  }
}


@HiveType(typeId: 5)
class Group extends DataClass {
  Group({required this.name, required this.exercises});
  @HiveField(0)
  String name = "";
  @HiveField(1)
  List<String> exercises = [];

  List<String> toCSVString() {
    List<String> row = [name];
    for (String unit in exercises) { row.add("${unit}"); }
    return row;
  }

}