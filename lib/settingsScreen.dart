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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
enum DisplayMode { light, dark }
enum GraphMode { simple, detailed }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreen();
}

void wipe<T>(context, String dataName) async {
  if (await confirm(context)) {
    var box = Hive.box<T>(dataName);
    box.clear();
  }
}

void backup<T>(String dataName) async {
  List<List<String>> datalist = [];
  List<T> data = Hive.box<T>(dataName).values.toList();
  for (var t in data) { datalist.add((t as DataClass).toCSVString()); }
  String csvData = const ListToCsvConverter().convert(datalist);
  final String directory = (await getApplicationSupportDirectory()).path;
  final path = "$directory/${dataName}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv";
  final File file = File(path);
  await file.writeAsString(csvData);
  final params = SaveFileDialogParams(sourceFilePath: path);
  await FlutterFileDialog.saveFile(params: params);
}


void triggerLoad<T>(context, dataname) async {
  String importData;
  if (kIsWeb) {
    String filePath = dataname == "Exercises" ? 'csv/ex.csv' : 'csv/set.csv';
    importData = await rootBundle.loadString(filePath);
  } else {
    final filePath = await FlutterFileDialog.pickFile(params: const OpenFileDialogParams(dialogType: OpenFileDialogType.document, sourceType: SourceType.savedPhotosAlbum));
    if (filePath == null) { return; }
    importData =  await File(filePath).readAsString();
  }
  restoreData<T>(dataname, importData);

}
List<T> stringToList<T>(String str) {
  List<T> values = [];
  for (String e in str.split(";")) {
    if (e != "") { values.add((T == double ? double.parse(e) : e) as T); }
  }
  return values;
}

void restoreData<T>(String dataName, String data) async {
  List<List<String>> csvTable = const CsvToListConverter(shouldParseNumbers: false).convert(data);
  if (dataName == "TrainingSets") {  // can't imagine this is less ugly than template specilization
    final setBox = Hive.box<TrainingSet>(dataName);
    setBox.clear();
    for (List<String> row in csvTable) { setBox.add(TrainingSet(exercise: row[0], date: DateTime.parse(row[1]), weight: double.parse(row[2]), repetitions: int.parse(row[3]), setType: int.parse(row[4]), baseReps: int.parse(row[5]), maxReps: int.parse(row[6]), increment: double.parse(row[7]), machineName: row[7])); }
  } else if (dataName == "Exercises") {
    final exerciseBox = Hive.box<Exercise>('Exercises');
    exerciseBox .clear();
    for (List<String> row in csvTable) {
      exerciseBox.add(Exercise(name: row[0], type: int.parse(row[1]), muscleGroups: stringToList<String>(row[2]), muscleIntensities: stringToList<double>(row[3]), defaultRepBase: int.parse(row[4]), defaultRepMax: int.parse(row[5]), defaultIncrement: double.parse(row[6])));
    }
  } else if (dataName == "Workouts") {
    final workoutBox = Hive.box<Workout>("Workouts");
    workoutBox.clear();
    WorkoutUnit? unit;
    List<String> unitStr = [];
    for (List<String> row in csvTable) {  
      List<WorkoutUnit> units = [];   
      for (int i = 1; i < row.length;i++){
        unitStr = row[i].split(", ");
        unit = WorkoutUnit(exercise: unitStr[0], warmups: int.parse(unitStr[1]), worksets: int.parse(unitStr[2]), dropsets: int.parse(unitStr[3]), type: int.parse(unitStr[4]));
        units.add(unit);
      }
      workoutBox.add(Workout(name: row[0], units: units));
    }
  }
}


class _SettingsScreen extends State<SettingsScreen> {
  final wakeUpTimeController = TextEditingController();
  final graphNumberOfDays = TextEditingController();
  // final equationController = TextEditingController();
  final Future<SharedPreferences> _preferences = SharedPreferences.getInstance();
  DisplayMode selectedMode = DisplayMode.light;
  GraphMode selectedGraphMode = globals.detailedGraph ? GraphMode.detailed : GraphMode.simple;

  @override
  void initState() {
    super.initState();
    wakeUpTimeController.text = "${globals.idleTimerWakeup}";
    graphNumberOfDays.text = "${globals.graphNumberOfDays}";
    // equationController.text = "w * ((r-b)/(m-b)) * r";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              const Text("Graph days"),
              SizedBox(
                width: 100,
                child: 
              TextField(
                  textAlign: TextAlign.center,
                  controller: graphNumberOfDays,
                  obscureText: false,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    //alignLabelWithHint: true
                  ),
                  onChanged: (String s) async {
                    if (double.tryParse(s) != null) {
                      final SharedPreferences prefs = await _preferences;
                      globals.graphNumberOfDays = int.parse(s);
                      prefs.setInt('graphNumberOfDays', globals.graphNumberOfDays);
                    }
                  }
                ),
              ),
            ],),
            
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text("Graph display"),
                SegmentedButton<GraphMode>(
                      showSelectedIcon: false,
                      segments: const <ButtonSegment<GraphMode>>[
                    ButtonSegment<GraphMode>(
                        value: GraphMode.simple,
                        label: Text('Simple (max)'),
                        icon: FaIcon(FontAwesomeIcons.arrowTrendUp)),
                    ButtonSegment<GraphMode>(
                        value: GraphMode.detailed,
                        label: Text('Detailed'),
                        icon: FaIcon(FontAwesomeIcons.chartColumn))
                      ],
                  selected: <GraphMode>{selectedGraphMode},
                  onSelectionChanged: (Set<GraphMode> s) async {
                      setState(() {
                        selectedGraphMode = s.first;
                      });
                      final SharedPreferences prefs = await _preferences;
                      globals.detailedGraph =  s.first == GraphMode.simple ? false : true;
                      prefs.setBool('detailedGraph', s.first == GraphMode.simple ? false : true);
                  }),
              ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text("Display mode"),
                SegmentedButton<DisplayMode>(
                      showSelectedIcon: false,
                      segments: const <ButtonSegment<DisplayMode>>[
                        ButtonSegment<DisplayMode>(
                            value: DisplayMode.light,
                            icon: Icon(Icons.light_mode)),
                        ButtonSegment<DisplayMode>(
                            value: DisplayMode.dark,
                            icon: Icon(Icons.dark_mode)),
                        ],
                  selected: <DisplayMode>{selectedMode},
                  onSelectionChanged: (Set<DisplayMode> s) {
                    setState(() {
                      selectedMode = s.first;
                    });
                  }),
              ]),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [FaIcon(FontAwesomeIcons.list, size: 13), SizedBox(width: 10), Text("Export App-Data")]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              TextButton.icon(
                label: const Text('Trainings'),
                icon: const FaIcon(FontAwesomeIcons.chartLine, size: 13),
                onPressed: () {  backup<TrainingSet>("TrainingSets"); },
              ),
              TextButton.icon(
                label: const Text('Exercises'),
                icon: const FaIcon(FontAwesomeIcons.list, size: 13),
                onPressed: () { backup<Exercise>("Exercises"); },
              ),
              TextButton.icon(
                label: const Text('Workouts'),
                icon: const FaIcon(FontAwesomeIcons.clipboardList, size: 13),
                onPressed: () { backup<Workout>("Workouts"); },
              ),
            ]),
            const SizedBox(height: 10),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.restore_page, size: 13), SizedBox(width: 10), Text("Import App-Data")]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  label: const Text('Trainings'),
                  icon: const FaIcon(FontAwesomeIcons.chartLine, size: 13),
                  onPressed: () { triggerLoad<TrainingSet>(context, "TrainingSets"); Navigator.pop(context); },
                ),
                  TextButton.icon(
                  label: const Text('Exercises'),
                  icon: const FaIcon(FontAwesomeIcons.list, size: 13),
                  onPressed: () { triggerLoad<Exercise>(context, "Exercises"); Navigator.pop(context); },
                ),
                TextButton.icon(
                    label: const Text('Workouts'),
                    icon: const FaIcon(FontAwesomeIcons.clipboardList, size: 13),
                    onPressed: () { triggerLoad<Workout>(context, "Workouts"); },
                  ),
            ]),
            const SizedBox(height: 10),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_forever, size: 13), SizedBox(width: 10), Text(" Wipe App-Data")]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              TextButton.icon(
                label: const Text('Trainings'),
                icon: const FaIcon(FontAwesomeIcons.chartLine, size: 13),
                onPressed: () { wipe<TrainingSet>(context, "TrainingSets"); },
              ),
              TextButton.icon(
                label: const Text('Exercises'),
                icon: const FaIcon(FontAwesomeIcons.list, size: 13),
                onPressed: () { wipe<Exercise>(context, "Exercises"); }
              ),
              TextButton.icon(
                label: const Text('Workouts'),
                icon: const FaIcon(FontAwesomeIcons.clipboardList, size: 13),
                onPressed: () { wipe<Workout>(context, "Workouts"); }
              ),
              ]),
            const Spacer(),
          ]
        ),
    );
  }
}
