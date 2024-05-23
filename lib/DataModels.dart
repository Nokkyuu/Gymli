import 'dart:async';
import 'package:hive/hive.dart';
part 'DataModels.g.dart';

@HiveType(typeId: 1)
class Exercise extends HiveObject {
  Exercise ({
    required this.id,
    required this.name,
    required this.type,
    required this.muscleGroups,
    required this.defaultRepBase,
    required this.defaultRepMax,
    required this.defaultIncrement
  });

  @HiveField(0)
  int id = 0;
  @HiveField(1)
  String name = "";
  @HiveField(2)
  int type = 0;
  @HiveField(3)
  String muscleGroups = "";
  @HiveField(4)
  int defaultRepBase = 10;
  @HiveField(5)
  int defaultRepMax = 15;
  @HiveField(6)
  double defaultIncrement = 1.0;

}

