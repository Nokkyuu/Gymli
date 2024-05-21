import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer';

class Exercise {
  final int id;
  final String name;
  final int type;
  final String muscleGroups;
  final int defaultRepBase;
  final int defaultRepMax;
  final double defaultIncrement;

  const Exercise ({
    required this.id,
    required this.name,
    required this.type,
    required this.muscleGroups,
    required this.defaultRepBase,
    required this.defaultRepMax,
    required this.defaultIncrement
  });
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'muscleGroups': muscleGroups,
      'defaultRepBase': defaultRepBase,
      'defaultRepMax': defaultRepMax,
      'defaultIncrement': defaultIncrement
    };
  }
}


Future<Database> openMyDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'database.sqlite');
  final database = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Create tables here
    },
  );
  return database;
}
