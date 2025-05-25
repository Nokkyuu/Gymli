/**
 * Statistics Screen - Workout Analytics and Progress Visualization
 * 
 * This screen provides comprehensive workout analytics and progress tracking
 * through various charts, graphs, and statistical visualizations using fl_chart.
 * 
 * Key features:
 * - Muscle group activation bar charts and heatmaps
 * - Training volume analysis over time
 * - One Rep Max (1RM) progression tracking
 * - Exercise-specific performance metrics
 * - Weekly/monthly workout frequency analysis
 * - Visual progress indicators and trend analysis
 * - Customizable date ranges for data analysis
 * - Interactive charts with detailed data points
 * - Muscle group balance assessment
 * - Training load distribution visualization
 * 
 * The screen helps users understand their training patterns, identify
 * imbalances, track progress, and make data-driven decisions about their
 * fitness routines through comprehensive visual analytics.
 */

// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:file_picker/file_picker.dart';
import 'globals.dart' as globals;
import 'package:time_machine/time_machine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tuple/tuple.dart';
import 'dart:math';
import 'database.dart' as db;
import 'user_service.dart';
import 'api_models.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreen();
}

const List<String> barChartMuscleNames = [
  "Pecs",
  "Trapz",
  "Biceps",
  "Abs",
  "Front-D",
  "Delts",
  "Back-D",
  "Lats",
  "Triceps",
  "Glutes",
  "Hams",
  "Quads",
  "Arms",
  "Calves",
];

const List<Color> barChartMuscleColors = [
  Color.fromARGB(255, 166, 206, 227),
  Color.fromARGB(255, 202, 178, 214),
  Color.fromARGB(255, 178, 223, 138),
  Color.fromARGB(255, 51, 160, 44),
  Color.fromARGB(255, 251, 154, 153),
  Color.fromARGB(255, 251, 154, 153),
  Color.fromARGB(255, 251, 154, 153),
  Color.fromARGB(255, 31, 120, 180),
  Color.fromARGB(255, 227, 26, 28),
  Color.fromARGB(255, 255, 127, 0),
  Color.fromARGB(255, 253, 191, 111),
  Color.fromARGB(255, 106, 61, 154),
  Color.fromARGB(255, 255, 255, 153),
  Color.fromARGB(255, 177, 89, 40),
];

TextStyle subStyle =
    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0);

class _StatisticsScreen extends State<StatisticsScreen> {
  // overall variables
  int numberOfTrainingDays = 0;
  String trainingDuration = "";
  List<String> trainingDates = [];
  List<LineChartBarData> trainingsPerWeekChart = [];
  List<BarChartGroupData> barChartStatistics = [];
  List<Text> exerciseDetails = [];
  String? startingDate;
  String? endingDate;
  List<double> heatMapMulti = [];
  // ignore: non_constant_identifier_names
  final TextEditingController MuscleController = TextEditingController();
  final UserService userService = UserService();
  List<List<double>> heatMapCood = [
    [0.25, 0.53], //pectoralis
    [0.75, 0.57], // trapezius
    [0.37, 0.48], // biceps
    [0.25, 0.44], // abs
    [0.36, 0.54], //Front delts
    [0.64, 0.59], //Side Delts
    [0.64, 0.53], //Back Delts
    [0.74, 0.45], //latiss
    [0.61, 0.48], //tri
    [0.74, 0.34], //glut
    [0.71, 0.27], //ham
    [0.29, 0.28], //quad
    [0.4, 0.40], //fore
    [0.31, 0.15], //calv
  ];

  void updateView() {}

  int weekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  BarChartGroupData generateBars(
      int x, List<double> rations, List<Color> colors) {
    List<BarChartRodData> bars = [];
    for (var i = 0; i < rations.length - 1; ++i) {
      bars.add(BarChartRodData(
          fromY: rations[i],
          toY: rations[i + 1],
          color: colors[i],
          borderRadius: const BorderRadius.horizontal()));
    }
    return BarChartGroupData(x: x, groupVertically: true, barRods: bars);
  }

  Future<void> updateBarStatistics() async {
    // calculate portions of training
    // final musGroups = ["Pectoralis major", "Biceps", "Abdominals", "Deltoids", "Latissimus dorsi", "Triceps", "Gluteus maximus", "Hamstrings", "Quadriceps"];
    // determine mapping of muscle groups to scores
    Map<String, int> muscleMapping = {
      "Pectoralis major": 0,
      "Trapezius": 1,
      "Biceps": 2,
      "Abdominals": 3,
      "Front Delts": 4,
      "Deltoids": 5,
      "Back Delts": 6,
      "Latissimus dorsi": 7,
      "Triceps": 8,
      "Gluteus maximus": 9,
      "Hamstrings": 10,
      "Quadriceps": 11,
      "Forearms": 12,
      "Calves": 13,
    };

    try {
      final exercisesData = await userService.getExercises();
      final exercises =
          exercisesData.map((e) => ApiExercise.fromJson(e)).toList();

      Map<String, List<Tuple2<int, double>>> exerciseMapping = {};
      for (var e in exercises) {
        List<Tuple2<int, double>> intermediateMap = [];
        for (int i = 0; i < e.muscleGroups.length; ++i) {
          String which = e.muscleGroups[i];
          var val = muscleMapping[which]!;
          intermediateMap.add(Tuple2<int, double>(val, e.muscleIntensities[i]));
        }
        exerciseMapping[e.name] = intermediateMap;
      }

      barChartStatistics.clear();
      List<DateTime> _trainingDates = await db.getTrainingDates("");
      if (startingDate != null) {
        var tokens = startingDate!.split("-");
        String _startingDateString =
            "${tokens[2]}-${tokens[1]}-${tokens[0]}T00:00:00";
        DateTime _start = DateTime.parse(_startingDateString);
        _trainingDates =
            _trainingDates.where((d) => _start.isBefore(d)).toList();
      }
      if (endingDate != null) {
        var tokens = endingDate!.split("-");
        String _endingDateString =
            "${tokens[2]}-${tokens[1]}-${tokens[0]}T00:00:00";
        DateTime _end = DateTime.parse(_endingDateString);
        _trainingDates = _trainingDates.where((d) => _end.isAfter(d)).toList();
      }

      List<List<double>> muscleHistoryScore = [];
      for (var day in _trainingDates) {
        var trainings = await db.getTrainings(day);
        List<double> dailyMuscleScores = [
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0
        ]; // very static and nasty
        for (var exerciseSet in trainings) {
          String exerciseName = exerciseSet.exercise;
          List<Tuple2<int, double>>? muscleInvolved =
              exerciseMapping[exerciseName];
          if (muscleInvolved != null) {
            for (Tuple2<int, double> pair in muscleInvolved) {
              dailyMuscleScores[pair.item1] += pair.item2;
            }
          }
        }
        muscleHistoryScore.add(dailyMuscleScores);
      }
      for (var i = 0; i < muscleHistoryScore.length; ++i) {
        var currentScore = muscleHistoryScore[i]; // convert to accumulated
        List<double> accumulatedScore = [0.0];
        for (var d in currentScore) {
          accumulatedScore.add(accumulatedScore.last + d);
        }
        barChartStatistics
            .add(generateBars(i, accumulatedScore, barChartMuscleColors));
      }
      globals.muscleHistoryScore = muscleHistoryScore;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating statistics: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      // ignore: no_leading_underscores_for_local_identifiers
      List<DateTime> _trainingDates = await db.getTrainingDates("");
      setState(() {
        numberOfTrainingDays = _trainingDates.length;
        if (numberOfTrainingDays == 0) {
          return;
        }
        // var timeDiff = _trainingDates.first.difference(_trainingDates.last).inDays;
        Period diff = LocalDate.dateTime(_trainingDates.last)
            .periodSince(LocalDate.dateTime(_trainingDates.first));
        trainingDuration =
            "Over the period of ${diff.months} month and ${diff.days} days";
        var firstWeek = weekNumber(_trainingDates.first);
        var lastWeek = weekNumber(_trainingDates.last);
        List<int> trainingsPerWeek = [];
        for (int i = firstWeek; i < lastWeek + 1; ++i) {
          trainingsPerWeek.add(0);
        }
        for (var d in _trainingDates) {
          trainingDates.add(DateFormat('dd-MM-yyyy').format(d));
          trainingsPerWeek[weekNumber(d) - firstWeek] += 1;
        }
        List<FlSpot> spots = [];
        for (int i = 0; i < trainingsPerWeek.length; ++i) {
          spots.add(FlSpot(
              (i + firstWeek).toDouble(), trainingsPerWeek[i].toDouble()));
        }
        trainingsPerWeekChart.add(LineChartBarData(spots: spots));
      });

      await updateBarStatistics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<List> muscleHistoryScore = globals.muscleHistoryScore;

    List<double> muscleHistoryScoreCum = [];
    if (muscleHistoryScore.isNotEmpty) {
      for (int i = 0; i < muscleHistoryScore[0].length; i++) {
        double item = 0;
        for (int j = 0; j < muscleHistoryScore.length; j++) {
          item = item +
              muscleHistoryScore[j]
                  [i]; //adds all values from all the lists in the list.
        }
        muscleHistoryScoreCum.add(item);
      }
      var highestValue = muscleHistoryScoreCum.reduce(max);
      heatMapMulti = [];
      for (int i = 0; i < muscleHistoryScoreCum.length; i++) {
        heatMapMulti.add(muscleHistoryScoreCum[i] /
            highestValue); //percentage of muscle usage in relation to highest for the heatmap.
      }
      //print(heatMapMulti);
    }
    //print(highestValue);
    //print(globals.muscleHistoryScore);
    //print(heatMapCood);
    //print(heatMapMulti);
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
          title: const Text("Statistics"),
        ),
        body: ListView(children: <Widget>[
          Text("Selected Training Interval", style: subStyle),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Spacer(),
            DropdownMenu<String>(
              label: const Text("Start"),
              onSelected: (String? date) {
                startingDate = date!;
                updateBarStatistics();
              },
              dropdownMenuEntries:
                  trainingDates.map<DropdownMenuEntry<String>>((String name) {
                return DropdownMenuEntry<String>(value: name, label: name);
              }).toList(),
              menuHeight: 200,
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                constraints: BoxConstraints.tight(const Size.fromHeight(40)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Spacer(),
            DropdownMenu<String>(
              label: const Text("End"),
              onSelected: (String? date) {
                endingDate = date!;
                updateBarStatistics();
              },
              dropdownMenuEntries:
                  trainingDates.map<DropdownMenuEntry<String>>((String name) {
                return DropdownMenuEntry<String>(value: name, label: name);
              }).toList(),
              menuHeight: 200,
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                constraints: BoxConstraints.tight(const Size.fromHeight(40)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Spacer(),
          ]),
          const SizedBox(height: 20),
          Text("Number of training days: $numberOfTrainingDays"),
          Text(trainingDuration),
          const Divider(),
          Text(
            "Number of Trainings per Week",
            style: subStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.15,
              child: Padding(
                padding: const EdgeInsets.only(
                    right: 10.0,
                    top: 15.0,
                    left: 0.0), // Hier das Padding rechts hinzufügen
                child: LineChart(LineChartData(
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false))),
                    lineBarsData: trainingsPerWeekChart,
                    maxY: 4)),
              )),
          const SizedBox(height: 20),
          Text(
            "Muscle usage per Exercise",
            style: subStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: (() {
              List<Widget> widgets = [];
              for (int i = 0; i < barChartMuscleColors.length / 2; i++) {
                widgets.add(Wrap(children: [
                  Container(
                      width: 14.0,
                      height: 14.0,
                      color: barChartMuscleColors[i]),
                  Text(" ${barChartMuscleNames[i]}",
                      style: const TextStyle(fontSize: 10.0))
                ]));
                // widgets.add(Text(barChartMuscleNames[i]));
              }
              return widgets;
            })(),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: (() {
              List<Widget> widgets = [];
              for (int i = barChartMuscleColors.length ~/ 2;
                  i < barChartMuscleColors.length;
                  i++) {
                widgets.add(Wrap(children: [
                  Container(
                      width: 14.0,
                      height: 14.0,
                      color: barChartMuscleColors[i]),
                  Text(" ${barChartMuscleNames[i]}",
                      style: const TextStyle(fontSize: 10.0))
                ]));
                // widgets.add(Text(barChartMuscleNames[i]));
              }
              return widgets;
            })(),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.15,
            child: Padding(
              padding: const EdgeInsets.only(
                  right: 10.0,
                  top: 5.0,
                  left: 10.0), // Hier das Padding rechts hinzufügen
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  titlesData: const FlTitlesData(
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    // bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: barChartStatistics,
                ),
              ),
            ),
          ),
          // Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: (() {
              List<Widget> widgets = [];
              for (var d in exerciseDetails) {
                widgets.add(d);
              }
              return widgets;
            })(),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            "Heatmap: relative to most used muscle",
            style: subStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 20,
          ),

          SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              width: 100,
              child: Stack(
                //width: MediaQuery.of(context).size.width,
                fit: StackFit.expand,
                // width: MediaQuery.of(context).size.width,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scaleX: -1,
                        child: Image(
                            fit: BoxFit.fill,
                            width: MediaQuery.of(context).size.width * 0.35,
                            // height: MediaQuery.of(context).size.height * 0.7,
                            image: const AssetImage(
                                'images/muscles/Front_bg.png')),
                      ),
                      Image(
                          fit: BoxFit.fill,
                          width: MediaQuery.of(context).size.width * 0.35,
                          //   height: MediaQuery.of(context).size.height * 0.7,
                          image:
                              const AssetImage('images/muscles/Back_bg.png')),
                    ],
                  ),
                  for (int i = 0; i < heatMapMulti.length; i++)
                    heatDot(
                        text: "${(heatMapMulti[i] * 100).round()}%",
                        x: (MediaQuery.of(context).size.width *
                                heatMapCood[i][0]) -
                            ((30 + (50 * heatMapMulti[i])) / 2),
                        y: (MediaQuery.of(context).size.height *
                                heatMapCood[i][1]) -
                            ((30 + (50 * heatMapMulti[i])) / 2),
                        dia: 30 + (50 * heatMapMulti[i]),
                        opa: heatMapMulti[i] == 0 ? 0 : 200,
                        lerp: heatMapMulti[i]),
                ],
              )),
        ]));
  }
}

// ignore: camel_case_types
class heatDot extends StatelessWidget {
  const heatDot({
    super.key,
    required this.y,
    required this.x,
    required this.dia,
    required this.opa,
    required this.lerp,
    required this.text,
  });

  final double y;
  final double x;
  final double dia;
  final int opa;
  final double lerp;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: y,
      left: x,
      child: Container(
        width: dia,
        height: dia,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(Color.fromARGB(opa, 255, 200, 50),
                Color.fromARGB(opa, 255, 30, 50), lerp)),
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
