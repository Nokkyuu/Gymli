import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/exerciseListScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:yafa_app/DataModels.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'dart:math';

enum ExerciseType { warmup, work, dropset }

final workIcons = [Icons.local_fire_department, Icons.rowing, Icons.south_east];

List<DateTime> getTrainingDates(String exercise) {
  var box = Hive.box<TrainingSet>('TrainingSets');
  var items = box.values.where((item) => item.exercise == exercise).toList();
  final dates = items.map((e) => DateFormat('yyyy-MM-dd').format(e.date)).toSet().toList();
  dates.sort((a, b) { return a.toLowerCase().compareTo(b.toLowerCase());});  // wiederum etwas hacky
  List<DateTime> trainingDates = [];
  for (var d in dates) {
    trainingDates.add(DateFormat('yyyy-MM-dd').parse(d));
  }
  return trainingDates;
}

List<FlSpot> getTrainingScores(String exercise) {
  List<FlSpot> scores = [];
  var trainings = Hive.box<TrainingSet>('TrainingSets').values.toList();
  var trainingDates = getTrainingDates(exercise);
  var i = 0;
  for (var d in trainingDates) {
    var day_diff = d.difference(DateTime.now()).inDays;
    if (day_diff > -5) {
      var subTrainings = trainings.where((item) => item.date.day == d.day && item.date.month == d.month && item.date.year == d.year).toList();
      scores.add(FlSpot((-1 * day_diff).toDouble(), subTrainings.first.weight));
    }
  }
  // dates.sort((a, b) { return a.toLowerCase().compareTo(b.toLowerCase());});  // wiederum etwas hacky

  return scores;
}

Future<int> addSet(String exercise, double weight, int repetitions, int setType, String when) async {
  var box = Hive.box<TrainingSet>('TrainingSets');
  var theDate = DateTime.parse(when);
  // TrainingSet ({required this.id, required this.exercise, required this.date, required this.weight, required this.repetitions, required this.setType, required this.baseReps, required this.maxReps, required this.increment, required this.machineName});
  box.add(TrainingSet(exercise: exercise, date: theDate, setType: setType, weight:weight, repetitions: repetitions, baseReps: 8, maxReps: 12, increment: 5.0, machineName: ""));
  return 0;
}

class ExerciseScreen extends StatefulWidget {
  final String exerciseName;
  const ExerciseScreen(this.exerciseName, {super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreen();
}
class _ExerciseScreen extends State<ExerciseScreen> {
  // late String exerciseName;
  Set<ExerciseType> _selected = {ExerciseType.warmup};
  var _newData = 0.0;
  List<FlSpot> graphData = [ FlSpot(0, 0)];
  void updateSelected(Set<ExerciseType> newSelection) async {
    setState(() {
      _selected = newSelection;
    });
    updateGraph();
  }
  void updateGraph() async {
    setState(() {
      if (graphData.last.x == 0) {
        graphData.removeLast();
      }
      if (_newData > 0.0) {
        graphData.add(FlSpot(0, _newData));
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    var title = widget.exerciseName;

    TextEditingController weightController = TextEditingController(text: '15');
    TextEditingController repetitionController = TextEditingController(text: '10');
    TextEditingController dateInputController = TextEditingController(text: DateTime.now().toString());
    graphData = getTrainingScores(widget.exerciseName);

    return MaterialApp(
      theme: Theme.of(context),
      title: title,
      home: Scaffold(
        appBar: AppBar(
          leading: InkWell( onTap: () {Navigator.pop(context); },
          
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black54,
          ),),
          title: Text(title),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
              width: 500, 
              height: 130,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                    spots: graphData
                  ),
                ],
              )
            )
            ),
          Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<TrainingSet>('TrainingSets').listenable(),
                builder: (context, Box<TrainingSet> box, _) {
                  var items = box.values.where((item) => item.exercise == widget.exerciseName).toList();
                  var today = DateTime.now();
                  items = items.where((item) => item.date.day == today.day && item.date.month == today.month && item.date.year == today.year).toList();
                  if (!items.isEmpty) {
                    return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: CircleAvatar(radius: 17.5,backgroundColor: Colors.cyan,child: Icon(workIcons[item.setType], color: Colors.white,),),
                        title: Text("${item.weight} for ${item.repetitions} reps"),
                        subtitle: Text("${item.date.hour}:${item.date.minute}:${item.date.second}"),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciseListScreen()),);
                        }
                      );
                    });
                  } else {
                    return const Text("No Training yet.");
                  }
                }
              )
            ),
            SegmentedButton<ExerciseType>(
              segments: const <ButtonSegment<ExerciseType>>[
                ButtonSegment<ExerciseType>(
                    value: ExerciseType.warmup,
                    label: Text('Warmup'),
                    icon: Icon(Icons.local_fire_department)
                    ),
                ButtonSegment<ExerciseType>(
                    value: ExerciseType.work,
                    label: Text('Work'),
                    icon: Icon(Icons.rowing)
                    ),
                ButtonSegment<ExerciseType>(
                    value: ExerciseType.dropset,
                    label: Text('Dropset'),
                    icon: Icon(Icons.south_east)
                    ),
                    
              ],
              selected: _selected,
              onSelectionChanged: updateSelected,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 50),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: dateInputController,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                )
            ]),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 50, bottom: 10),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: weightController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'kg',),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: repetitionController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'reps',),
                    keyboardType: TextInputType.number
                  ),
                ),
                TextButton(
                  style: const ButtonStyle(),
                  onPressed: () { 
                    addSet(widget.exerciseName, double.parse(weightController.text), int.parse(repetitionController.text), _selected.first.index, dateInputController.text);
                    _newData = max(_newData, double.parse(weightController.text));
                    updateGraph();
                  },
                  child: const Text('Submit'),
                ),
              ])
            ),
          const Padding(
            padding: EdgeInsets.only(bottom: 50)
          ),]
          //               Row(
          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          // mainAxisSize: MainAxisSize.max,
          // children: <Widget>[
          // TextButton(
          //   style: ButtonStyle(
          //   ),
          //   onPressed: () { },
          //   child: Text('Training Stoppen'),
          // ),
          // const Text("Dauer 00:41:32 ")
          // ]),

        ),
      ),
    );
  }
}

/// The base class for the different types of items the list can contain.
abstract class ListItem {
  Widget buildTitle(BuildContext context);
  Widget buildSubtitle(BuildContext context);
  Widget buildIcon(BuildContext context);
}
// add new button?
class ExerciseItem implements ListItem {
  final String exerciseName;
  final String meta;
  final IconData workIcon;

  ExerciseItem(this.exerciseName, this.meta, this.workIcon);
  @override
  Widget buildTitle(BuildContext context) => Text(exerciseName);
  @override
  Widget buildSubtitle(BuildContext context) => Text(meta);
  @override
  Widget buildIcon(BuildContext context) => CircleAvatar(radius: 17.5,backgroundColor: Colors.cyan,child: Icon(workIcon, color: Colors.white,),);
}