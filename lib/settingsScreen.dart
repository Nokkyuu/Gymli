// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:confirm_dialog/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreen();
}
void wipeExercises(context) async {
  if (await confirm(context)) {
    var exerciseBox = Hive.box<Exercise>('Exercises');
    exerciseBox.clear();
  }
}
void wipeTrainingSets(context) async {
  if (await confirm(context)) {
  var trainingBox = Hive.box<TrainingSet>('TrainingSets');
  trainingBox.clear();
  }
}


void backupExercises(context) async {
  List<List<String>> exercisedata = [];
  var trainings = Hive.box<Exercise>('Exercises').values.toList();
  for (var t in trainings) {
    exercisedata.add(t.toCSVString());
  }

  String csvData = const ListToCsvConverter().convert(exercisedata);
  final String directory = (await getApplicationSupportDirectory()).path;
  final path = "$directory/exercises_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv";
  final File file = File(path);
  await file.writeAsString(csvData);
  final params = SaveFileDialogParams(sourceFilePath: path);
  final filePath = await FlutterFileDialog.saveFile(params: params);  
}

void backupSetState(context) async {
  List<List<String>> trainingSetData = [];
  var trainings = Hive.box<TrainingSet>('TrainingSets').values.toList();
  for (var t in trainings) {
    trainingSetData.add(t.toCSVString());
  }

  String csvData = const ListToCsvConverter().convert(trainingSetData);
  final String directory = (await getApplicationSupportDirectory()).path;
  final path = "$directory/trainingsets_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv";
  final File file = File(path);
  await file.writeAsString(csvData);
  final params = SaveFileDialogParams(sourceFilePath: path);
  final filePath = await FlutterFileDialog.saveFile(params: params);
}


class _SettingsScreen extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios,
          ),
        ),
        title: const Text("Settings"),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            TextButton.icon(
              style: const ButtonStyle(),
              label: const Text('Save Training Sets'),
              icon: const Icon(Icons.expand_circle_down),
              onPressed: () {
                backupSetState(context);
              },
            ),
            TextButton.icon(
              style: const ButtonStyle(),
              label: const Text('Save Exercises'),
              icon: const Icon(Icons.expand_sharp),
              onPressed: () {
                backupExercises(context);
              },
            ),
            TextButton.icon(
              style: const ButtonStyle(),
              label: const Text('Wipe Training Sets'),
              icon: const Icon(Icons.delete_rounded),
              onPressed: () {
                wipeTrainingSets(context);
              },
            ),
            TextButton.icon(
              style: const ButtonStyle(),
              label: const Text('Wipe Exercises'),
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                wipeExercises(context);
              },
            ),
          ]
        ),
    );
  }
}
