import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DbHelper {
  int deleteIndex = 0;
  late Box box;
  DbHelper() { openbox(); }
  openbox() async { box = Hive.box('Exercise'); }

  Future<Map> getExercises() {
    if (box.values.isEmpty) {
      return Future.value({});
    } else {
      return Future.value(box.toMap());
    }
  }
}