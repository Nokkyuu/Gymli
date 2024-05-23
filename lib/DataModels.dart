import 'dart:async';
import 'package:hive/hive.dart';
part 'DataModels.g.dart';


final exerciseTypeNames = ["Free", "Machine", "Cable", "Body"];
final muscleGroupNames = ["Pectoralis major", "Trapezius", "Biceps", "Abdominals", "Front Deltoids", "Side Deltoids", "Rear Deltoids", "Latissimus dorsi", "Triceps", "Gluteus maximus", "Hamstrings", "Quadriceps", "Forearms", "Calves"];
final setTypeNames = ["Warm", "Work", "Drop"];

@HiveType(typeId: 1)
class Exercise extends HiveObject {
  Exercise ({ required this.name, required this.type, required this.muscleGroups, required this.defaultRepBase, required this.defaultRepMax, required this.defaultIncrement });
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
}

@HiveType(typeId: 2)
class TrainingSet extends HiveObject {
  TrainingSet ({required this.id, required this.exercise, required this.date, required this.weight, required this.repetitions, required this.setType, required this.baseReps, required this.maxReps, required this.increment, required this.machineName});
  @HiveField(0)
  int id = 0;
  @HiveField(1)
  String exercise = "";
  @HiveField(2)
  DateTime date = DateTime.now();
  @HiveField(3)
  double weight = 0.0;
  @HiveField(4)
  int repetitions = 0;
  @HiveField(5)
  int setType = 0;
  @HiveField(6)
  int baseReps = 0;
  @HiveField(7)
  int maxReps = 0;
  @HiveField(8)
  double increment = 0.0;
  @HiveField(9)
  String machineName = "";
}


