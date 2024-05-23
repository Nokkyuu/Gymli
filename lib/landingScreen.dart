import 'package:flutter/material.dart';
//import 'package:fl_chart/fl_chart.dart';
import 'package:yafa_app/exerciseScreen.dart';
import 'package:yafa_app/exerciseSetupScreen.dart';
import 'package:yafa_app/workoutSetupScreen.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:yafa_app/DataBase.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
// class LandingScreen extends StatefulWidget {
//   LandingScreen({Key? key}) : super(key: key);
//   _LandingScreen createState() => _LandingScreen();
// }
class LandingScreen extends StatelessWidget {
  // _LandingScreen({super.key});
  // static List<ListItem> items = [
  //         ExerciseItem('Deadlift', '15 kg'),
  //         ExerciseItem('Benchpress', '12 kg'),
  //         ExerciseItem('Pullup', '50 kg'),
  //         ExerciseItem('Squat', '1 kg'),
  //         ExerciseItem('Biceps Curl', '15 s'),
  //       ];
  // final Box<Exercise> = Hive.box<Exercise>('Exercise');

  // DbHelper dbHelper = DbHelper();
  // final exercises = [];
  // final box = Hive.openBox('Exercise');
  // // Future<List<Exercise>> _openBox async {
  //   // final taskBox = await Hive.openBox<Exercise>('Exercises');
  //   final taskBox = Hive.box<Exercise>('Exercises');
  //   final exercises = taskBox.toList();
  // }
  //  @override
  // void initState() {
  //   super.initState();
  //   // final box = Hive.box('Exercise');
  // }

  @override
  Widget build(BuildContext context) {
    const title = 'Fitness Tracker';
    final points = [(10, 1), (20, 1)];
    // List exercises = then(taskBox.values.toList());

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
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Exercise>('Exercises').listenable(),
                builder: (context, Box<Exercise> box, _) {
                  if (!box.values.isEmpty) {
                    return ListView.builder(
                      itemCount: box.values.length,
                      itemBuilder: (context, index) {
                        final currentData = box.getAt(index);
                        return ListTile(
                          leading: const CircleAvatar(radius: 17.5,backgroundColor: Colors.cyan,child: Icon(Icons.timer_outlined, color: Colors.white,),),
                          title: Text(currentData!.name),
                          subtitle: 
                                Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                          // item.buildSubtitle(context),
                          const Text(" 12847 reps")
                        ]),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciseScreen()),);
                        }
                      );
                    });
                  } else {
                    return const CircularProgressIndicator();
                }
                }
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

void main() async {
  // final taskBox = await Hive.openBox<Exercise>('Exercises');
  // add(taskBox);
  // taskBox.close();
  // get(taskBox);
  final box = await Hive.openBox<Exercise>('Exercises');
  runApp(MaterialApp(
      title: 'Navigation Basics',
      // home: ExerciseListScreen(),
      home: LandingScreen(),
    ));
}
