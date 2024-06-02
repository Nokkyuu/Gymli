// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Gymli/exerciseListScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:Gymli/DataModels.dart';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:tuple/tuple.dart';
import 'package:Gymli/exerciseSetupScreen.dart';
import 'globals.dart' as globals;
import 'package:flutter/services.dart';

enum ExerciseType { warmup, work, dropset }

const List<Color> graphColors = [
Color.fromARGB(255, 5,112,176),
Color.fromARGB(255, 116,169,207),
Color.fromARGB(255, 189,201,225),
Color.fromARGB(255, 241,238,246)];

const List<Color> twinColors = [
Color.fromARGB(255, 254,240,217),
Color.fromARGB(255, 253,204,138),
Color.fromARGB(255, 252,141,89),
Color.fromARGB(255, 215,48,31)];

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
    if (dayDiff > -(globals.graphNumberOfDays)) {
      var subTrainings = trainings
          .where((item) =>
              item.date.day == d.day &&
              item.date.month == d.month &&
              item.date.year == d.year).toList();
      subTrainings = subTrainings.where((item) => item.setType > 0).toList();
      if (subTrainings.length > set + 1) {
        var s = subTrainings[set];
        var score = s.weight +
            ((s.repetitions - s.baseReps) / (s.maxReps - s.baseReps)) *
                s.increment;
        scores.add(FlSpot((dayDiff).toDouble(), score));
      }
    }
  }
  print("---");
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
  double maxHistoryDistance = globals.graphNumberOfDays.toDouble();
  late Timer timer;
  List<LineChartBarData> barData = [];
  Text timerText = const Text("Workout: 00:42:21 - Idle: 00:03:45");
  DateTime fictiveStart = DateTime.now();
  DateTime workoutStartTime = DateTime.now();

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

 @override
  void dispose() {
    // Cancel the timer when the state is disposed
    timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    var trainings = globals.getTrainings(DateTime.now());
    if (trainings.isNotEmpty) {
      workoutStartTime = trainings[0].date;
      fictiveStart = trainings.last.date;
    }
    var duration = DateTime.now().difference(fictiveStart);
    var workoutDuration = DateTime.now().difference(workoutStartTime);
    timerText = Text("Working out: ${workoutDuration.toString().split(".")[0]} - Idle: ${duration.toString().split(".")[0]}");

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        var duration = DateTime.now().difference(fictiveStart);
        int secondsSince = duration.inSeconds;
        if (secondsSince >= globals.idleTimerWakeup && secondsSince <= globals.idleTimerWakeup+3) {
          HapticFeedback.vibrate();
        }
        var workoutDuration = DateTime.now().difference(workoutStartTime);
        String workoutString = workoutDuration.toString().split(".")[0]; // ewwww, nasty
        workoutString = workoutString.split(":")[0] + ":" + workoutString.split(":")[1];

        timerText = Text("Working out: ${workoutString} - Idle: ${duration.toString().split(".")[0]}");
        // timerText = Text("ASD");
      });
    // timer.cancel();
    });

    for (var i = 3; i >= 0; --i) {
      trainingGraphs[i] = getTrainingScores(widget.exerciseName, i);
      if (trainingGraphs[i].isNotEmpty) {
        barData.add(LineChartBarData(
            spots: trainingGraphs[i],
            color: graphColors[i]));
      }
    }
    if (trainingGraphs[0].isNotEmpty) {
      maxHistoryDistance = min(trainingGraphs[0][0].x*-1, maxHistoryDistance);

    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    var title = widget.exerciseName;

    TextEditingController dateInputController = TextEditingController(text: DateTime.now().toString());


    // for (int i = 0; i < globals.exercise_twins[widget.exerciseName]!.length; i++) {
    //   additionalGraphs[i] = getTrainingScores(globals.exercise_twins[widget.exerciseName]![i], 0);
    // }

    var minScore = 1e6;
    var maxScore = 0.0;
    Tuple2<double, int> latestTrainingInfo = globals.getLastTrainingInfo(widget.exerciseName);

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
            preferredSize: Size.zero,
            child: timerText
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
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        clipData: const FlClipData.all(),
                        lineBarsData: barData,
                        minY: minScore - 5.0,
                        maxY: maxScore + 5.0,
                        minX: -maxHistoryDistance - 1.0,
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
                fictiveStart = DateTime.now();
              }
              
            ),
            const SizedBox(height: 40),
          ]),
    );
  }
}

// ignore: must_be_immutable
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
          Column(
            children: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.calculator),
                onPressed: () {
                  setState(() {
                    showModalBottomSheet<dynamic>(
                    // isScrollControlled: true,
                    context: context,
                    sheetAnimationStyle: AnimationStyle(
                      duration: const Duration(milliseconds: 0),
                      reverseDuration: const Duration(milliseconds: 0),
                    ),
                    builder: (BuildContext context) {
                      return const WeightConfigurator();
                    },
                  );
                  });
                },
              ),
            ]
          ),
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
          const Spacer(),
          const Spacer()
        ]);
  }
}



class WeightConfigurator extends StatefulWidget {
  const WeightConfigurator({
    super.key,
  });

  @override
  State<WeightConfigurator> createState() => _WeightConfigurator();
}

enum ExerciseDevice { dumbbell, barbell20, barbellhome }
class _WeightConfigurator extends State<WeightConfigurator> {
  double itemHeight = 50.0;
  double itemWidth = 30.0;
  ExerciseDevice selectedDevice = ExerciseDevice.barbell20;
  List<Widget> rightContainers = [];
  late Container acceptRow;
  late DragTarget<Text> accepter ;

  List<TextEditingController> kg_controller = [];
  late List<int> kg_counter = [];

  List<double> kgs = [1, 1.25, 2, 2.5, 5, 10, 20, 25];
  List<String> kg_texts = [" 1", "1¼", " 2", "2½", " 5", "10", "20", "25"];

  void addWeight(String txt) {
    print(txt);
    rightContainers.add(RotatedBox(
                quarterTurns: 1, child:
                Container(
                  color: Colors.black45, width: 110, alignment: Alignment.center, padding: const EdgeInsets.all(2),
                  child: Text("10", style: const TextStyle(color: Colors.white,fontSize: 15.0)),
                ),
              ),);
    
  }
  @override
  void initState() {
    super.initState();
    for (int i = 0; i < kg_texts.length; ++i) {
      kg_controller.add(TextEditingController());
      kg_controller.last.text = "0";
      kg_counter.add(0);
    }
    updateWeight();

    acceptRow = Container(width: 100, height: 100, color: Colors.black87.withOpacity(0.3), child: 
      Row(children: rightContainers,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,)
    );
    accepter = DragTarget<Text>(
            onAcceptWithDetails: (text) {
                setState(() {
                  addWeight(text.data.data!);
                });
            },
            builder: (context, accepted, rejected) {
              return acceptRow;
            });
    addWeight("20");
  }

  void increase(int i) {
    kg_counter[i] += 1;
    kg_controller[i].text = kg_counter[i].toString();
    updateWeight();
  }
  void decrease(int i) {
    kg_counter[i] -= kg_counter[i] > 0 ? 1 : 0;
    kg_controller[i].text = kg_counter[i].toString();
    updateWeight();
  }

  String weightText = "";

  void updateWeight() {
    double currentWeight = 0.0;
    for (int i = 0; i < kgs.length; ++i) {
      currentWeight += kgs[i]*kg_counter[i];
    }
    currentWeight *= 2.0;
    List<double> adds = [2.3, 20.0, 8.6];
    currentWeight += adds[selectedDevice.index];
    currentWeight = 70;
    weightText = "Stacked weight: $currentWeight kg";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              ElevatedButton(
                child: const Text('Escape'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Take weight'),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const Spacer(),
            Text(weightText, style: const TextStyle(fontSize: 20),),
            const SizedBox(height: 20.0),
            SegmentedButton<ExerciseDevice>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<ExerciseDevice>>[
                    ButtonSegment<ExerciseDevice>(
                        value: ExerciseDevice.dumbbell,
                        label: Text('Dumbbell')),
                    ButtonSegment<ExerciseDevice>(
                        value: ExerciseDevice.barbell20,
                        label: Text('Barbell Gym')),
                    ButtonSegment<ExerciseDevice>(
                        value: ExerciseDevice.barbellhome,
                        label: Text('Barbell Home'))
                  ],
                  selected: <ExerciseDevice>{selectedDevice},
                  onSelectionChanged: (Set<ExerciseDevice> newSelection) {
                    setState(() {
                      selectedDevice = newSelection.first;
                      updateWeight();
                    });
                  }),
            const Spacer(),
            const Text("Pick weights on one side"),
            const SizedBox(height: 10.0),
            Wrap(alignment: WrapAlignment.center,
            children: (() {
                List<Widget> widgets = [];
                for (int i = 0; i < kg_texts.length; ++i) {
                  widgets.add(Draggable<Text>(
                  data: Text(kg_texts[i]),
                  feedback: Container(
                    width: 50, height: 30, 
                    color: Colors.black45.withOpacity(0.5),
                    child: Center(child: Text(kg_texts[i], style: TextStyle(color: Colors.white, fontSize: 10.0)),),
                  ),
                  child: Padding(padding: EdgeInsets.only(left: 1, right: 1.0), child: Container(
                    width: 40, height: 30, color: Colors.black45,
                    child: Center(child: Text(kg_texts[i], style: TextStyle(color: Colors.white, fontSize: 14.0)),),
                  ))
                ));
                }
                return widgets;
              })(),
            ),
            SizedBox(height: 10),
            TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Exercise") ,
                onPressed:  () {
                  setState(() {
                    addWeight("20");
                  });
                },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // accepter,

                // RotatedBox(
                //   quarterTurns: 1, child:
                //   Container(
                //     width: 95, alignment: Alignment.center, padding: const EdgeInsets.all(2),
                //     child: const Text('5 kg', style: TextStyle(color: Colors.white,fontSize: 15.0)),
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.all(Radius.circular(6.0)),
                //       color: Colors.black45, 
                //     ),
                //   ),
                // ),
                // Padding(padding:const EdgeInsets.all(1), child:
                //   RotatedBox(
                //   quarterTurns: 1, child:
                //   Container(
                //     color: Colors.black45, width: 110, alignment: Alignment.center, padding: const EdgeInsets.all(2),
                //     child: const Text('10 kg', style: TextStyle(color: Colors.white,fontSize: 15.0)),
                //   ),
                //   ),
                // ),
                // RotatedBox(
                //   quarterTurns: 1, child:
                //   Container(
                //     color: Colors.black45, width: 110, alignment: Alignment.center, padding: const EdgeInsets.all(2),
                //     child: const Text('10 kg', style: TextStyle(color: Colors.white,fontSize: 15.0)),
                //   ),
                // ),
                Container(
                    color: Colors.black54, width: 100, alignment: Alignment.center,
                    child: const Text('bar', style: TextStyle(color: Colors.white, fontSize: 10.0)),
                  ),
                accepter
                // RotatedBox(
                //   quarterTurns: 1, child:
                //   Container(
                //     color: Colors.black45, width: 110, alignment: Alignment.center, padding: const EdgeInsets.all(2),
                //     child: const Text('10 kg', style: TextStyle(color: Colors.white,fontSize: 15.0)),
                //   ),
                // ),
                // Padding(padding:const EdgeInsets.all(1), child:
                //   RotatedBox(
                //   quarterTurns: 1, child:
                //   Container(
                //     color: Colors.black45, width: 110, alignment: Alignment.center, padding: const EdgeInsets.all(2),
                //     child: const Text('10 kg', style: TextStyle(color: Colors.white,fontSize: 15.0)),
                //   ),
                //   ),
                // ),
                // RotatedBox(
                //   quarterTurns: 1, child:
                //   Container(
                //     color: Colors.black45, width: 95, alignment: Alignment.center, padding: const EdgeInsets.all(2),
                //     child: const Text('5 kg', style: TextStyle(color: Colors.white,fontSize: 15.0)),
                //   ),
                // ),
              ]
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: (() {
            //     List<Widget> widgets = [];
            //     for (var variable in kg_texts) {
            //       widgets.add(Text("$variable", style: TextStyle(fontFamily: "Courier New")));
            //     }
            //     return widgets;
            //   })(),
            // ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: (() {
            //     List<Widget> widgets = [];
            //     for (int i = 0; i < kg_controller.length; ++i) {
            //       widgets.add(SizedBox(
            //     width: 40,
            //     child: TextFormField(
            //       controller: kg_controller[i],
            //       // enabled: false,
            //       decoration: InputDecoration(
            //         labelText: kg_texts[i],
            //         alignLabelWithHint: true, 
            //         labelStyle: const TextStyle(fontSize: 14.0),
            //         border: const OutlineInputBorder(),
            //       ),
            //       textAlign: TextAlign.center,
            //     )));
            //     }
            //     return widgets;
            //     })(),
            // ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: (() {
            //     List<Widget> widgets = [];
            //     for (int i = 0; i < kg_counter.length; ++i) {
            //       widgets.add(
            //         Column(
            //           children: [
            //             IconButton(
            //             icon: const Icon(FontAwesomeIcons.plus),
            //             onPressed: () {
            //               setState(() {
            //                 increase(i);
            //               });
            //             }),
            //             IconButton(
            //             icon: const Icon(FontAwesomeIcons.minus),
            //             onPressed: () {
            //               setState(() {
            //                 decrease(i);
            //               });
            //             }),
            //           ]
            //         )
            //       );
            //     }
            //     return widgets;
            //     })(),
            // ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
