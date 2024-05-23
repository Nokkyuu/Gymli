import 'package:flutter/material.dart';
//import 'package:fl_chart/fl_chart.dart';
import 'package:yafa_app/exerciseScreen.dart';
import 'package:yafa_app/exerciseSetupScreen.dart';
import 'package:yafa_app/workoutSetupScreen.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:yafa_app/DataBase.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const title = 'Fitness Tracker';
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
                        final exerciseType = currentData!.type;
                        final repBase = currentData!.defaultRepBase;
                        final repMax = currentData!.defaultRepMax;
                        final increment = currentData!.defaultIncrement;
                        final itemList = [Icons.sports_tennis, Icons.agriculture_outlined, Icons.cable, Icons.sports_martial_arts];
                        final currentIcon = itemList[exerciseType];
                        return ListTile(
                          leading: CircleAvatar(radius: 17.5,backgroundColor: Colors.cyan,child: Icon(currentIcon, color: Colors.white,),),
                          title: Text(currentData!.name),
                          subtitle: 
                                Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text("$repBase/$repMax with $increment kg")
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
  // final box = await Hive.openBox<Exercise>('Exercises');
  runApp(MaterialApp(
      title: 'Navigation Basics',
      // home: ExerciseListScreen(),
      home: LandingScreen(),
    ));
}
