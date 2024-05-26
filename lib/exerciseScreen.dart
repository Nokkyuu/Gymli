// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/exerciseListScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum ExerciseType { warmup, work, dropset }

final workIcons = [
  FontAwesomeIcons.fire,
  FontAwesomeIcons.handFist,
  FontAwesomeIcons.arrowDown
];

List<DateTime> getTrainingDates(String exercise) {
  var box = Hive.box<TrainingSet>('TrainingSets');
  var items = box.values.where((item) => item.exercise == exercise).toList();
  final dates = items
      .map((e) => DateFormat('yyyy-MM-dd').format(e.date))
      .toSet()
      .toList();
  dates.sort((a, b) {
    return a.toLowerCase().compareTo(b.toLowerCase());
  }); // wiederum etwas hacky
  List<DateTime> trainingDates = [];
  for (var d in dates) {
    trainingDates.add(DateFormat('yyyy-MM-dd').parse(d));
  }
  return trainingDates;
}

List<FlSpot> getTrainingScores(String exercise) {
  List<FlSpot> scores = [];
  var trainings = Hive.box<TrainingSet>('TrainingSets').values.toList();
  trainings = trainings.where((item) => item.exercise == exercise).toList();
  var trainingDates = getTrainingDates(exercise);
  //var i = 0;
  for (var d in trainingDates) {
    final dayDiff = d.difference(DateTime.now()).inDays;

    // if (day_diff > -21) {
    var subTrainings = trainings
        .where((item) =>
            item.date.day == d.day &&
            item.date.month == d.month &&
            item.date.year == d.year)
        .toList();
    var currentScore = 0.0;
    for (var s in subTrainings) {
      currentScore = max(
          currentScore,
          s.weight +
              ((s.repetitions - s.baseReps) / (s.maxReps - s.baseReps)) *
                  s.increment);
    }
    scores.add(FlSpot((dayDiff).toDouble(), currentScore));
    // }
  }

  return scores;
}

Future<int> addSet(String exercise, double weight, int repetitions, int setType,
    String when) async {
  var box = Hive.box<TrainingSet>('TrainingSets');
  var theDate = DateTime.parse(when);
  // TrainingSet ({required this.id, required this.exercise, required this.date, required this.weight, required this.repetitions, required this.setType, required this.baseReps, required this.maxReps, required this.increment, required this.machineName});
  box.add(TrainingSet(
      exercise: exercise,
      date: theDate,
      setType: setType,
      weight: weight,
      repetitions: repetitions,
      baseReps: 8,
      maxReps: 12,
      increment: 5.0,
      machineName: ""));
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
final ScrollController _scrollController = ScrollController();  
TextEditingController weightController = TextEditingController();
    TextEditingController repetitionController =
        TextEditingController();
//   @override
//   void initState() {
//   super.initState();
// }

  Set<ExerciseType> _selected = {ExerciseType.warmup};
  var _newData = 0.0;
  List<FlSpot> graphData = [const FlSpot(0, 0)];
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

    
      _scrollToBottom() {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    var title = widget.exerciseName;

    

    
    TextEditingController dateInputController =
        TextEditingController(text: DateTime.now().toString());
    graphData = getTrainingScores(widget.exerciseName);

    var minScore = 1e6;
    var maxScore = 0.0;
    for (var d in graphData) {
      minScore = min(minScore, d.y);
      maxScore = max(maxScore, d.y);
    }

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
        title: Text(title),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(left: 50, right: 50, bottom: 10),
                child: Column(
                  children: [
                    
                    const SizedBox(height: 10),
                    SegmentedButton<ExerciseType>(
                      segments: const <ButtonSegment<ExerciseType>>[
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.warmup,
                            label: Text('Warmup'),
                            icon: Icon(Icons.local_fire_department)),
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.work,
                            label: Text('Work'),
                            icon: FaIcon(FontAwesomeIcons.handFist)),
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.dropset,
                            label: Text('Dropset'),
                            icon: Icon(Icons.south_east)),
                      ],
                      selected: _selected,
                      onSelectionChanged: updateSelected,
                    ),
                    const SizedBox(height: 10),
                    InputFields(weightController: weightController, repetitionController: repetitionController),
                    const SizedBox(height: 10),
                    
                  ],
                )),

            TextButton.icon(
              style: const ButtonStyle(),
              label: const Text('Submit'),
              icon: const Icon(Icons.send),
              onPressed: () {
                addSet(
                    widget.exerciseName,
                    double.parse(weightController.text),
                    int.parse(repetitionController.text),
                    _selected.first.index,
                    dateInputController.text);
                _newData = max(_newData,
                    double.parse(weightController.text));
                updateGraph();
              },
            ),
            SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.3,
                child: LineChart(LineChartData(
                  lineBarsData: [
                    LineChartBarData(spots: graphData),
                  ],
                  minY: minScore - 5.0,
                  maxY: maxScore + 5.0,
                ))),
            const Divider(),
                    Expanded(
                child: ValueListenableBuilder(
                    valueListenable:
                        Hive.box<TrainingSet>('TrainingSets').listenable(),
                    builder: (context, Box<TrainingSet> box, _) {
                      var items = box.values
                          .where((item) => item.exercise == widget.exerciseName)
                          .toList();
                      var today = DateTime.now();
                      items = items
                          .where((item) =>
                              item.date.day == today.day &&
                              item.date.month == today.month &&
                              item.date.year == today.year)
                          .toList();
                      if (items.isNotEmpty) {
                        return ListView.builder(
                          //reverse: true,
                          controller: _scrollController,

                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                  leading: CircleAvatar(
                                    radius: 17.5,
                                    //backgroundColor: Colors.cyan,
                                    child: FaIcon(
                                      workIcons[item.setType],
                                    ),
                                  ),
                                  title: Text(
                                      "${item.weight} for ${item.repetitions} reps"),
                                  subtitle: Text(
                                      "${item.date.hour}:${item.date.minute}:${item.date.second}"),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ExerciseListScreen()),
                                    );
                                  });
                            });
                      } else {
                        return const Text("No Training yet.");
                      }
                    })),
            // const Divider(),
            // const Padding(padding: EdgeInsets.only(bottom: 50)),
          ]),
    );
  }
}

class InputFields extends StatelessWidget {
  const InputFields({
    super.key,
    required this.weightController,
    required this.repetitionController,
  });

  final TextEditingController weightController;
  final TextEditingController repetitionController;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: weightController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              // keyboardType: TextInputType.number,
            ),
          ),
          Expanded(
            child: TextField(
                controller: repetitionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixText: 'reps',
                ),
                // keyboardType: TextInputType.number
                ),
          ),
          
        ]);
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
  Widget buildIcon(BuildContext context) => CircleAvatar(
        radius: 17.5,
        backgroundColor: Colors.cyan,
        child: Icon(
          workIcon,
          color: Colors.white,
        ),
      );
}
