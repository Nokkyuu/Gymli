import 'dart:async';
import 'package:hive/hive.dart';
part 'DataModels.g.dart';

@HiveType(typeId: 1)
class Exercise extends HiveObject {
  Exercise ({
    required this.name,
    required this.type,
    required this.muscleGroups,
    required this.defaultRepBase,
    required this.defaultRepMax,
    required this.defaultIncrement
  });

  @HiveField(0)
  String name = "";
  @HiveField(1)
  int type = 0;
  @HiveField(2)
  String muscleGroups = "";
  @HiveField(3)
  int defaultRepBase = 10;
  @HiveField(4)
  int defaultRepMax = 15;
  @HiveField(5)
  double defaultIncrement = 1.0;

}

