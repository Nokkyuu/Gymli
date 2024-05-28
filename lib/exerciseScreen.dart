// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/exerciseListScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:tuple/tuple.dart';

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

Tuple2<double, int> getLastTrainingInfo(String exercise) {
  var trainings = Hive.box<TrainingSet>('TrainingSets').values.toList();
  trainings = trainings.where((item) => item.exercise == exercise).toList();
  var trainingDates = getTrainingDates(exercise);
  if (trainingDates.isEmpty) {
    return const Tuple2<double, int>(20.0, 10);
  }
  // absolutely horrible solutions
  var best_element = 0;
  var best_element_distance = -999;
  for (var i = 0; i < trainingDates.length; i++) {
    final dayDiff = trainingDates[i].difference(DateTime.now()).inDays;
    if (dayDiff > best_element_distance) {
      best_element = i;
      best_element_distance = dayDiff;
    }
  }
  var d = trainingDates[best_element];
  var latest_trainings = trainings.where((item) =>
      item.date.day == d.day &&
      item.date.month == d.month &&
      item.date.year == d.year);
  var best_weight = -100.0;
  var best_reps = 1;
  for (var s in latest_trainings) {
    if (s.weight > best_weight) {
      best_weight = s.weight;
      best_reps = s.repetitions;
    }
  }
  return Tuple2<double, int>(best_weight, best_reps);
}

List<FlSpot> getTrainingScores(String exercise) {
  List<FlSpot> scores = [];
  var trainings = Hive.box<TrainingSet>('TrainingSets').values.toList();
  trainings = trainings.where((item) => item.exercise == exercise).toList();
  var trainingDates = getTrainingDates(exercise);
  //var i = 0;
  for (var d in trainingDates) {
    final dayDiff = d.difference(DateTime.now()).inDays;

    if (dayDiff > -(6 * 7)) {
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
    }
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
  //final String exerciseName;
  final ScrollController _scrollController = ScrollController();
  int weightKg = 40;
  int weightDg = 0;
  int repetitions = 10;

  late InputFields inputFieldAccessor = InputFields(
      weightDg: weightDg, weightKg: weightKg, repetitions: repetitions);
  Set<ExerciseType> _selected = {ExerciseType.work};
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
      if (graphData.isNotEmpty && graphData.last.x == 0) {
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
    Tuple2<double, int> latestTrainingInfo =
        getLastTrainingInfo(widget.exerciseName);
    
    weightKg = latestTrainingInfo.item1.toInt();
    weightDg = (latestTrainingInfo.item1 * 100.0).toInt() % 100;
    repetitions = latestTrainingInfo.item2;

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
          actions: [
            IconButton(
                onPressed: () => print(
                    "edit exercise"), //TODO: go to exercise setup to edit the current exercise
                icon: const Icon(Icons.edit)),
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExerciseListScreen(title)),
                  );
                },
                icon: const Icon(Icons.list))
          ]),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.25,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Padding(
                      padding: const EdgeInsets.only(
                          right: 10.0,
                          top: 10.0,
                          left: 0.0), // Hier das Padding rechts hinzufügen
                      child: LineChart(LineChartData(
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        clipData: const FlClipData.all(),
                        lineBarsData: [
                          LineChartBarData(spots: graphData),
                        ],
                        minY: minScore - 5.0,
                        maxY: maxScore + 5.0,
                        minX: -30.0,
                        maxX: 0.0,
                      ))),
                )),
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
                                      "${item.weight}kg for ${item.repetitions} reps"),
                                  subtitle: Text(
                                      "${item.date.hour}:${item.date.minute}:${item.date.second}"),
                                  trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => {
                                            box.delete(item.key)
                                    
                                          }),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ExerciseListScreen(title)),
                                    );
                                  });
                            });
                      } else {
                        return ListView(
                          controller: _scrollController,
                          children: const [
                            ListTile(title: Text("No Training yet.")),
                          ],
                        );
                      }
                    })),
            const Divider(),
            Padding(
                padding: const EdgeInsets.only(left: 30, right: 30, bottom: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    SegmentedButton<ExerciseType>(
                      showSelectedIcon: false,
                      segments: const <ButtonSegment<ExerciseType>>[
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.warmup,
                            label: Text('Warm'),
                            icon: Icon(Icons.local_fire_department)),
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.work,
                            label: Text('Work'),
                            icon: FaIcon(FontAwesomeIcons.handFist)),
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.dropset,
                            label: Text('Drop'),
                            icon: Icon(Icons.south_east)),
                      ],
                      selected: _selected,
                      onSelectionChanged: updateSelected,
                    ),
                    const SizedBox(height: 10),
                    inputFieldAccessor,
                  ],
                )),
            ElevatedButton.icon(
              style: const ButtonStyle(),
              label: const Text('Submit'),
              icon: const Icon(Icons.send),
              onPressed: () {
                double new_weight = inputFieldAccessor.weightKg.toDouble() +
                    inputFieldAccessor.weightDg.toDouble() / 100.0;
                addSet(
                    widget.exerciseName,
                    new_weight,
                    inputFieldAccessor.repetitions,
                    _selected.first.index,
                    dateInputController.text);
                _newData = max(_newData, new_weight);
                updateGraph();
              },
            ),
            const SizedBox(height: 20),
          ]),
    );
  }
}

class InputFields extends StatefulWidget {
  // final String exerciseName;
  // const InputFields({super.key});
  int weightKg;
  int weightDg;
  int repetitions;
  InputFields({
    super.key,
    required this.weightKg,
    required this.weightDg,
    required this.repetitions,
  });
  @override
  State<InputFields> createState() => _InputFields();
}

class _InputFields extends State<InputFields> {
  double itemHeight = 35.0;
  double itemWidth = 50.0;
  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          const Spacer(),
          NumberPicker(
            value: widget.weightKg,
            minValue: -70,
            maxValue: 250,
            haptics: true,
            itemHeight: itemHeight,
            itemWidth: itemWidth,
            onChanged: (value) => setState(() => widget.weightKg = value),
          ),
          const Text(","),
          NumberPicker(
            value: widget.weightDg,
            minValue: 0,
            maxValue: 95,
            haptics: true,
            step: 5,
            itemHeight: itemHeight,
            itemWidth: itemWidth,
            onChanged: (value) => setState(() => widget.weightDg = value),
          ),
          const Text("kg"),
          const Spacer(),
          NumberPicker(
            value: widget.repetitions,
            minValue: 1,
            haptics: true,
            maxValue: 25,
            itemHeight: itemHeight,
            itemWidth: itemWidth,
            onChanged: (value) => setState(() => widget.repetitions = value),
          ),
          const Text("Reps"),
          const Spacer()
        ]);
  }
}
