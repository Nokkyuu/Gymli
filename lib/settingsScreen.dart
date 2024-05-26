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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreen();
}

void backupState(context) async {
  List<List<String>> data = [
    ["No.", "Name", "Roll No."],
    ["1", "1", "2"],
    ["2", "1", "2"],
    ["3", "1", "2"]
  ];
  String csvData = ListToCsvConverter().convert(data);
  final String directory = (await getApplicationSupportDirectory()).path;
  final path = "$directory/test.csv";
  // print(path);
  final File file = File(path);
  await file.writeAsString(csvData);
  final params = SaveFileDialogParams(sourceFilePath: path);
  final filePath = await FlutterFileDialog.saveFile(params: params);
  // Navigator.of(context).push(
  //   MaterialPageRoute(
  //     builder: (_) {
  //       return LoadCsvDataScreen(path: path);
  //     },
  //   ),
  // );
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
              icon: const Icon(Icons.data_array_outlined),
              onPressed: () {
                backupState(context);
              },
            ),
          ]
        ),
    );
  }
}
