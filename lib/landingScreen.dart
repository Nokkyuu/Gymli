import 'package:flutter/material.dart';
//import 'package:fl_chart/fl_chart.dart';
import 'package:yafa_app/exerciseScreen.dart';
import 'package:yafa_app/exerciseSetupScreen.dart';
import 'package:yafa_app/workoutSetupScreen.dart';

class LandingScreen extends StatelessWidget {
  static List<ListItem> items = [
          ExerciseItem('Deadlift', '15 kg'),
          ExerciseItem('Benchpress', '12 kg'),
          ExerciseItem('Pullup', '50 kg'),
          ExerciseItem('Squat', '1 kg'),
          ExerciseItem('Biceps Curl', '15 s'),
        ];

  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Fitness Tracker';
    final points = [(10, 1), (20, 1)];

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
          centerTitle: true,
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
            style: const ButtonStyle(
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciseSetupScreen()));},
            child: const Text('New Exercise'),
          ),
          TextButton(
            style: const ButtonStyle(
            ),
            onPressed: () { 
              Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutSetupScreen()));},
            child: const Text('New Workout'),
          ),
          const Text("Dauer 00:41:32 ")
          ]),
          Expanded(
              child: ListView.builder(
              itemCount: items.length,
              // Provide a builder function. This is where the magic happens.
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: const CircleAvatar(radius: 17.5,backgroundColor: Colors.cyan,child: Icon(Icons.timer_outlined, color: Colors.white,),),
                  title: item.buildTitle(context),
                  subtitle: 
                        Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                  item.buildSubtitle(context),
                  const Text(" 12847 reps")
                  ]),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciseScreen()),);
                  }
                );
              })
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
// add new button?
class ExerciseItem implements ListItem {
  final String exerciseName;
  final String meta;

  ExerciseItem(this.exerciseName, this.meta);
  @override
  Widget buildTitle(BuildContext context) => Text(exerciseName);

  @override
  Widget buildSubtitle(BuildContext context) => Text(meta);
}