import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
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
  ExerciseList? selectedExercise;
  int warmUpS = 0;
  int workS = 0;
  int dropS = 0;

  @override
  Widget build(BuildContext context) {
    const title = 'Workout Editor';

    return MaterialApp(
      title: title,
      home: Scaffold(
          appBar: AppBar(
            leading: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black54,
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
                  //TODO: Fonz Size
                  obscureText: false,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Workout Name',
                    //alignLabelWithHint: true
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('Warm Ups: $warmUpS'),
                      NumberPicker(
                        value: warmUpS,
                        minValue: 0,
                        maxValue: 10,
                        onChanged: (value) => setState(() => warmUpS = value),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Work Sets: $workS'),
                      NumberPicker(
                        value: workS,
                        minValue: 0,
                        maxValue: 10,
                        onChanged: (value) => setState(() => workS = value),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Drop Sets: $dropS'),
                      NumberPicker(
                        value: dropS,
                        minValue: 0,
                        maxValue: 10,
                        onChanged: (value) => setState(() => dropS = value),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  DropdownMenu<ExerciseList>(
                    initialSelection: ExerciseList.Benchpress,
                    controller: exerciseController,
                    requestFocusOnTap: true,
                    label: const Text('Exercises'),
                    onSelected: (ExerciseList? name) {
                      setState(() {
                        selectedExercise = name;
                      });
                    },
                    dropdownMenuEntries: ExerciseList.values
                        .map<DropdownMenuEntry<ExerciseList>>(
                            (ExerciseList name) {
                      return DropdownMenuEntry<ExerciseList>(
                        value: name,
                        label: name.exerciseName,
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

                ],),
              Divider(),
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
          )),
    );
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
      leading: const Icon(Icons.sports_tennis),
      title: Text(exerciseName),
      subtitle: Text('Warm Ups: $warmUpS, Work Sets: $workS, Drop Sets: $dropS'),
      trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed:  () => print("deleted")
                  ),
    );
  }
}