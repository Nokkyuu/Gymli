// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Gymli/DataModels.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
//import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

enum DisplayMode { light, dark }

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
  final filePath = await FlutterFileDialog.saveFile(params: SaveFileDialogParams(sourceFilePath: path));
}

void restoreSetData(context) async {
  if (kIsWeb) {
    //print("bla");
    var filePath = 'csv/set.csv';
    final myData = await rootBundle.loadString(filePath);
    //print(myData);
    restoreSetLoad(myData);
  } else {
  final filePath = await FlutterFileDialog.pickFile(params: const OpenFileDialogParams(dialogType: OpenFileDialogType.document, sourceType: SourceType.savedPhotosAlbum));
  if (filePath != null){
  File file = File(filePath); 
  final myData =  await file.readAsString();
  restoreSetLoad(myData);
  }
  
  else{return;}
  }
}

void restoreSetLoad(myData) {
  List<List<String>> csvTable = const CsvToListConverter(shouldParseNumbers: false).convert(myData);
  final setBox = Hive.box<TrainingSet>('TrainingSets');
  setBox.clear();
  for (List<String> row in csvTable) {
    //print(row);
    setBox.add(TrainingSet(exercise: row[0], date: DateTime.parse(row[1]), weight: double.parse(row[2]), repetitions: int.parse(row[3]), setType: int.parse(row[4]), baseReps: int.parse(row[5]), maxReps: int.parse(row[6]), increment: double.parse(row[7]), machineName: row[7]));
  }
}

void restoreExercises(context) async {
  if (kIsWeb) {
    //print("bla");
    var filePath = 'csv/ex.csv';
    final myData = await rootBundle.loadString(filePath);
    // print(myData);
    restoreExLoad(myData);
  } else {
  final filePath = await FlutterFileDialog.pickFile(params: const OpenFileDialogParams(dialogType: OpenFileDialogType.document, sourceType: SourceType.savedPhotosAlbum));
  if (filePath != null){
  File file = File(filePath); 
  final myData =  await file.readAsString();
  restoreExLoad(myData);
  }
  
  else{return;}
  }
}
  
void restoreExLoad(myData){
  //print(myData);
  final exerciseBox = Hive.box<Exercise>('Exercises');
  exerciseBox.clear();
  List<List<String>> csvTable = const CsvToListConverter(shouldParseNumbers: false).convert(myData);
  for (List<String> row in csvTable) {
    List<String> muscleGroups = [];
    List<double> muscleIntensities = [];
    for (String e in row[2].split(";")) {
      if (e != "") { muscleGroups.add(e); }
    }
    for (String e in row[3].split(";")) {
      if (e != "") { muscleIntensities.add(double.parse(e)); }
    }
    if (muscleGroups.length > muscleIntensities.length) {
      muscleIntensities = [];
      for (var i = 0; i < muscleGroups.length; ++i) {
        muscleIntensities.add(1.0);
      }
    }
    exerciseBox.add(Exercise(name: row[0], type: int.parse(row[1]), muscleGroups: muscleGroups, muscleIntensities: muscleIntensities, defaultRepBase: int.parse(row[4]), defaultRepMax: int.parse(row[5]), defaultIncrement: double.parse(row[6])));
  }
} 


class _SettingsScreen extends State<SettingsScreen> {
  final wakeUpTimeController = TextEditingController();
  // final equationController = TextEditingController();
  final Future<SharedPreferences> _preferences = SharedPreferences.getInstance();
  DisplayMode selectedMode = DisplayMode.light;

  @override
  void initState() {
    super.initState();
    wakeUpTimeController.text = "${globals.idleTimerWakeup}";
    // equationController.text = "w * ((r-b)/(m-b)) * r";
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              const Text("Wakeup Timer (s)"),
              SizedBox(
                width: 100,
                child: 
              TextField(
                  textAlign: TextAlign.center,
                  controller: wakeUpTimeController,
                  obscureText: false,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    //alignLabelWithHint: true
                  ),
                  onChanged: (String s) async {
                    if (double.tryParse(s) != null) {
                      final SharedPreferences prefs = await _preferences;
                      globals.idleTimerWakeup = int.parse(s);
                      prefs.setInt('idleWakeTime', globals.idleTimerWakeup);
                    }
                  }
                ),
              ),
            ],),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text("Display mode"),
                SegmentedButton<DisplayMode>(
                      showSelectedIcon: false,
                      segments: const <ButtonSegment<DisplayMode>>[
                    ButtonSegment<DisplayMode>(
                        value: DisplayMode.light,
                        //label: Text('Free'),
                        icon: Icon(Icons.light_mode)),
                    ButtonSegment<DisplayMode>(
                        value: DisplayMode.dark,
                        //label: Text('Machine',softWrap: false, overflow: TextOverflow.fade),
                        icon: Icon(Icons.dark_mode)),
],
                  selected: <DisplayMode>{selectedMode},
                  onSelectionChanged: (Set<DisplayMode> s) {
                    setState(() {
                      selectedMode = s.first;
                    });
                  }),
              ]),
               Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              const Text("Score calculation"),
              Column(
                children: [
                  SegmentedButton<DisplayMode>(
                      showSelectedIcon: false,
                      segments: const <ButtonSegment<DisplayMode>>[
                    ButtonSegment<DisplayMode>(
                        value: DisplayMode.light,
                        label: Text('Equation'),
                        icon: Icon(Icons.calculate)),
                    ButtonSegment<DisplayMode>(
                        value: DisplayMode.dark,
                        label: Text('Records'),
                        icon: Icon(Icons.arrow_outward))
                      ],
                  selected: <DisplayMode>{selectedMode},
                  onSelectionChanged: (Set<DisplayMode> s) {
                    setState(() {
                      selectedMode = s.first;
                    });
                  }),
              ])
            ],),
            const Spacer(flex: 3,),
            const Divider(),
            const Text("Export App-Data"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              TextButton.icon(
                style: const ButtonStyle(),
                label: const Text('Training Sets'),
                icon: const Icon(Icons.save),
                onPressed: () {
                  backupSetState(context);
                },
              ),
              TextButton.icon(
                style: const ButtonStyle(),
                label: const Text('Exercises List'),
                icon: const Icon(Icons.save),
                onPressed: () {
                  backupExercises(context);
                },
              ),
            ]),
            const Divider(),
            const Spacer(),
            const Divider(),
            const Text("Wipe App-Data"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              TextButton.icon(
                style: const ButtonStyle(),
                label: const Text('Training Sets'),
                icon: const Icon(Icons.delete_forever),
                onPressed: () {
                  wipeTrainingSets(context);
                },
              ),
              TextButton.icon(
                style: const ButtonStyle(),
                label: const Text('Exercise List'),
                icon: const Icon(Icons.delete_forever),
                onPressed: () {
                  wipeExercises(context);
                }
              ),
              ]),
            const Divider(),
            const Spacer(),
            const Divider(),
            const Text("Restore App-Data"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  style: const ButtonStyle(),
                  label: const Text('Training Sets'),
                  icon: const Icon(Icons.restore_page),
                  onPressed: () {
                    restoreSetData(context);
                    Hive.box<Exercise>('Exercises').watch();
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
                  TextButton.icon(
                  style: const ButtonStyle(),
                  label: const Text('Exercises List'),
                  icon: const Icon(Icons.restore_page),
                  onPressed: () {
                    restoreExercises(context);
                    setState(() {});
                    Navigator.pop(context);
                    
                  },
                ),
            ]),
            const Divider(),
            const Spacer(),
          ]
        ),
    );
  }
}
