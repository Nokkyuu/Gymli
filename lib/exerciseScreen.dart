// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/exerciseListScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:yafa_app/DataModels.dart';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:tuple/tuple.dart';
import 'package:yafa_app/exerciseSetupScreen.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'globals.dart' as globals;
import 'package:intl/intl.dart';

enum ExerciseType { warmup, work, dropset }

final workIcons = [
  FontAwesomeIcons.fire,
  FontAwesomeIcons.handFist,
  FontAwesomeIcons.arrowDown
];

void get_exercise_list() async {
  final box = await Hive.openBox<Exercise>('Exercises');
  var boxmap = box.values.toList();
  List<String> exerciseList = [];
  for (var e in boxmap) {
    exerciseList.add(e.name);
  }
  globals.exerciseList = exerciseList;
}

List<FlSpot> getTrainingScores(String exercise, int set) {
  List<FlSpot> scores = [];
  var trainings = Hive.box<TrainingSet>('TrainingSets').values.toList();
  trainings = trainings.where((item) => item.exercise == exercise).toList();
  var trainingDates = globals.getTrainingDates(exercise);
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
      if (subTrainings.length > set + 1) {
        var s = subTrainings[set];
        var score = s.weight +
            ((s.repetitions - s.baseReps) / (s.maxReps - s.baseReps)) *
                s.increment;
        scores.add(FlSpot((dayDiff).toDouble(), score));
      }
    }
  }
  return scores;
}

Future<int> addSet(String exerciseName, double weight, int repetitions,
    int setType, String when) async {
  var box = Hive.box<TrainingSet>('TrainingSets');
  var theDate = DateTime.parse(when);
  // TrainingSet ({required this.id, required this.exercise, required this.date, required this.weight, required this.repetitions, required this.setType, required this.baseReps, required this.maxReps, required this.increment, required this.machineName});
  var exercise = globals.get_exercise(exerciseName);

  box.add(TrainingSet(
      exercise: exerciseName,
      date: theDate,
      setType: setType,
      weight: weight,
      repetitions: repetitions,
      baseReps: exercise.defaultRepBase,
      maxReps: exercise.defaultRepMax,
      increment: exercise.defaultIncrement,
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
  late Timer timer;
  List<LineChartBarData> barData = [];
  Text timerText = Text("Workout: 00:42:21 - Idle: 00:03:45");
  DateTime fictiveStart = DateTime.now();

  late InputFields inputFieldAccessor = InputFields(
      weightDg: weightDg, weightKg: weightKg, repetitions: repetitions);
  Set<ExerciseType> _selected = {ExerciseType.work};
  var _newData = 0.0;
  List<List<FlSpot>> trainingGraphs = [[], [], [], []];
  List<List<FlSpot>> additionalGraphs = [[], [], [], []];

  void updateSelected(Set<ExerciseType> newSelection) async {
    setState(() {
      _selected = newSelection;
    });
    updateGraph();
  }

  void updateGraph() async {
    setState(() {
      if (trainingGraphs[0].isNotEmpty && trainingGraphs[0].last.x == 0) {
        trainingGraphs[0].removeLast();
      }
      if (_newData > 0.0) {
        trainingGraphs[0].add(FlSpot(0, _newData));
      }
    });
  }

  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }
  void handleTimeout() {
    setState(() {
      timerText = Text("asd");
    });
  }

 @override
  void dispose() {
    // Cancel the timer when the state is disposed
    timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        var duration = DateTime.now().difference(fictiveStart);
        timerText = Text("${duration.toString().split(".")[0]}");
        // timerText = Text("ASD");
      });
    // timer.cancel();
    });
  }
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    var title = widget.exerciseName;

    TextEditingController dateInputController =
        TextEditingController(text: DateTime.now().toString());
    for (var i = 0; i < 4; ++i) {
      trainingGraphs[i] = getTrainingScores(widget.exerciseName, i);
      if (trainingGraphs[i].isNotEmpty) {
        int reduce = (255 - ((i / 4) * 100)).toInt();
        barData.add(LineChartBarData(
            spots: trainingGraphs[i],
            color: Color.fromARGB(reduce, 33, 150, 243)));
      }
    }

    // for (int i = 0; i < globals.exercise_twins[widget.exerciseName]!.length; i++) {
    //   additionalGraphs[i] = getTrainingScores(globals.exercise_twins[widget.exerciseName]![i], 0);
    // }

    var minScore = 1e6;
    var maxScore = 0.0;
    Tuple2<double, int> latestTrainingInfo =
        globals.getLastTrainingInfo(widget.exerciseName);

    weightKg = latestTrainingInfo.item1.toInt();
    weightDg = (latestTrainingInfo.item1 * 100.0).toInt() % 100;
    repetitions = latestTrainingInfo.item2;

    for (var i = 0; i < 4; ++i) {
      for (var d in trainingGraphs[i]) {
        minScore = min(minScore, d.y);
        maxScore = max(maxScore, d.y);
      }
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
          bottom: PreferredSize(
            child: timerText,
            preferredSize: Size.zero
          ),
          actions: [
            IconButton(
                onPressed: () {
                  get_exercise_list();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExerciseSetupScreen(title)),
                  );
                },
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
                height: MediaQuery.of(context).size.height * 0.20,
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
                        lineBarsData: barData,
                        minY: minScore - 5.0,
                        maxY: maxScore + 5.0,
                        minX: -45.0,
                        maxX: 1.0,
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
                                    child: FaIcon(
                                      workIcons[item.setType],
                                    ),
                                  ),
                                  dense: true,
                                  visualDensity: const VisualDensity(
                                      vertical: -3), // to compact
                                  title: Text(
                                      "${item.weight}kg for ${item.repetitions} reps"),
                                  subtitle: Text(
                                      "${item.date.hour}:${item.date.minute}:${item.date.second}"),
                                  trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => {box.delete(item.key)}),
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
              onPressed: 
              
              () {
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
              }
              
            ),
            const SizedBox(height: 40),
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
