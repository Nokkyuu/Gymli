///Settings Screen, accessed from the navigation drawer.
///Contains import and export functionality.
///possibile usage for more user specific customizing settings
///
library;

import 'package:flutter/material.dart';
//import 'package:flutter/services.dart'; // Add this for Clipboard
//import 'package:Gymli/utils/services/user_service.dart';
import 'package:Gymli/utils/services/service_container.dart';
import 'package:Gymli/utils/api/api_models.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import '../utils/globals.dart' as globals;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert'; // Add this import for utf8
import 'package:flutter/foundation.dart'; // Add this import for kIsWeb
//import 'dart:math' as Math;
import '../utils/info_dialogues.dart';
import 'dart:html' as html;
//import 'dart:convert';

//TODO: More robust import and export funcitonality, more modular for future use with direct imports from a workout ladder system.

enum DisplayMode { light, dark }

enum GraphMode { simple, detailed }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreen();
}

void downloadCsv(String csvData, String fileName) {
  final bytes = utf8.encode(csvData);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
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
      if (kDebugMode) print('Starting to clear training sets...');
      // Use the UserService which has the correct username handling
      final container = ServiceContainer();

      // Get the correct username from UserService
      final currentUserName = container.authService.userName;
      if (kDebugMode)
        print('Clearing training sets for user: $currentUserName');

      // Use the UserService method which handles both API calls and in-memory data
      await container.trainingSetService.clearTrainingSets();
      if (kDebugMode) print('Clear training sets completed successfully');

      // Wait a moment for the clear operation to fully complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify that training sets were actually cleared
      final remainingTrainingSets =
          await container.trainingSetService.getTrainingSets();
      if (kDebugMode)
        print(
            'Remaining training sets after clear: ${remainingTrainingSets.length}');

      // Dismiss loading dialog
      // Notify that data has changed
      container.dataService.notifyDataChanged();

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
        'Are you sure you want to permanently delete all exercises?\n\nATTENTION:\nThis will also delete all Training Sets and Workout !\n\nThis action cannot be undone.'),
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
      await container.workoutService.clearWorkouts();
      await container.trainingSetService.clearTrainingSets();
      await container.exerciseService.clearExercises();

      // Notify that data has changed
      container.dataService.notifyDataChanged();

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
      await container.workoutService.clearWorkouts();
      // Notify that data has changed
      container.dataService.notifyDataChanged();

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

Future<void> backup(String dataType, BuildContext context) async {
  try {
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text('Exporting $dataType...'),
              ],
            ),
          );
        },
      );
    }

    final container = ServiceContainer(); //TODO: Check for redundancy
    List<List<String>> datalist = [];

    print('Starting backup for $dataType...');

    if (dataType == "TrainingSets") {
      final trainingSets = await container.trainingSetService.getTrainingSets();
      if (kDebugMode) print('Retrieved ${trainingSets.length} training sets');

      for (var ts in trainingSets) {
        try {
          final apiTrainingSet = ApiTrainingSet.fromJson(ts);
          datalist.add(apiTrainingSet.toCSVString());
        } catch (e) {
          if (kDebugMode) print('Error converting training set to CSV: $e');
        }
      }
    } else if (dataType == "Exercises") {
      final exercises = await container.exerciseService.getExercises();
      if (kDebugMode) print('Retrieved ${exercises.length} exercises');

      for (var ex in exercises) {
        try {
          final apiExercise = ApiExercise.fromJson(ex);
          datalist.add(apiExercise.toCSVString());
        } catch (e) {
          if (kDebugMode) print('Error converting exercise to CSV: $e');
        }
      }
    } else if (dataType == "Workouts") {
      final workouts = await container.workoutService.getWorkouts();
      if (kDebugMode) print('Retrieved ${workouts.length} workouts');

      for (var wo in workouts) {
        try {
          final apiWorkout = ApiWorkout.fromJson(wo);
          datalist.add(apiWorkout.toCSVString());
        } catch (e) {
          if (kDebugMode) print('Error converting workout to CSV: $e');
        }
      }
    } else if (dataType == "Foods") {
      final foods = await container.foodService.getFoods();
      if (kDebugMode) print('Retrieved ${foods.length} foods');

      for (var food in foods) {
        try {
          final apiFood = ApiFood.fromJson(food);
          datalist.add(apiFood.toCSVString());
        } catch (e) {
          if (kDebugMode) print('Error converting food to CSV: $e');
        }
      }
    }

    if (datalist.isEmpty) {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No $dataType data to export'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (kDebugMode) print('Converting ${datalist.length} items to CSV...');

    // IMPROVED: Use proper CSV formatting with explicit line endings
    String csvData = const ListToCsvConverter(
      eol: '\n', // Force Unix line endings
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(datalist);

    // ADDED: Ensure the CSV ends with a newline
    if (!csvData.endsWith('\n')) {
      csvData += '\n';
    }

    final fileName =
        "${dataType}_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv";

    if (kDebugMode) print('Starting file save process...');

    if (kIsWeb) {
      // Web-specific implementation
      try {
        if (kDebugMode) print('Using web download approach...');

        // Convert string to bytes with explicit UTF-8 encoding
        final bytes = utf8.encode(csvData);

        // Try direct save with just bytes and filename
        final params = SaveFileDialogParams(
          data: bytes,
          fileName: fileName,
          mimeTypesFilter: ['text/csv'], // ADDED: Specify MIME type
        );
        downloadCsv(csvData, fileName);
        final result = await FlutterFileDialog.saveFile(params: params);

        // Dismiss loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();

          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$dataType exported successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Export cancelled by user'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (webError) {
        if (kDebugMode) print('Web export failed: $webError');

        // Fallback: try to trigger browser download
        try {
          if (kDebugMode) print('Attempting browser download fallback...');

          if (context.mounted) {
            Navigator.of(context).pop(); // Close loading dialog

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('$dataType Export Data'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        csvData,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                    // TextButton(
                    //   onPressed: () async {
                    //     // Copy to clipboard
                    //     await Clipboard.setData(ClipboardData(text: csvData));
                    //     Navigator.of(context).pop();
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(
                    //         content: Text(
                    //             'CSV data copied to clipboard - paste into a text editor and save as .csv'),
                    //         backgroundColor: Colors.green,
                    //         duration: Duration(seconds: 5),
                    //       ),
                    //     );
                    //   },
                    //   child: const Text('Copy to Clipboard'),
                    // ),
                  ],
                );
              },
            );
          }
        } catch (fallbackError) {
          if (kDebugMode) print('Fallback also failed: $fallbackError');
          rethrow;
        }
      }
    } else {
      // Mobile platform implementation
      try {
        if (kDebugMode) print('Using mobile file system approach...');

        // Get platform-appropriate directory
        final directory = (await getApplicationSupportDirectory()).path;
        final path = "$directory/$fileName";

        if (kDebugMode) print('Creating file at: $path');

        final File file = File(path);
        // IMPROVED: Write with explicit UTF-8 encoding
        await file.writeAsString(csvData, encoding: utf8);
        if (kDebugMode) print('File written successfully');

        // Save file dialog
        final params = SaveFileDialogParams(
          sourceFilePath: path,
          fileName: fileName,
          mimeTypesFilter: ['text/csv'], // ADDED: Specify MIME type
        );

        final result = await FlutterFileDialog.saveFile(params: params);

        // Dismiss loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();

          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$dataType exported successfully to $result'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Export cancelled by user'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (mobileError) {
        print('Mobile export failed: $mobileError');
        rethrow;
      }
    }
  } catch (e) {
    print('Error during backup: $e');
    print('Stack trace: ${StackTrace.current}');

    // Dismiss loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting $dataType: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

void triggerLoad(context, dataType) async {
  // Show confirmation dialog before proceeding
  bool confirmed = false;
  if (context.mounted) {
    confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Import $dataType'),
              content: dataType == "Exercises"
                  ? Text(
                      'Importing $dataType will permanently delete all existing $dataType, Training Sets and Workout data. This action cannot be undone. Do you want to continue?')
                  : Text(
                      'Importing $dataType will permanently delete all existing $dataType data. This action cannot be undone. Do you want to continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  if (!confirmed) {
    return;
  }

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

  // Show loading dialog for all import types
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text('Importing $dataType...'),
            ],
          ),
        );
      },
    );
  }

  try {
    await restoreData(dataType, importData, context);
    // Notify that data has changed
    container.dataService.notifyDataChanged();

    // Dismiss loading dialog
    if (context.mounted) {
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

    // Dismiss loading dialog
    if (context.mounted) {
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
    final container = ServiceContainer();
    List<List<String>> csvTable = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n', // Force Unix line endings
      fieldDelimiter: ';',
      textDelimiter: '"',
      textEndDelimiter: '"',
    ).convert(data);

    int importedCount = 0;
    int skippedCount = 0;

    if (dataType == "TrainingSets") {
      // Clear existing training sets with better error handling
      print('Clearing existing training sets...');
      try {
        await container.trainingSetService.clearTrainingSets();
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
      final exercises = await container.exerciseService.getExercises();
      final Map<String, int> exerciseNameToIdMap = {};

      for (var exercise in exercises) {
        exerciseNameToIdMap[exercise['name']] = exercise['id'];
      }

      print(
          'Created exercise lookup map with ${exerciseNameToIdMap.length} exercises');

      // Prepare training sets for bulk import
      List<Map<String, dynamic>> trainingSetsToCreate = [];

      for (List<String> row in csvTable) {
        // Remove all trailing empty columns
        while (row.isNotEmpty && row.last.trim().isEmpty) {
          row.removeLast();
        }

        if (row.length == 5) {
          try {
            final exerciseId = exerciseNameToIdMap[row[0].trim()];

            if (exerciseId != null) {
              trainingSetsToCreate.add({
                'exerciseId': exerciseId,
                'date': DateTime.parse(row[1]).toIso8601String(),
                'weight': double.parse(row[2]),
                'repetitions': int.parse(row[3]),
                'setType': int.parse(row[4]),
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
          print('Skipping row with wrong data: $row');
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
            await container.trainingSetService.createTrainingSetsBulk(batch);
            importedCount += batch.length;
            if (kDebugMode)
              print(
                  'Successfully imported batch of ${batch.length} training sets (${i + 1}-${endIndex} of ${trainingSetsToCreate.length})');
          } catch (e) {
            if (kDebugMode)
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
        await container.trainingSetService.clearTrainingSets();
        await container.workoutService.clearWorkouts();
        await container.exerciseService.clearExercises();
        if (kDebugMode) print('Successfully cleared existing exercises.');
      } catch (e) {
        if (kDebugMode) print('Warning: Error clearing exercises: $e');
        if (kDebugMode) print('Continuing with import anyway...');
      }

      // Update dialog to show total count
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
                  Text('Importing ${csvTable.length} exercises...'),
                  const SizedBox(height: 10),
                  const Text('Please wait...'),
                ],
              ),
            );
          },
        );
      }

      for (int index = 0; index < csvTable.length; index++) {
        List<String> row =
            csvTable[index].map((e) => e is String ? e.trim() : e).toList();
        ;

        // Update progress every 10 exercises
        if (index % 10 == 0 && context.mounted) {
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
                    Text('Importing exercises...'),
                    const SizedBox(height: 10),
                    Text('${index + 1} of ${csvTable.length}'),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (index + 1) / csvTable.length,
                    ),
                  ],
                ),
              );
            },
          );
        }

        if (row.length >= 6) {
          try {
            // Parse muscle intensities directly - no names needed
            // NOTE: THIS NEEDS TO BE CAREFULLY ADJUSTED IF THE MUSCLE GROUPS ARE EVER TO CHANGE
            final muscleIntensities = parseCSVMuscleIntensities(row[2]);

            // Ensure we have exactly 14 values (pad with 0.0 if needed)
            // while (muscleIntensities.length < 14) {
            //   muscleIntensities.add(0.0);
            // }

            await container.exerciseService.createExercise(
              name: row[0],
              type: int.parse(row[1]),
              defaultRepBase: int.parse(row[3]),
              defaultRepMax: int.parse(row[4]),
              defaultIncrement: double.parse(row[5]),
              pectoralisMajor: muscleIntensities[0],
              trapezius: muscleIntensities[1],
              biceps: muscleIntensities[2],
              abdominals: muscleIntensities[3],
              frontDelts: muscleIntensities[4],
              deltoids: muscleIntensities[5],
              backDelts: muscleIntensities[6],
              latissimusDorsi: muscleIntensities[7],
              triceps: muscleIntensities[8],
              gluteusMaximus: muscleIntensities[9],
              hamstrings: muscleIntensities[10],
              quadriceps: muscleIntensities[11],
              forearms: muscleIntensities[12],
              calves: muscleIntensities[13],
            );
            importedCount++;
            print('Successfully imported exercise: ${row[0]}');
          } catch (e) {
            print('Error importing exercise "${row[0]}": $e');
            skippedCount++;
          }
        }
      }

      // Show completion dialog for exercises
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Exercise Import Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Successfully imported: $importedCount exercises'),
                  if (skippedCount > 0) Text('⚠️ Skipped: $skippedCount items'),
                  const SizedBox(height: 10),
                  const Text('All exercises have been imported successfully!'),
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
    } else if (dataType == "Workouts") {
      // Clear existing workouts with better error handling
      if (kDebugMode) print('Clearing existing workouts...');
      try {
        await container.workoutService.clearWorkouts();
        if (kDebugMode) print('Successfully cleared existing workouts.');
      } catch (e) {
        if (kDebugMode) print('Warning: Error clearing workouts: $e');
        if (kDebugMode) print('Continuing with import anyway...');
      }

      // Update dialog to show total count
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
                  Text('Importing ${csvTable.length} workouts...'),
                  const SizedBox(height: 10),
                  const Text('Please wait...'),
                ],
              ),
            );
          },
        );
      }

      for (int index = 0; index < csvTable.length; index++) {
        List<String> row =
            csvTable[index].map((e) => e is String ? e.trim() : e).toList();
        ;

        // Update progress for each workout
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
                    Text('Importing workouts...'),
                    const SizedBox(height: 10),
                    Text('${index + 1} of ${csvTable.length}'),
                    const SizedBox(height: 5),
                    if (row.isNotEmpty)
                      Text(
                        'Current: ${row[0]}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (index + 1) / csvTable.length,
                    ),
                  ],
                ),
              );
            },
          );
        }

        if (row.isNotEmpty) {
          try {
            final workoutName = row[0];
            List<Map<String, dynamic>> units = [];

            for (int i = 1; i < row.length; i++) {
              final unitStr = row[i].split(", ");
              if (unitStr.length >= 5) {
                // Use new helper method for name-based exercise resolution
                final exerciseId = await container.exerciseService
                    .getExerciseIdByName(unitStr[0]);

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
                final workoutData =
                    await container.workoutService.createWorkout(
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

      // Show completion dialog for workouts
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Workout Import Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Successfully imported: $importedCount workouts'),
                  if (skippedCount > 0) Text('⚠️ Skipped: $skippedCount items'),
                  const SizedBox(height: 10),
                  const Text('All workouts have been imported successfully!'),
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
    } else if (dataType == "Foods") {
      // Clear existing food data with better error handling
      if (kDebugMode) print('Clearing existing food data...');
      try {
        await container.foodService.clearFoodData();
        if (kDebugMode) print('Successfully cleared existing food data.');
      } catch (e) {
        if (kDebugMode) print('Warning: Error clearing food data: $e');
        if (kDebugMode) print('Continuing with import anyway...');
      }

      // Update dialog to show total count
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
                  Text('Importing ${csvTable.length} food items...'),
                  const SizedBox(height: 10),
                  const Text('Please wait...'),
                ],
              ),
            );
          },
        );
      }

      // Prepare food items for bulk import
      List<Map<String, dynamic>> foodsToCreate = [];

      for (int index = 0; index < csvTable.length; index++) {
        List<String> row =
            csvTable[index].map((e) => e is String ? e.trim() : e).toList();

        // Update progress every 10 foods
        if (index % 10 == 0 && context.mounted) {
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
                    Text('Preparing food items...'),
                    const SizedBox(height: 10),
                    Text('${index + 1} of ${csvTable.length}'),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (index + 1) / csvTable.length,
                    ),
                  ],
                ),
              );
            },
          );
        }

        if (row.length >= 5) {
          try {
            foodsToCreate.add({
              'name': row[0],
              'kcalPer100g': double.parse(row[1]),
              'proteinPer100g': double.parse(row[2]),
              'carbsPer100g': double.parse(row[3]),
              'fatPer100g': double.parse(row[4]),
              'notes': row.length > 5 ? row[5] : null,
            });
            print('Prepared food item: ${row[0]}');
          } catch (e) {
            print('Error preparing food item "${row[0]}": $e');
            skippedCount++;
          }
        } else {
          print('Skipping row with insufficient data: $row');
          skippedCount++;
        }
      }

      // Create food items in bulk (batches of 1000) with progress updates
      if (foodsToCreate.isNotEmpty) {
        print('Creating ${foodsToCreate.length} food items in bulk...');

        int batchSize = 1000;
        int totalBatches = (foodsToCreate.length / batchSize).ceil();

        for (int i = 0; i < foodsToCreate.length; i += batchSize) {
          int endIndex = (i + batchSize < foodsToCreate.length)
              ? i + batchSize
              : foodsToCreate.length;

          List<Map<String, dynamic>> batch = foodsToCreate.sublist(i, endIndex);
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
                      Text('${batch.length} food items'),
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
            await container.foodService.createFoodsBulk(batch);
            importedCount += batch.length;
            print(
                'Successfully imported batch of ${batch.length} food items (${i + 1}-${endIndex} of ${foodsToCreate.length})');
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
                title: const Text('Food Import Complete'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ Successfully imported: $importedCount food items'),
                    if (skippedCount > 0)
                      Text('⚠️ Skipped: $skippedCount items'),
                    const SizedBox(height: 10),
                    const Text(
                        'All food items have been imported successfully!'),
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

/// Parses muscle groups from CSV format (semicolon-separated)
List<String> parseCSVMuscleGroups(String input) {
  if (input.isEmpty || input.trim().isEmpty) {
    return <String>[];
  }

  // Remove any brackets and split by semicolon
  String cleaned = input.replaceAll('[', '').replaceAll(']', '').trim();
  if (cleaned.isEmpty) {
    return <String>[];
  }

  // Split by semicolon and filter out empty strings
  List<String> parts = cleaned
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  return parts;
}

/// Parses muscle intensities from CSV format (comma-separated)
List<double> parseCSVMuscleIntensities(String input) {
  if (input.isEmpty || input.trim().isEmpty) {
    return <double>[];
  }

  // Remove any brackets and split by comma
  String cleaned = input.replaceAll('[', '').replaceAll(']', '').trim();
  if (cleaned.isEmpty) {
    return <double>[];
  }

  // Split by COMMA, not empty string!
  List<double> parts = cleaned
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .map((e) => double.tryParse(e) ?? 0.0)
      .toList();

  return parts;
}

// /// Maps alternative muscle group names to standard names
// String? _mapMuscleGroupName(String inputName) {
//   final Map<String, String> muscleNameMappings = {
//     // Handle variations in naming
//     'Pectoralis Major': 'Pectoralis major',
//     'pectoralis major': 'Pectoralis major',
//     'Chest': 'Pectoralis major',
//     'chest': 'Pectoralis major',

//     'trapezius': 'Trapezius',
//     'Traps': 'Trapezius',
//     'traps': 'Trapezius',

//     'biceps': 'Biceps',
//     'Bicep': 'Biceps',
//     'bicep': 'Biceps',

//     'abdominals': 'Abdominals',
//     'Abs': 'Abdominals',
//     'abs': 'Abdominals',
//     'Core': 'Abdominals',
//     'core': 'Abdominals',

//     'Front Deltoids': 'Front Delts',
//     'front delts': 'Front Delts',
//     'Anterior Delts': 'Front Delts',
//     'anterior delts': 'Front Delts',

//     'deltoids': 'Deltoids',
//     'Delts': 'Deltoids',
//     'delts': 'Deltoids',
//     'Shoulders': 'Deltoids',
//     'shoulders': 'Deltoids',

//     'Back Deltoids': 'Back Delts',
//     'back delts': 'Back Delts',
//     'Rear Delts': 'Back Delts',
//     'rear delts': 'Back Delts',
//     'Posterior Delts': 'Back Delts',
//     'posterior delts': 'Back Delts',

//     'latissimus dorsi': 'Latissimus dorsi',
//     'Lats': 'Latissimus dorsi',
//     'lats': 'Latissimus dorsi',
//     'Lat': 'Latissimus dorsi',
//     'lat': 'Latissimus dorsi',

//     'triceps': 'Triceps',
//     'Tricep': 'Triceps',
//     'tricep': 'Triceps',

//     'gluteus maximus': 'Gluteus maximus',
//     'Glutes': 'Gluteus maximus',
//     'glutes': 'Gluteus maximus',
//     'Glute': 'Gluteus maximus',
//     'glute': 'Gluteus maximus',

//     'hamstrings': 'Hamstrings',
//     'Hamstring': 'Hamstrings',
//     'hamstring': 'Hamstrings',
//     'Hams': 'Hamstrings',
//     'hams': 'Hamstrings',

//     'quadriceps': 'Quadriceps',
//     'Quads': 'Quadriceps',
//     'quads': 'Quadriceps',
//     'Quad': 'Quadriceps',
//     'quad': 'Quadriceps',

//     'forearms': 'Forearms',
//     'Forearm': 'Forearms',
//     'forearm': 'Forearms',

//     'calves': 'Calves',
//     'Calf': 'Calves',
//     'calf': 'Calves',
//   };

//   return muscleNameMappings[inputName];
// }

/// List of muscle group names for mapping
// const List<String> muscleGroupNames = [
//   "Pectoralis major",
//   "Trapezius",
//   "Biceps",
//   "Abdominals",
//   "Front Delts",
//   "Deltoids",
//   "Back Delts",
//   "Latissimus dorsi",
//   "Triceps",
//   "Gluteus maximus",
//   "Hamstrings",
//   "Quadriceps",
//   "Forearms",
//   "Calves"
// ];

class _SettingsScreen extends State<SettingsScreen> {
  // final wakeUpTimeController = TextEditingController();
  // final graphNumberOfDays = TextEditingController();
  // final equationController = TextEditingController();
  // final Future<SharedPreferences> _preferences = SharedPreferences.getInstance();
  DisplayMode selectedMode = DisplayMode.light;
  GraphMode selectedGraphMode =
      globals.detailedGraph ? GraphMode.detailed : GraphMode.simple;

  @override
  void initState() {
    super.initState();
    // wakeUpTimeController.text = "${globals.idleTimerWakeup}";
    // graphNumberOfDays.text = "${globals.graphNumberOfDays}";
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
        actions: [
          buildInfoButton('Setting Screen info', context,
              () => showInfoDialogSettingsSetup(context)),
        ],
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: [
                // Background image with reduced opacity
                Opacity(
                  opacity:
                      0.15, // Adjust this value (0.0 to 1.0) for desired transparency
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'images/Icon-App_3_Darkmode.png'
                        : 'images/Icon-App_3.png',
                    fit: BoxFit.fill,
                  ),
                ),
                // Text overlay
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gymli',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Son of Gain, part of the Fellowship of the Gym',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.1.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'You should be lifting instead of fumbling with settings, son.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            // const Spacer(
            //   flex: 3,
            // ),
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
                  backup("TrainingSets", context);
                },
              ),
              TextButton.icon(
                label: const Text('Exercises'),
                icon: const FaIcon(FontAwesomeIcons.list, size: 13),
                onPressed: () {
                  backup("Exercises", context);
                },
              ),
              TextButton.icon(
                label: const Text('Workouts'),
                icon: const FaIcon(FontAwesomeIcons.clipboardList, size: 13),
                onPressed: () {
                  backup("Workouts", context);
                },
              ),
              TextButton.icon(
                label: const Text('Foods'),
                icon: const FaIcon(FontAwesomeIcons.utensils, size: 13),
                onPressed: () {
                  backup("Foods", context);
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
                },
              ),
              TextButton.icon(
                label: const Text('Exercises'),
                icon: const FaIcon(FontAwesomeIcons.list, size: 13),
                onPressed: () {
                  triggerLoad(context, "Exercises");
                },
              ),
              TextButton.icon(
                label: const Text('Workouts'),
                icon: const FaIcon(FontAwesomeIcons.clipboardList, size: 13),
                onPressed: () {
                  triggerLoad(context, "Workouts");
                },
              ),
              TextButton.icon(
                label: const Text('Foods'),
                icon: const FaIcon(FontAwesomeIcons.utensils, size: 13),
                onPressed: () {
                  triggerLoad(context, "Foods");
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
              TextButton.icon(
                label: const Text('Foods'),
                icon: const FaIcon(FontAwesomeIcons.utensils, size: 13),
                onPressed: () {
                  wipeFoods(context);
                },
              ),
            ]),
            const Spacer(),
          ]),
    );
  }
}

// TEMPORARY: Add this function to fix malformed CSV files
// Future<void> fixCSVFile() async {
//   try {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['csv'],
//     );

//     if (result != null && result.files.isNotEmpty) {
//       String content;
//       if (result.files.first.bytes != null) {
//         content = String.fromCharCodes(result.files.first.bytes!);
//       } else {
//         content = await File(result.files.first.path!).readAsString();
//       }

//       // Fix the content by ensuring proper line breaks
//       List<String> lines =
//           content.split(RegExp(r'[,](?=\w+,\d{4}-\d{2}-\d{2})'));

//       // Reconstruct with proper line endings
//       String fixedContent = '';
//       for (int i = 0; i < lines.length; i++) {
//         String line = lines[i].trim();
//         if (line.isNotEmpty) {
//           if (i > 0) {
//             // Add back the comma that was removed by split, but as line ending
//             fixedContent += '\n';
//           }
//           fixedContent += line;
//         }
//       }

//       // Add final newline
//       if (!fixedContent.endsWith('\n')) {
//         fixedContent += '\n';
//       }

//       // Save fixed version
//       final directory = await getApplicationSupportDirectory();
//       final fixedFile = File('${directory.path}/test_fixed.csv');
//       await fixedFile.writeAsString(fixedContent, encoding: utf8);

//       print('Fixed CSV saved to: ${fixedFile.path}');
//       print('First few lines of fixed CSV:');
//       print(fixedContent.split('\n').take(5).join('\n'));
//     }
//   } catch (e) {
//     print('Error fixing CSV: $e');
//   }
// }

Future<void> wipeFoods(BuildContext context) async {
  if (await confirm(
    context,
    title: const Text('Clear Food Data'),
    content: const Text(
        'Are you sure you want to permanently delete all food items? This action cannot be undone.'),
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
                Text('Clearing food data...'),
              ],
            ),
          );
        },
      );
    }

    try {
      if (kDebugMode) print('Starting to clear food data...');
      final container = ServiceContainer();
      final currentUserName = container.userName;
      if (kDebugMode) print('Clearing food data for user: $currentUserName');

      await container.foodService.clearFoodData();
      if (kDebugMode) print('Clear food data completed successfully');

      await Future.delayed(const Duration(milliseconds: 500));

      final remainingFoods = await container.foodService.getFoods();
      //final remainingLogs = await userService.getFoodLogs();
      if (kDebugMode)
        print('Remaining foods after clear: ${remainingFoods.length}');
      // print('Remaining food logs after clear: ${remainingLogs.length}');

      container.notifyDataChanged();

      if (context.mounted) {
        Navigator.of(context).pop();

        if (remainingFoods.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Food data cleared successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Warning: ${remainingFoods.length} foods may still remain'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing food data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
