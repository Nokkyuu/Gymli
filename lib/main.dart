import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(
    FitnessTracker(),
  );
}

class FitnessTracker extends StatelessWidget {
  static List<ListItem> items = [
          ExerciseItem('Deadlift', '15 kg'),
          ExerciseItem('Benchpress', '12 kg'),
          ExerciseItem('Pullup', '50 kg'),
          ExerciseItem('Squat', '1 kg'),
          ExerciseItem('Biceps Curl', '15 s'),
        ];

  const FitnessTracker({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Fitness Tracker';
    final points = [(10, 1), (20, 1)];

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
          TextButton(
            style: ButtonStyle(
            ),
            onPressed: () { },
            child: Text('Training Stoppen'),
          ),
          const Text("Dauer 00:41:32 ")
          ]),
          new Expanded(
              child: ListView.builder(
              itemCount: items.length,
              // Provide a builder function. This is where the magic happens.
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: CircleAvatar(radius: 17.5,backgroundColor: Colors.cyan,child: const Icon(Icons.timer_outlined, color: Colors.white,),),
                  title: item.buildTitle(context),
                  subtitle: 
                        Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                  item.buildSubtitle(context),
                  Text(" 10 reps")
                  ])
                );
              })
            ),
            new Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                    spots: const [ FlSpot(0, 5), FlSpot(1, 10), FlSpot(2, 8), FlSpot(3, 11), FlSpot(4, 12)]
                  ),
                ],
              )
            )
            )
            ]
        ),
      ),
    );
  }
}

/// The base class for the different types of items the list can contain.
abstract class ListItem {
  Widget buildTitle(BuildContext context);
  Widget buildSubtitle(BuildContext context);
}
class ExerciseItem implements ListItem {
  final String exerciseName;
  final String meta;

  ExerciseItem(this.exerciseName, this.meta);
  @override
  Widget buildTitle(BuildContext context) => Text(exerciseName);

  @override
  Widget buildSubtitle(BuildContext context) => Text(meta);
}