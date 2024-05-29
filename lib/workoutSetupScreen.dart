// ignore_for_file: file_names, constant_identifier_names
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:hive_flutter/hive_flutter.dart';
//import 'package:fl_chart/fl_chart.dart';

enum ExerciseList {
  Benchpress('Benchpress', 2, 3, 1),
  Squat('Squat', 2, 2, 1),
  Deadlift('Deadlift', 2, 3, 2),
  Benchpress2('Benchpress2', 2, 3, 1),
  Squat2('Squat2', 2, 2, 1),
  Deadlift2('Deadlift2', 2, 3, 2);

  const ExerciseList(this.exerciseName, this.warmUpS,this.workS, this.dropS);
  final String exerciseName;
  final int warmUpS;
  final int workS;
  final int dropS;
}

class WorkoutSetupScreen extends StatefulWidget {
  const WorkoutSetupScreen({super.key});

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  final TextEditingController exerciseController = TextEditingController();
  Exercise? selectedExercise;
  int warmUpS = 0;
  int workS = 0;
  int dropS = 0;
  var box = Hive.box<Exercise>('Exercises');
  List<Exercise> allExercises = Hive.box<Exercise>('Exercises').values.toList();
final itemList = [
                            FontAwesomeIcons.dumbbell,
                            Icons.forklift,
                            Icons.cable,
                            Icons.sports_martial_arts];

  @override
  Widget build(BuildContext context) {
    const title = 'Workout Editor';

    return Scaffold(
          appBar: AppBar(
            actions:[IconButton(
          onPressed: () => print("Workout deleted"),  //TODO: delete selected workout if it exists
          icon: const Icon(Icons.delete))],
            leading: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.arrow_back_ios,
              ),
            ),
            title: const Text(title),
            centerTitle: true,
            
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: TextEditingController(text: "Full Body Compound"),
                  obscureText: false,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Workout Name',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text('Warm Ups'),
                      NumberPicker(
                        decoration:BoxDecoration(border: Border.all()),
                        value: warmUpS,
                        minValue: 0,
                        maxValue: 10,
                        onChanged: (value) => setState(() => warmUpS = value),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Work Sets'),
                      NumberPicker(
                        decoration:BoxDecoration(border: Border.all()),
                        value: workS,
                        minValue: 0,
                        maxValue: 10,
                        onChanged: (value) => setState(() => workS = value),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Drop Sets'),
                      NumberPicker(
                        decoration:BoxDecoration(border: Border.all()),
                        value: dropS,
                        minValue: 0,
                        maxValue: 10,
                        onChanged: (value) => setState(() => dropS = value),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Divider(),
              const SizedBox(height: 20),
              DropdownMenu<Exercise>(
                width: MediaQuery.of(context).size.width * 0.7,
                //initialSelection: ExerciseList.Benchpress,
                controller: exerciseController,
                requestFocusOnTap: true,
                label: const Text('Exercises'),
                onSelected: (selectExercises) {
                  setState(() {
                    selectedExercise = selectExercises;
                  });
                },
                dropdownMenuEntries: allExercises
                    .map<DropdownMenuEntry<Exercise>>(
                        (Exercise name) {
                  return DropdownMenuEntry<Exercise>(
                    value: name,
                    label: name.name,
                    
                    leadingIcon: FaIcon(itemList[name.type])
                    //enabled: color.label != 'Grey',
                    //style: MenuItemButton.styleFrom(
                    //  foregroundColor: color.color,
                    //),
                  );
                }).toList(),
              ),
              
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Exercise") ,
                onPressed:  () => print("Added")
              ),
              const Divider(),
              Expanded(
              child: ListView.builder(
              itemCount: ExerciseList.values.length,
              // Provide a builder function. This is where the magic happens.
              itemBuilder: (context, index) {
                final item = ExerciseList.values[index];
                return ExerciseTile(exerciseName: item.exerciseName, warmUpS: item.warmUpS, workS: item.workS, dropS: item.dropS);
              }),
              
            ),
              //for (var Exercise in ExerciseList.values) 
              //  ExerciseTile(exerciseName: Exercise.exerciseName, warmUpS: Exercise.warmUpS, workS: Exercise.workS, dropS: Exercise.dropS),
            ],
          ))
    ;
  }
}


class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exerciseName,
    required this.warmUpS,
    required this.workS,
    required this.dropS,
  });

  final String exerciseName;
  final int warmUpS;
  final int workS;
  final int dropS;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: true,
      leading: const FaIcon(FontAwesomeIcons.dumbbell),
      title: Text(exerciseName),
      subtitle: Text('Warm Ups: $warmUpS, Work Sets: $workS, Drop Sets: $dropS'),
      trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed:  () => print("deleted")
                  ),
    );
  }
}