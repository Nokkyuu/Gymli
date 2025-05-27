/// Settings Screen - Application Configuration and Data Management
///
/// This screen provides comprehensive application settings, user preferences,
/// and data management capabilities for the Gymli fitness application.
///
/// Key features:
/// - User authentication management (login/logout)
/// - Display mode configuration (light/dark theme)
/// - Graph visualization preferences (simple/detailed)
/// - Data export functionality (CSV format)
/// - Data import capabilities from CSV files
/// - Training data management (clear/wipe options)
/// - Application preferences persistence
/// - File system operations for data backup/restore
/// - User account information display
/// - Confirmation dialogs for destructive operations
///
/// The screen serves as the central hub for customizing the application
/// experience and managing user data across different devices and sessions.
library;

// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:Gymli/user_service.dart';
import 'package:Gymli/api_models.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
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

  // Use file_picker for cross-platform file picking (including web)
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    allowMultiple: false,
  );

  if (result == null || result.files.isEmpty) {
    return;
  }

  // Read the file content - handle both web and mobile platforms
  if (result.files.first.bytes != null) {
    // Web platform - file content is available as bytes
    importData = String.fromCharCodes(result.files.first.bytes!);
  } else if (result.files.first.path != null) {
    // Mobile platforms - file content is available via file path
    importData = await File(result.files.first.path!).readAsString();
  } else {
    print('Error: Unable to read file content');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Unable to read file content'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  try {
    restoreData(dataType, importData);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$dataType import completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    print('Error in triggerLoad: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error importing $dataType: Some items may have failed. Check console for details.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
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

    int importedCount = 0;
    int skippedCount = 0;

    if (dataType == "TrainingSets") {
      // Clear existing training sets with better error handling
      print('Clearing existing training sets...');
      try {
        await userService.clearTrainingSets();
        print('Successfully cleared existing training sets.');
      } catch (e) {
        print('Warning: Error clearing training sets: $e');
        print('Continuing with import anyway...');
      }

      for (List<String> row in csvTable) {
        if (row.length >= 8) {
          try {
            // Use new helper method for name-based exercise resolution
            final exerciseId = await userService.getExerciseIdByName(row[0]);

            if (exerciseId != null) {
              await userService.createTrainingSet(
                exerciseId: exerciseId,
                date: DateTime.parse(row[1]).toIso8601String(),
                weight: double.parse(row[2]),
                repetitions: int.parse(row[3]),
                setType: int.parse(row[4]),
                baseReps: int.parse(row[5]),
                maxReps: int.parse(row[6]),
                increment: double.parse(row[7]),
                machineName: row.length > 8 ? row[8] : "",
              );
              importedCount++;
              print(
                  'Successfully imported training set for exercise: ${row[0]}');
            } else {
              print(
                  'Warning: Exercise "${row[0]}" not found, skipping training set');
              skippedCount++;
            }
          } catch (e) {
            print('Error importing training set for exercise "${row[0]}": $e');
            skippedCount++;
          }
        }
      }
    } else if (dataType == "Exercises") {
      // Clear existing exercises with better error handling
      print('Clearing existing exercises...');
      try {
        await userService.clearExercises();
        print('Successfully cleared existing exercises.');
      } catch (e) {
        print('Warning: Error clearing exercises: $e');
        print('Continuing with import anyway...');
      }

      for (List<String> row in csvTable) {
        if (row.length >= 7) {
          try {
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
            importedCount++;
            print('Successfully imported exercise: ${row[0]}');
          } catch (e) {
            print('Error importing exercise "${row[0]}": $e');
            skippedCount++;
          }
        }
      }
    } else if (dataType == "Workouts") {
      // Clear existing workouts with better error handling
      print('Clearing existing workouts...');
      try {
        await userService.clearWorkouts();
        print('Successfully cleared existing workouts.');
      } catch (e) {
        print('Warning: Error clearing workouts: $e');
        print('Continuing with import anyway...');
      }

      for (List<String> row in csvTable) {
        if (row.isNotEmpty) {
          try {
            final workoutName = row[0];
            List<Map<String, dynamic>> units = [];

            for (int i = 1; i < row.length; i++) {
              final unitStr = row[i].split(", ");
              if (unitStr.length >= 5) {
                // Use new helper method for name-based exercise resolution
                final exerciseId =
                    await userService.getExerciseIdByName(unitStr[0]);

                if (exerciseId != null) {
                  units.add({
                    'exercise_id': exerciseId,
                    'warmups': int.parse(unitStr[1]),
                    'worksets': int.parse(unitStr[2]),
                    'dropsets': int.parse(unitStr[3]),
                    'type': int.parse(unitStr[4]),
                  });
                  print(
                      'Added workout unit for exercise: ${unitStr[0]} with ${unitStr[1]} warmups, ${unitStr[2]} worksets, ${unitStr[3]} dropsets, type ${unitStr[4]}');
                } else {
                  print(
                      'Warning: Exercise "${unitStr[0]}" not found, skipping workout unit');
                  skippedCount++;
                }
              } else {
                print(
                    'Warning: Invalid workout unit format for row $i: ${row[i]}');
                skippedCount++;
              }
            }

            if (units.isNotEmpty) {
              try {
                final workoutData = await userService.createWorkout(
                  name: workoutName,
                  units: units,
                );
                importedCount++;
                print(
                    'Successfully imported workout: $workoutName with ${units.length} units (ID: ${workoutData['id']})');
              } catch (e) {
                print('Error creating workout $workoutName: $e');
                skippedCount++;
              }
            } else {
              print('Warning: No valid units found for workout: $workoutName');
              skippedCount++;
            }
          } catch (e) {
            print('Error importing workout "${row[0]}": $e');
            skippedCount++;
          }
        }
      }
    }

    // Print import summary
    print(
        '$dataType import completed: $importedCount imported, $skippedCount skipped');

    // If we have skipped items, log additional details
    if (skippedCount > 0) {
      print(
          'Warning: $skippedCount items were skipped due to errors. This is often due to missing dependencies or network issues.');
    }
  } catch (e) {
    print('Critical error during $dataType restore: $e');
    rethrow; // Re-throw to be caught by triggerLoad
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
                  //Navigator.pop(context);
                },
              ),
              TextButton.icon(
                label: const Text('Exercises'),
                icon: const FaIcon(FontAwesomeIcons.list, size: 13),
                onPressed: () {
                  triggerLoad(context, "Exercises");
                  //Navigator.pop(context);
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
