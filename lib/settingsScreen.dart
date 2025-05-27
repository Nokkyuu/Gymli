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
  if (await confirm(
    context,
    title: const Text('Clear Training Sets'),
    content: const Text(
        'Are you sure you want to permanently delete all training sets? This action cannot be undone.'),
  )) {
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Clearing training sets...'),
              ],
            ),
          );
        },
      );
    }

    try {
      print('Starting to clear training sets...');
      // Use the UserService which has the correct username handling
      final userService = UserService();

      // Get the correct username from UserService
      final currentUserName = userService.userName;
      print('Clearing training sets for user: $currentUserName');

      // Use the UserService method which handles both API calls and in-memory data
      await userService.clearTrainingSets();
      print('Clear training sets completed successfully');

      // Wait a moment for the clear operation to fully complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify that training sets were actually cleared
      final remainingTrainingSets = await userService.getTrainingSets();
      print(
          'Remaining training sets after clear: ${remainingTrainingSets.length}');

      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        if (remainingTrainingSets.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Training sets cleared successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Warning: ${remainingTrainingSets.length} training sets may still remain'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing training sets: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

Future<void> wipeExercises(BuildContext context) async {
  if (await confirm(
    context,
    title: const Text('Clear Exercises'),
    content: const Text(
        'Are you sure you want to permanently delete all exercises? This action cannot be undone.'),
  )) {
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Clearing exercises...'),
              ],
            ),
          );
        },
      );
    }

    try {
      await UserService().clearExercises();

      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercises cleared successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing exercises: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

Future<void> wipeWorkouts(BuildContext context) async {
  if (await confirm(
    context,
    title: const Text('Clear Workouts'),
    content: const Text(
        'Are you sure you want to permanently delete all workouts? This action cannot be undone.'),
  )) {
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Clearing workouts...'),
              ],
            ),
          );
        },
      );
    }

    try {
      await UserService().clearWorkouts();

      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workouts cleared successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing workouts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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

  // Show loading dialog for training sets import
  if (dataType == "TrainingSets" && context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Importing training sets...'),
            ],
          ),
        );
      },
    );
  }

  try {
    await restoreData(dataType, importData, context);

    // Dismiss loading dialog if it was shown
    if (dataType == "TrainingSets" && context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$dataType import completed successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    print('Error in triggerLoad: $e');

    // Dismiss loading dialog if it was shown
    if (dataType == "TrainingSets" && context.mounted) {
      Navigator.of(context).pop();
    }

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

Future<void> restoreData(
    String dataType, String data, BuildContext context) async {
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

      // Update dialog to show preparation phase
      if (context.mounted) {
        // Update the dialog content to show preparation
        Navigator.of(context).pop(); // Close current dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Preparing training sets...'),
                ],
              ),
            );
          },
        );
      }

      // OPTIMIZATION: Fetch all exercises once and create lookup map
      print('Fetching exercises for ID resolution...');
      final exercises = await userService.getExercises();
      final Map<String, int> exerciseNameToIdMap = {};

      for (var exercise in exercises) {
        exerciseNameToIdMap[exercise['name']] = exercise['id'];
      }

      print(
          'Created exercise lookup map with ${exerciseNameToIdMap.length} exercises');

      // Prepare training sets for bulk import
      List<Map<String, dynamic>> trainingSetsToCreate = [];

      for (List<String> row in csvTable) {
        if (row.length >= 8) {
          try {
            // OPTIMIZED: Use lookup map instead of API call
            final exerciseId = exerciseNameToIdMap[row[0]];

            if (exerciseId != null) {
              trainingSetsToCreate.add({
                'exerciseId': exerciseId,
                'date': DateTime.parse(row[1]).toIso8601String(),
                'weight': double.parse(row[2]),
                'repetitions': int.parse(row[3]),
                'setType': int.parse(row[4]),
                'baseReps': int.parse(row[5]),
                'maxReps': int.parse(row[6]),
                'increment': double.parse(row[7]),
                'machineName': row.length > 8 ? row[8] : "",
              });
              print('Prepared training set for exercise: ${row[0]}');
            } else {
              print(
                  'Warning: Exercise "${row[0]}" not found, skipping training set');
              skippedCount++;
            }
          } catch (e) {
            print('Error preparing training set for exercise "${row[0]}": $e');
            skippedCount++;
          }
        } else {
          print('Skipping row with insufficient data: $row');
          skippedCount++;
        }
      }

      // Create training sets in bulk (batches of 1000) with progress updates
      if (trainingSetsToCreate.isNotEmpty) {
        print(
            'Creating ${trainingSetsToCreate.length} training sets in bulk...');

        int batchSize = 1000;
        int totalBatches = (trainingSetsToCreate.length / batchSize).ceil();

        for (int i = 0; i < trainingSetsToCreate.length; i += batchSize) {
          int endIndex = (i + batchSize < trainingSetsToCreate.length)
              ? i + batchSize
              : trainingSetsToCreate.length;

          List<Map<String, dynamic>> batch =
              trainingSetsToCreate.sublist(i, endIndex);

          int currentBatch = (i / batchSize).floor() + 1;

          // Update dialog to show current batch progress
          if (context.mounted) {
            Navigator.of(context).pop(); // Close current dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text('Importing batch $currentBatch of $totalBatches'),
                      const SizedBox(height: 10),
                      Text('${batch.length} training sets'),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: currentBatch / totalBatches,
                      ),
                    ],
                  ),
                );
              },
            );
          }

          try {
            await userService.createTrainingSetsBulk(batch);
            importedCount += batch.length;
            print(
                'Successfully imported batch of ${batch.length} training sets (${i + 1}-${endIndex} of ${trainingSetsToCreate.length})');
          } catch (e) {
            print('Error importing batch ${i + 1}-${endIndex}: $e');
            skippedCount += batch.length;
          }

          // Small delay to allow UI to update
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Final completion dialog
        if (context.mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Import Complete'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '✅ Successfully imported: $importedCount training sets'),
                    if (skippedCount > 0)
                      Text('⚠️ Skipped: $skippedCount items'),
                    const SizedBox(height: 10),
                    const Text(
                        'All training sets have been imported successfully!'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
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

/// Converts a string representation of a list back to a typed list
/// Example: "[item1, item2, item3]" -> ["item1", "item2", "item3"]
List<T> stringToList<T>(String input) {
  if (input.isEmpty || input == '[]') {
    return <T>[];
  }

  // Remove brackets and split by comma
  String cleaned = input.replaceAll('[', '').replaceAll(']', '').trim();
  if (cleaned.isEmpty) {
    return <T>[];
  }

  List<String> parts = cleaned.split(',').map((e) => e.trim()).toList();

  // Convert to the specified type
  if (T == String) {
    return parts.cast<T>();
  } else if (T == double) {
    return parts.map((e) => double.tryParse(e) ?? 0.0).toList().cast<T>();
  } else if (T == int) {
    return parts.map((e) => int.tryParse(e) ?? 0).toList().cast<T>();
  } else {
    // Default to string conversion
    return parts.cast<T>();
  }
}

/// List of muscle group names for mapping
const List<String> muscleGroupNames = [
  "Pectoralis major",
  "Trapezius",
  "Biceps",
  "Abdominals",
  "Front Delts",
  "Deltoids",
  "Back Delts",
  "Latissimus dorsi",
  "Triceps",
  "Gluteus maximus",
  "Hamstrings",
  "Quadriceps",
  "Calves"
];

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
