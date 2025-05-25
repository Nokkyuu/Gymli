/**
 * Settings Screen - Application Configuration and Data Management
 * 
 * This screen provides comprehensive application settings, user preferences,
 * and data management capabilities for the Gymli fitness application.
 * 
 * Key features:
 * - User authentication management (login/logout)
 * - Display mode configuration (light/dark theme)
 * - Graph visualization preferences (simple/detailed)
 * - Data export functionality (CSV format)
 * - Data import capabilities from CSV files
 * - Training data management (clear/wipe options)
 * - Application preferences persistence
 * - File system operations for data backup/restore
 * - User account information display
 * - Confirmation dialogs for destructive operations
 * 
 * The screen serves as the central hub for customizing the application
 * experience and managing user data across different devices and sessions.
 */

// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:Gymli/user_service.dart';
import 'package:Gymli/api_models.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
//import 'package/file_picker/file_picker.dart';
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

Future<void> wipeTrainingSets(BuildContext context) async {
  if (await confirm(context)) {
    try {
      await UserService().clearTrainingSets();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training sets cleared successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing training sets: $e')),
        );
      }
    }
  }
}

Future<void> wipeExercises(BuildContext context) async {
  if (await confirm(context)) {
    try {
      await UserService().clearExercises();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercises cleared successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing exercises: $e')),
        );
      }
    }
  }
}

Future<void> wipeWorkouts(BuildContext context) async {
  if (await confirm(context)) {
    try {
      await UserService().clearWorkouts();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workouts cleared successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing workouts: $e')),
        );
      }
    }
  }
}

void backup(String dataType) async {
  try {
    final userService = UserService();
    List<List<String>> datalist = [];

    if (dataType == "TrainingSets") {
      final trainingSets = await userService.getTrainingSets();
      for (var ts in trainingSets) {
        final apiTrainingSet = ApiTrainingSet.fromJson(ts);
        datalist.add(apiTrainingSet.toCSVString());
      }
    } else if (dataType == "Exercises") {
      final exercises = await userService.getExercises();
      for (var ex in exercises) {
        final apiExercise = ApiExercise.fromJson(ex);
        datalist.add(apiExercise.toCSVString());
      }
    } else if (dataType == "Workouts") {
      final workouts = await userService.getWorkouts();
      for (var wo in workouts) {
        final apiWorkout = ApiWorkout.fromJson(wo);
        datalist.add(apiWorkout.toCSVString());
      }
    }

    String csvData = const ListToCsvConverter().convert(datalist);
    final String directory = (await getApplicationSupportDirectory()).path;
    final path =
        "$directory/${dataType}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv";
    final File file = File(path);
    await file.writeAsString(csvData);
    final params = SaveFileDialogParams(sourceFilePath: path);
    await FlutterFileDialog.saveFile(params: params);
  } catch (e) {
    print('Error during backup: $e');
  }
}

void triggerLoad(context, dataType) async {
  String importData;
  if (kIsWeb) {
    String filePath = dataType == "Exercises" ? 'csv/ex.csv' : 'csv/set.csv';
    importData = await rootBundle.loadString(filePath);
  } else {
    final filePath = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(
            dialogType: OpenFileDialogType.document,
            sourceType: SourceType.savedPhotosAlbum));
    if (filePath == null) {
      return;
    }
    importData = await File(filePath).readAsString();
  }
  restoreData(dataType, importData);
}

List<T> stringToList<T>(String str) {
  List<T> values = [];
  for (String e in str.split(";")) {
    if (e != "") {
      values.add((T == double ? double.parse(e) : e) as T);
    }
  }
  return values;
}

void restoreData(String dataType, String data) async {
  try {
    final userService = UserService();
    List<List<String>> csvTable =
        const CsvToListConverter(shouldParseNumbers: false).convert(data);

    if (dataType == "TrainingSets") {
      // Clear existing training sets
      await userService.clearTrainingSets();

      for (List<String> row in csvTable) {
        if (row.length >= 8) {
          // Find exercise ID by name - need to get exercises first
          final exercises = await userService.getExercises();
          final exerciseData = exercises.firstWhere(
            (item) => item['name'] == row[0],
            orElse: () => null,
          );

          if (exerciseData != null) {
            await userService.createTrainingSet(
              exerciseId: exerciseData['id'],
              date: DateTime.parse(row[1]).toIso8601String(),
              weight: double.parse(row[2]),
              repetitions: int.parse(row[3]),
              setType: int.parse(row[4]),
              baseReps: int.parse(row[5]),
              maxReps: int.parse(row[6]),
              increment: double.parse(row[7]),
              machineName: row.length > 8 ? row[8] : "",
            );
          }
        }
      }
    } else if (dataType == "Exercises") {
      // Clear existing exercises
      await userService.clearExercises();

      for (List<String> row in csvTable) {
        if (row.length >= 7) {
          final muscleGroups = stringToList<String>(row[2]);
          final muscleIntensities = stringToList<double>(row[3]);

          // Map muscle groups to individual muscle fields
          final Map<String, double> muscleMap = {};
          for (int i = 0; i < muscleGroupNames.length; i++) {
            String muscleKey = muscleGroupNames[i];
            double intensity = 0.0;

            int muscleIndex = muscleGroups.indexOf(muscleKey);
            if (muscleIndex >= 0 && muscleIndex < muscleIntensities.length) {
              intensity = muscleIntensities[muscleIndex];
            }
            muscleMap[muscleKey] = intensity;
          }

          await userService.createExercise(
            name: row[0],
            type: int.parse(row[1]),
            defaultRepBase: int.parse(row[4]),
            defaultRepMax: int.parse(row[5]),
            defaultIncrement: double.parse(row[6]),
            pectoralisMajor: muscleMap["Pectoralis major"] ?? 0.0,
            trapezius: muscleMap["Trapezius"] ?? 0.0,
            biceps: muscleMap["Biceps"] ?? 0.0,
            abdominals: muscleMap["Abdominals"] ?? 0.0,
            frontDelts: muscleMap["Front Delts"] ?? 0.0,
            deltoids: muscleMap["Deltoids"] ?? 0.0,
            backDelts: muscleMap["Back Delts"] ?? 0.0,
            latissimusDorsi: muscleMap["Latissimus dorsi"] ?? 0.0,
            triceps: muscleMap["Triceps"] ?? 0.0,
            gluteusMaximus: muscleMap["Gluteus maximus"] ?? 0.0,
            hamstrings: muscleMap["Hamstrings"] ?? 0.0,
            quadriceps: muscleMap["Quadriceps"] ?? 0.0,
            calves: muscleMap["Calves"] ?? 0.0,
          );
        }
      }
    } else if (dataType == "Workouts") {
      // Clear existing workouts
      await userService.clearWorkouts();

      for (List<String> row in csvTable) {
        if (row.isNotEmpty) {
          final workoutName = row[0];
          List<Map<String, dynamic>> units = [];

          for (int i = 1; i < row.length; i++) {
            final unitStr = row[i].split(", ");
            if (unitStr.length >= 5) {
              // Find exercise ID by name
              final exercises = await userService.getExercises();
              final exerciseData = exercises.firstWhere(
                (item) => item['name'] == unitStr[0],
                orElse: () => null,
              );

              if (exerciseData != null) {
                units.add({
                  'exercise_id': exerciseData['id'],
                  'warmups': int.parse(unitStr[1]),
                  'worksets': int.parse(unitStr[2]),
                  'dropsets': int.parse(unitStr[3]),
                  'type': int.parse(unitStr[4]),
                });
              }
            }
          }

          if (units.isNotEmpty) {
            await userService.createWorkout(
              name: workoutName,
              units: units,
            );
          }
        }
      }
    }
  } catch (e) {
    print('Error during restore: $e');
  }
}

class _SettingsScreen extends State<SettingsScreen> {
  final wakeUpTimeController = TextEditingController();
  final graphNumberOfDays = TextEditingController();
  // final equationController = TextEditingController();
  final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();
  DisplayMode selectedMode = DisplayMode.light;
  GraphMode selectedGraphMode =
      globals.detailedGraph ? GraphMode.detailed : GraphMode.simple;

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
                  child: TextField(
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
                      }),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text("Graph days"),
                SizedBox(
                  width: 100,
                  child: TextField(
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
                          prefs.setInt(
                              'graphNumberOfDays', globals.graphNumberOfDays);
                        }
                      }),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
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
                    globals.detailedGraph =
                        s.first == GraphMode.simple ? false : true;
                    prefs.setBool('detailedGraph',
                        s.first == GraphMode.simple ? false : true);
                  }),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              const Text("Display mode"),
              SegmentedButton<DisplayMode>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<DisplayMode>>[
                    ButtonSegment<DisplayMode>(
                        value: DisplayMode.light, icon: Icon(Icons.light_mode)),
                    ButtonSegment<DisplayMode>(
                        value: DisplayMode.dark, icon: Icon(Icons.dark_mode)),
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
                Column(children: [
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
              ],
            ),
            const Spacer(
              flex: 3,
            ),
            const Divider(),
            const SizedBox(height: 10),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FaIcon(FontAwesomeIcons.list, size: 13),
              SizedBox(width: 10),
              Text("Export App-Data")
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                label: const Text('Trainings'),
                icon: const FaIcon(FontAwesomeIcons.chartLine, size: 13),
                onPressed: () {
                  backup("TrainingSets");
                },
              ),
              TextButton.icon(
                label: const Text('Exercises'),
                icon: const FaIcon(FontAwesomeIcons.list, size: 13),
                onPressed: () {
                  backup("Exercises");
                },
              ),
              TextButton.icon(
                label: const Text('Workouts'),
                icon: const FaIcon(FontAwesomeIcons.clipboardList, size: 13),
                onPressed: () {
                  backup("Workouts");
                },
              ),
            ]),
            const SizedBox(height: 10),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.restore_page, size: 13),
              SizedBox(width: 10),
              Text("Import App-Data")
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                label: const Text('Trainings'),
                icon: const FaIcon(FontAwesomeIcons.chartLine, size: 13),
                onPressed: () {
                  triggerLoad(context, "TrainingSets");
                  Navigator.pop(context);
                },
              ),
              TextButton.icon(
                label: const Text('Exercises'),
                icon: const FaIcon(FontAwesomeIcons.list, size: 13),
                onPressed: () {
                  triggerLoad(context, "Exercises");
                  Navigator.pop(context);
                },
              ),
              TextButton.icon(
                label: const Text('Workouts'),
                icon: const FaIcon(FontAwesomeIcons.clipboardList, size: 13),
                onPressed: () {
                  triggerLoad(context, "Workouts");
                },
              ),
            ]),
            const SizedBox(height: 10),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.delete_forever, size: 13),
              SizedBox(width: 10),
              Text(" Wipe App-Data")
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                label: const Text('Trainings'),
                icon: const FaIcon(FontAwesomeIcons.chartLine, size: 13),
                onPressed: () {
                  wipeTrainingSets(context);
                },
              ),
              TextButton.icon(
                  label: const Text('Exercises'),
                  icon: const FaIcon(FontAwesomeIcons.list, size: 13),
                  onPressed: () {
                    wipeExercises(context);
                  }),
              TextButton.icon(
                  label: const Text('Workouts'),
                  icon: const FaIcon(FontAwesomeIcons.clipboardList, size: 13),
                  onPressed: () {
                    wipeWorkouts(context);
                  }),
            ]),
            const Spacer(),
          ]),
    );
  }
}
