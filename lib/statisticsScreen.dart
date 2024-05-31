// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:intl/intl.dart';
//import 'package:file_picker/file_picker.dart';
import 'globals.dart' as globals;
import 'package:time_machine/time_machine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:tuple/tuple.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreen();
}

class _StatisticsScreen extends State<StatisticsScreen> {

  // overall variables
  int numberOfTrainingDays = 0;
  String trainingDuration = "";
  List<String> trainingDates = [];
  List<LineChartBarData> trainingsPerWeekChart = [];

  final TextEditingController MuscleController = TextEditingController();

  void updateView() {

  }

  final betweenSpace = 0.0;
  Widget bottomTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(["A1", "B2", "C3"][value.toInt()])
    );
  }

BarChartGroupData generateGroupData(
    int x,
    double pilates,
    double quickWorkout,
    double cycling,
  ) {
    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: pilates,
          color: Colors.red,
        ),
        BarChartRodData(
          fromY: pilates,
          toY: pilates + quickWorkout,
          color: Colors.blue,
        ),
        BarChartRodData(
          fromY: pilates + quickWorkout,
          toY: pilates + quickWorkout + cycling,
          color: Colors.yellow,
        ),
      ],
    );
  }

  int weekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
  @override
  void initState() {
    super.initState();
    List<DateTime> _trainingDates = globals.getTrainingDates("");
    setState(() {
      numberOfTrainingDays = _trainingDates.length;
      // var timeDiff = _trainingDates.first.difference(_trainingDates.last).inDays;
      Period diff = LocalDate.dateTime(_trainingDates.last).periodSince(LocalDate.dateTime(_trainingDates.first));
      trainingDuration = "Over the period of ${diff.months} month and ${diff.days} days";
      var firstWeek = weekNumber(_trainingDates.first);
      var lastWeek = weekNumber(_trainingDates.last);
      List<int> trainingsPerWeek = [];
      for (int i = firstWeek; i < lastWeek+1; ++i) { trainingsPerWeek.add(0); }
      for (var d in _trainingDates) {
        trainingDates.add(DateFormat('dd-MM-yyyy').format(d));
        trainingsPerWeek[weekNumber(d)-firstWeek] += 1;
      }
      List<FlSpot> spots = [];
      for (int i = 0; i < trainingsPerWeek.length; ++i) {
        spots.add(FlSpot((i+firstWeek).toDouble(), trainingsPerWeek[i].toDouble()));
      }
      trainingsPerWeekChart.add(LineChartBarData(spots: spots));

      // calculate portions of training
      // final musGroups = ["Pectoralis major", "Biceps", "Abdominals", "Deltoids", "Latissimus dorsi", "Triceps", "Gluteus maximus", "Hamstrings", "Quadriceps"];
      List<double> muscleScores = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      Map<String, int> muscleMapping = { "Pectoralis major": 1, "Trapezius": 0,  "Biceps": 2, "Abdominals": 3,  "Deltoids": 4,  "Latissimus dorsi": 5,  "Triceps": 6,  "Gluteus maximus": 7,  "Hamstrings": 8,  "Quadriceps": 9,  "Forearms": 0,  "Calves": 0 };
      var ebox = Hive.box<Exercise>("Exercises");
      Map<String, List<Tuple2<int, double>>> exerciseMapping = {};
      for (var e in ebox.values.toList()) {
        List<Tuple2<int, double>> intermediateMap = [];
        for (int i = 0; i < e.muscleGroups.length; ++i) {
          String which = e.muscleGroups[i];
          var val = muscleMapping[which]!;
          intermediateMap.add(Tuple2<int, double>(val, e.muscleIntensities[i]));
        }
        exerciseMapping[e.name] = intermediateMap;
      }
      print(exerciseMapping);

      
      
      Map<String, int> map1 = {'zero': 0, 'one': 1, 'two': 2};

      for (var day in trainingDates) {
      }


    });
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
        title: const Text("Statistics"),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text("Number of training days: $numberOfTrainingDays"),
            Text(trainingDuration),
            Divider(),
            Text("Statistic Interval"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                DropdownMenu<String>(
                  label: const Text("Start"),
                  onSelected: (String? date) { updateView(); },
                  dropdownMenuEntries: trainingDates.map<DropdownMenuEntry<String>>((String name) { return DropdownMenuEntry<String>(value: name, label: name); }).toList(),
                ),
                const Spacer(),
                DropdownMenu<String>(
                  label: const Text("End"),
                  onSelected: (String? date) { updateView(); },
                  dropdownMenuEntries: trainingDates.map<DropdownMenuEntry<String>>((String name) { return DropdownMenuEntry<String>(value: name, label: name); }).toList(),
                ),
                const Spacer(),
              ]
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.15,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0, top: 15.0, left: 0.0), // Hier das Padding rechts hinzufügen
                child: LineChart(
                  LineChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
                  lineBarsData: trainingsPerWeekChart,
                  maxY: 4
                )
              ),
              )
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.20,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0, top: 15.0, left: 0.0), // Hier das Padding rechts hinzufügen
                child: BarChart(
                  BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitles,
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  // borderData: FlBorderData(show: false),
                  // gridData: const FlGridData(show: false),
                  barGroups: [
                    generateGroupData(0, 2, 3, 2),
                    generateGroupData(1, 2, 5, 1.7),
                    generateGroupData(2, 1.3, 3.1, 2.8),
                  ],
                  maxY: 11 + (betweenSpace * 3),
                ),
                ),
                ),
            ),
            Spacer(),
          ]
        ),
    );
  }
}
