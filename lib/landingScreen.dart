// ignore: file_names
// ignore_for_file: file_names, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:yafa_app/exerciseScreen.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List exercises = then(taskBox.values.toList());
    return  Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
            
            Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<Exercise>('Exercises').listenable(),
                  builder: (context, Box<Exercise> box, _) {
                    if (box.values.isNotEmpty) {
                      return ListView.builder(
                        itemCount: box.values.length,
                        itemBuilder: (context, index) {
                          final currentData = box.getAt(index);
                          final exerciseType = currentData!.type;
                          final repBase = currentData.defaultRepBase;
                          final repMax = currentData.defaultRepMax;
                          final increment = currentData.defaultIncrement;
                          final itemList = [FontAwesomeIcons.dumbbell, Icons.forklift, Icons.cable, Icons.sports_martial_arts];
                          final currentIcon = itemList[exerciseType];
                          return ListTile(
                            leading: CircleAvatar(radius: 17.5,child: FaIcon(currentIcon),),
                            title: Text(currentData.name),
                            subtitle: 
                                  Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("$repBase/$repMax with $increment kg")
                          ]),
                          onTap: () {
                            
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ExerciseScreen(currentData.name)));
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
  runApp(const MaterialApp(
    
      title: 'Navigation Basics',
      // home: ExerciseListScreen(),
      home: LandingScreen(),
    ));
}
