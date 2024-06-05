// ignore_for_file: file_names
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
//import 'package:file_picker/file_picker.dart';
import 'globals.dart' as globals;
import 'package:time_machine/time_machine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Gymli/DataModels.dart';
import 'package:tuple/tuple.dart';
import 'dart:math';
import 'database.dart' as db;

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
  "Delts",
  "Lats",
  "Triceps",
  "Glutes",
  "Hams",
  "Quads",
  "Arms",
  "Calves"
];

const List<Color> barChartMuscleColors = [
  Color.fromARGB(255, 166,206,227), 
  Color.fromARGB(255, 202,178,214), 
  Color.fromARGB(255, 178,223,138), 
  Color.fromARGB(255, 51,160,44), 
  Color.fromARGB(255, 251,154,153), 
  Color.fromARGB(255, 31,120,180), 
  Color.fromARGB(255, 227,26,28), 
  Color.fromARGB(255, 255,127,0), 
  Color.fromARGB(255, 253,191,111), 
  Color.fromARGB(255, 106,61,154), 
  Color.fromARGB(255, 255,255,153), 
  Color.fromARGB(255, 177,89,40), 
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
  List<double> heatMapMulti = [];
  final TextEditingController MuscleController = TextEditingController();
  List<List<double>> heatMapCood = [
    [0.25, 0.53], //pectoralis
    [0.75, 0.57], // trapezius
    [0.37, 0.48], // biceps
    [0.25, 0.44], // abs
    [0.36, 0.54], //delts
    [0.74, 0.45], //latiss
    [0.61, 0.49], //tri
    [0.74, 0.34], //glut
    [0.71, 0.27], //ham
    [0.29, 0.28], //quad
    [0.4, 0.40], //fore
    [0.31, 0.15] //calv
  ];
  
  
  // Pectoralis major - x: 100, y: 450
// Trapezius - x: 300, y: 480
// Biceps - x: 150, y: 410
// Abdominals - x: 100, y: 380
// Deltoids - x: 145, y: 460,
// Latissimus dorsi - x: 290, y: 380,
// Triceps - x: 240, y: 395
// Gluteus maximus - x: 290, y: 300
// Hamstrings - x: 280, y: 220
// Quadriceps - x: 115, y: 230
// Forearms - x: 160, y: 350
// Calves - x: 270, y: 120


  void updateView() {}

  // Widget bottomTitles(double value, TitleMeta meta) {
  //   return SideTitleWidget(
  //     axisSide: meta.axisSide,
  //     child: Text(["A1", "B2", "C3"][value.toInt()])
  //   );
  // }

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

  @override
  void initState() {
    super.initState();
    List<DateTime> _trainingDates = db.getTrainingDates("");
    setState(() {
      numberOfTrainingDays = _trainingDates.length;
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
        spots.add(
            FlSpot((i + firstWeek).toDouble(), trainingsPerWeek[i].toDouble()));
      }
      trainingsPerWeekChart.add(LineChartBarData(spots: spots));

      // calculate portions of training
      // final musGroups = ["Pectoralis major", "Biceps", "Abdominals", "Deltoids", "Latissimus dorsi", "Triceps", "Gluteus maximus", "Hamstrings", "Quadriceps"];
      // determine mapping of muscle groups to scores
      Map<String, int> muscleMapping = {
        "Pectoralis major": 0,
        "Trapezius": 1,
        "Biceps": 2,
        "Abdominals": 3,
        "Deltoids": 4,
        "Latissimus dorsi": 5,
        "Triceps": 6,
        "Gluteus maximus": 7,
        "Hamstrings": 8,
        "Quadriceps": 9,
        "Forearms": 10,
        "Calves": 11
      };

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

      List<List<double>> muscleHistoryScore = [];
      for (var day in _trainingDates) {
        var trainings = db.getTrainings(day);
        List<double> dailyMuscleScores = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]; // very static and nasty
        for (var exerciseSet in trainings) {
          String exerciseName = exerciseSet.exercise;
          List<Tuple2<int, double>> muscleInvolved =
              exerciseMapping[exerciseName]!;
          for (Tuple2<int, double> pair in muscleInvolved) {
            dailyMuscleScores[pair.item1] += pair.item2;
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
    });
  }

  @override
  Widget build(BuildContext context) {

    List<List> muscleHistoryScore = globals.muscleHistoryScore;

    List<double> muscleHistoryScoreCum = [];
    for (int i = 0 ; i < muscleHistoryScore[0].length; i++) {
      double item = 0;
      for (int j = 0 ; j < muscleHistoryScore.length; j++) {
        item = item +
            muscleHistoryScore[j]
                [i]; //adds all values from all the lists in the list.
      }
      muscleHistoryScoreCum.add(item);
    }
    var highestValue = muscleHistoryScoreCum.reduce(max);
    List<double> heatMapMulti = [];
    for (int i =0; i < muscleHistoryScoreCum.length ; i++) {
      heatMapMulti.add(muscleHistoryScoreCum[i] /
          highestValue); //percentage of muscle usage in relation to highest for the heatmap.
    }

    //print(highestValue);
    print(globals.muscleHistoryScore);
    print(heatMapCood);
    print(heatMapMulti);
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
                updateView();
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
                updateView();
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
          Text("Number of Trainings per Week", style: subStyle, textAlign: TextAlign.center,),
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
          Text("Muscle usage per Exercise", style: subStyle, textAlign: TextAlign.center,),
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
              for (int i = (barChartMuscleColors.length / 2).toInt();
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
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
          Text("Heatmap: relative to most used muscle", style: subStyle, textAlign: TextAlign.center,),
                    const SizedBox(
            height: 20,
          ),
          // SizedBox(
          //   width: MediaQuery.of(context).size.width,
          //   height: MediaQuery.of(context).size.height * 0.15,
          //   child: PieChart(
          //     PieChartData(
          //       pieTouchData: PieTouchData(
          //         touchCallback: (FlTouchEvent event, pieTouchResponse) {
          //           setState(() {
          //             if (!event.isInterestedForInteractions ||
          //                 pieTouchResponse == null ||
          //                 pieTouchResponse.touchedSection == null) {
          //               return;
          //             }
          //           });
          //         },
          //       ),
          //       borderData: FlBorderData(
          //         show: false,
          //       ),
          //       sectionsSpace: 0,
          //       centerSpaceRadius: 40,
          //       sections: List.generate(4, (i) {
          //         // final isTouched = i == touchedIndex;
          //         final isTouched = false;
          //         final fontSize = isTouched ? 25.0 : 16.0;
          //         final radius = isTouched ? 60.0 : 50.0;
          //         const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
          //         switch (i) {
          //           case 0:
          //             return PieChartSectionData(
          //               color: barChartMuscleColors[0],
          //               value: 40,
          //               title: '40%',
          //               radius: radius,
          //               titleStyle: TextStyle(
          //                 fontSize: fontSize,
          //                 fontWeight: FontWeight.bold,
          //                 color: barChartMuscleColors[1],
          //                 shadows: shadows,
          //               ),
          //             );
          //           case 1:
          //             return PieChartSectionData(
          //               color: barChartMuscleColors[2],
          //               value: 30,
          //               title: '30%',
          //               radius: radius,
          //               titleStyle: TextStyle(
          //                 fontSize: fontSize,
          //                 fontWeight: FontWeight.bold,
          //                 color: barChartMuscleColors[3],
          //                 shadows: shadows,
          //               ),
          //             );
          //           case 2:
          //             return PieChartSectionData(
          //               color: barChartMuscleColors[4],
          //               value: 15,
          //               title: '15%',
          //               radius: radius,
          //               titleStyle: TextStyle(
          //                 fontSize: fontSize,
          //                 fontWeight: FontWeight.bold,
          //                 color: barChartMuscleColors[5],
          //                 shadows: shadows,
          //               ),
          //             );
          //           case 3:
          //             return PieChartSectionData(
          //               color: barChartMuscleColors[6],
          //               value: 15,
          //               title: '15%',
          //               radius: radius,
          //               titleStyle: TextStyle(
          //                 fontSize: fontSize,
          //                 fontWeight: FontWeight.bold,
          //                 color: barChartMuscleColors[7],
          //                 shadows: shadows,
          //               ),
          //             );
          //           default:
          //             throw Error();
          //         }
          //       }),
          //     ),
          //   ),
          // ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            width: 100,
            child: 
              Stack(
                //width: MediaQuery.of(context).size.width,
                fit: StackFit.expand,
                // width: MediaQuery.of(context).size.width,
                children: [Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scaleX: -1,
                      child:  Image(
                        fit: BoxFit.fill,
                          width: MediaQuery.of(context).size.width*0.35,
                          // height: MediaQuery.of(context).size.height * 0.7,
                          image: AssetImage('images/muscles/Front_bg.png')),
                    ),
                     Image(
                      fit: BoxFit.fill,
                        width: MediaQuery.of(context).size.width*0.35,
                        //   height: MediaQuery.of(context).size.height * 0.7,
                        image: AssetImage('images/muscles/Back_bg.png')),
                  ],
                ),
              

              //for (var i in [0,1])
              // Pectoralis major - x: 100, y: 450
// Trapezius - x: 300, y: 480
// Biceps - x: 150, y: 410
// Abdominals - x: 100, y: 380
// Deltoids - x: 145, y: 460,
// Latissimus dorsi - x: 290, y: 380,
// Triceps - x: 240, y: 395
// Gluteus maximus - x: 290, y: 300
// Hamstrings - x: 280, y: 220
// Quadriceps - x: 115, y: 230
// Forearms - x: 160, y: 350
// Calves - x: 270, y: 120
//dia min: 50 max: 100
// opa min: 100 max 200
//lerp min 0 max 1
              for (int i = 0; i < heatMapMulti.length; i++)
                //heatDot(x: heatMapCood[i][0]-((30+(50*heatMapMulti[i]))/2), y: heatMapCood[i][1]-((30+(50*heatMapMulti[i]))/2), dia: 30+(50*heatMapMulti[i]), opa: heatMapMulti[i] == 0 ? 0 : (50 + 150*heatMapMulti[i]).toInt(), lerp: heatMapMulti[i]),
                heatDot(
                    text: (heatMapMulti[i] * 100).round().toString() + "%",
                    x: (MediaQuery.of(context).size.width*heatMapCood[i][0]) - ((30 + (50 * heatMapMulti[i])) / 2),
                    y: (MediaQuery.of(context).size.height*heatMapCood[i][1]) - ((30 + (50 * heatMapMulti[i])) / 2),
                    dia: 30 + (50 * heatMapMulti[i]),
                    opa: heatMapMulti[i] == 0 ? 0 : 200,
                    lerp: heatMapMulti[i]),
          ],
          )),
          // Spacer(),
          // for (var i in List.generate(15, (i) => i))
          //   Text("bla"),]
          // ),
        ]));
  }
}

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
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(Color.fromARGB(opa, 255, 200, 50),
                Color.fromARGB(opa, 255, 30, 50), lerp)),
      ),
    );
  }
}
