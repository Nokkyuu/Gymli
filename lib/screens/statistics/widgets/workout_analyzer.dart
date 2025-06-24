import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../../user_service.dart';

class WorkoutAnalyzerScreen extends StatefulWidget {
  final String? startingDate;
  final String? endingDate;
  final bool useDefaultDateFilter;

  const WorkoutAnalyzerScreen({
    super.key,
    this.startingDate,
    this.endingDate,
    this.useDefaultDateFilter = true,
  });

  @override
  State<WorkoutAnalyzerScreen> createState() => _WorkoutAnalyzerScreenState();
}

class _WorkoutAnalyzerScreenState extends State<WorkoutAnalyzerScreen> {
  final UserService userService = UserService();

  List<Map<String, dynamic>> _workouts = [];
  List<Map<String, dynamic>> _exercises = [];
  Set<int> _selectedWorkoutIds = {};
  bool _isLoading = true;

  final List<String> muscleKeys = [
    'pectoralis_major',
    'trapezius',
    'biceps',
    'abdominals',
    'front_delts',
    'deltoids',
    'back_delts',
    'latissimus_dorsi',
    'triceps',
    'gluteus_maximus',
    'hamstrings',
    'quadriceps',
    'forearms',
    'calves',
  ];
  final List<String> muscleLabels = [
    'Pectoralis',
    'Trapezius',
    'Biceps',
    'Abs',
    'Front Delts',
    'Side Delts',
    'Back Delts',
    'Lats',
    'Triceps',
    'Glutes',
    'Hamstrings',
    'Quads',
    'Forearms',
    'Calves',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final workouts = await userService.getWorkouts();
      final exercises = await userService.getExercises();
      // Sortiere Workouts alphabetisch nach Name
      final sortedWorkouts = List<Map<String, dynamic>>.from(workouts)
        ..sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
              (b['name'] ?? '').toString().toLowerCase(),
            ));
      setState(() {
        _workouts = sortedWorkouts;
        _exercises = List<Map<String, dynamic>>.from(exercises);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading workouts/exercises: $e');
      setState(() => _isLoading = false);
    }
  }

  // Aggregiert Muskelgruppen-Volumen für ausgewählte Workouts
  Map<String, double> _aggregateMuscleVolume() {
    Map<String, double> muscleVolume = {for (var k in muscleKeys) k: 0.0};

    for (final workout
        in _workouts.where((w) => _selectedWorkoutIds.contains(w['id']))) {
      final units = workout['units'] as List<dynamic>? ?? [];
      for (final unit in units) {
        final exerciseId = unit['exercise_id'];
        final worksets = (unit['worksets'] ?? 0) as int;
        final exercise = _exercises.firstWhere(
          (ex) => ex['id'] == exerciseId,
          orElse: () => <String, dynamic>{},
        );
        if (exercise.isNotEmpty) {
          for (final muscle in muscleKeys) {
            final intensity = (exercise[muscle] ?? 0.0) as double;
            muscleVolume[muscle] =
                muscleVolume[muscle]! + (worksets * intensity);
          }
        }
      }
    }

    // Apply logarithmic or squareroot scaling
    //muscleVolume.updateAll((k, v) => log(1 + v));
    //muscleVolume.updateAll((k, v) => sqrt(v));
    // Normalize to 0-100% based on current selection's maximum
    final maxValue = muscleVolume.values.fold<double>(0.0, max);
    if (maxValue > 0) {
      muscleVolume.updateAll((k, v) => (v / maxValue) * 100.0);
    }

    return muscleVolume;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final muscleVolume = _aggregateMuscleVolume();

    return Row(
      children: [
        // Linke Seite: Workouts-Liste mit Mehrfachauswahl
        Expanded(
          flex: 1,
          child: Card(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Workouts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ..._workouts.take(10).map((workout) {
                  final id = workout['id'] as int;
                  final name = workout['name']?.toString() ?? 'Workout $id';
                  return CheckboxListTile(
                    value: _selectedWorkoutIds.contains(id),
                    title: Text(name),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedWorkoutIds.add(id);
                        } else {
                          _selectedWorkoutIds.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
                if (_workouts.length > 10)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('...'),
                  ),
              ],
            ),
          ),
        ),
        // Rechte Seite: RadarChart
        Expanded(
          flex: 2,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Muscle Group Volume (relative, %)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        //_selectedWorkoutIds.isEmpty
                        // ? const Center(
                        //     child: Text(
                        //     'Select one or more workouts to analyze',
                        //   ))
                        //:
                        RadarChart(
                      RadarChartData(
                        dataSets: [
                          RadarDataSet(
                            dataEntries: muscleKeys
                                .map((k) =>
                                    RadarEntry(value: muscleVolume[k] ?? 0.0))
                                .toList(),
                            borderColor: Colors.blue,
                            fillColor: Colors.blue.withOpacity(0.3),
                            entryRadius: 2,
                            borderWidth: 3,
                          ),
                          // Add invisible dataset to force 0-100 scale
                          RadarDataSet(
                            dataEntries: List.generate(
                              muscleKeys.length,
                              (index) =>
                                  RadarEntry(value: index == 0 ? 100.0 : 0.0),
                            ),
                            borderColor: Colors.transparent,
                            fillColor: Colors.transparent,
                            entryRadius: 0,
                            borderWidth: 0,
                          ),
                        ],
                        radarBackgroundColor: Colors.transparent,
                        radarBorderData: const BorderSide(color: Colors.grey),
                        titleTextStyle: const TextStyle(fontSize: 12),
                        getTitle: (index, angle) {
                          return RadarChartTitle(
                            text: muscleLabels[index],
                            angle: angle,
                          );
                        },
                        tickCount: 4, // 0, 25, 50, 75, 100

                        ticksTextStyle:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                        tickBorderData:
                            const BorderSide(color: Colors.grey, width: 1),
                        gridBorderData:
                            const BorderSide(color: Colors.grey, width: 1),
                        radarShape: RadarShape.polygon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
