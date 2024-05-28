// ignore: file_names
// ignore_for_file: file_names, duplicate_ignore, constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:yafa_app/exerciseScreen.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum WorkoutList {
  Push('Push'),
  Pull('Pull'),
  Legs('Legs'),
  FullBodyComp('Full Body Comp');

  const WorkoutList(this.workoutName);
  final String workoutName;
}

enum MuscleList {
  Pectoralis_major("Pectoralis major"),
  Trapezius("Trapezius"),
  Biceps("Biceps"),
  Abdominals("Abdominals"),
  Delts("Deltoids"),
  Latissimus_dorsi("Dorsal Fins"),
  Triceps("Triceps"),
  Gluteus_maximus("Glutes"),
  Hamstrings("Hams"),
  Quadriceps("Quads"),
  Forearms("Forearms"),
  Calves("Calves");

  const MuscleList(this.muscleName);
  final String muscleName;
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController WorkoutController = TextEditingController();
  final TextEditingController MuscleController = TextEditingController();
  WorkoutList? selectedWorkout;
  MuscleList? selectedMuscle;

  @override
 
  Widget build(BuildContext context) {
    
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Filter by or "),
              TextButton.icon(
                onPressed: () => print("Show All"),
                label: const Text("Show All"),
                icon: const Icon(Icons.search),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownMenu<WorkoutList>(
                width: MediaQuery.of(context).size.width * 0.5,
                enabled: true,
                //initialSelection: WorkoutList.Push,
                controller: WorkoutController,
                requestFocusOnTap: false,
                label: const Text('Workouts'),
                onSelected: (WorkoutList? name) {
                  setState(() {
                    selectedWorkout = name;
                  });
                },
                dropdownMenuEntries: WorkoutList.values
                    .map<DropdownMenuEntry<WorkoutList>>((WorkoutList name) {
                  return DropdownMenuEntry<WorkoutList>(
                    value: name,
                    label: name.workoutName,
                    trailingIcon: IconButton(
                        onPressed: () => print(
                            "edit workout"), //TODO: go to workout setup to edit the selected workout
                        icon: const Icon(Icons.edit)),
                  );
                }).toList(),
              ),
              DropdownMenu<MuscleList>(
                width: MediaQuery.of(context).size.width * 0.5,
                enabled: true,
                //initialSelection: MuscleList.Pectoralis_major,
                controller: MuscleController,
                requestFocusOnTap: false,

                label: const Text('Muscles'),
                onSelected: (MuscleList? name) {
                  setState(() {
                    selectedMuscle = name;
                  });
                },
                dropdownMenuEntries: MuscleList.values
                    .map<DropdownMenuEntry<MuscleList>>((MuscleList name) {
                  return DropdownMenuEntry<MuscleList>(
                    value: name,
                    label: name.muscleName,
                  );
                }).toList(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder(
                valueListenable: Hive.box<Exercise>('Exercises').listenable(),
                builder: (context, Box<Exercise> box, _) {
                  var items = box.values.toList();
                  //box.values.toList();
                  if (box.isNotEmpty) {
                    return ListView.builder(
                        itemCount: box.values.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final currentData = box.getAt(index);
                          final exerciseType = currentData!.type;
                          final repBase = currentData.defaultRepBase;
                          final repMax = currentData.defaultRepMax;
                          final increment = currentData.defaultIncrement;
                          final itemList = [
                            FontAwesomeIcons.dumbbell,
                            Icons.forklift,
                            Icons.cable,
                            Icons.sports_martial_arts
                          ];
                          final currentIcon = itemList[exerciseType];
                          return ListTile(
                              leading: CircleAvatar(
                                radius: 17.5,
                                child: FaIcon(currentIcon),
                              ),
                              trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) => Dialog(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  const Text(
                                                      'Confirm Deletion:'),
                                                  const SizedBox(height: 15),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      box.delete(item.key);
                                                      Box setbox = Hive.box<TrainingSet>('TrainingSets');
                                                      var items = setbox.values.toList();
                                                      items = setbox.values.where((item) => item.exercise == currentData.name).toList();   
                                                      for (var item in items){
                                                        setbox.delete(item.key);
                                                      }
                                                    },
                                                    child:
                                                        const Text('Confirm'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ))),
                              title: Text(currentData.name),
                              subtitle: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text("$repBase/$repMax with $increment kg")
                                  ]),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ExerciseScreen(currentData.name)));
                              });
                        });
                  } else {
                    return const Text("No exercises yet");
                  }
                }),
          )
        ]);
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
