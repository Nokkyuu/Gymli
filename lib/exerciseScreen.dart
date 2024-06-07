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
import 'database.dart' as db;
import 'package:flutter/services.dart';
import "package:collection/collection.dart";

enum ExerciseType { warmup, work, dropset }

const List<Color> graphColors = [
Color.fromARGB(255, 0,109,44),
Color.fromARGB(255, 44,162,95),
Color.fromARGB(255, 102,194,164),
Color.fromARGB(255, 153,216,201),
];

const List<Color> twinColors = [
Color.fromARGB(255, 254,240,217),
Color.fromARGB(255, 253,204,138),
Color.fromARGB(255, 252,141,89),
Color.fromARGB(255, 215,48,31)];

final workIcons = [FontAwesomeIcons.fire, FontAwesomeIcons.handFist, FontAwesomeIcons.arrowDown];

class ExerciseScreen extends StatefulWidget {
  final String exerciseName;
  final String workoutDescription;
  const ExerciseScreen(this.exerciseName, this.workoutDescription, {super.key});

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
  DateTime lastActivity = DateTime.now();
  DateTime workoutStartTime = DateTime.now();

  Text warmText = const Text('Warm');
  Text workText = const Text('Work');
  Text dropText = const Text('Drop');
  late int numWarmUps, numWorkSets, numDropSets;

  late InputFields inputFieldAccessor = InputFields(weightDg: weightDg, weightKg: weightKg, repetitions: repetitions);
  Set<ExerciseType> _selected = {ExerciseType.work};

  List<List<FlSpot>> trainingGraphs = [[], [], [], []];
  List<List<FlSpot>> additionalGraphs = [[], [], [], []];


  Future<int> addSet(String exerciseName, double weight, int repetitions, int setType, String when) async {
    var box = Hive.box<TrainingSet>('TrainingSets');
    var exercise = db.get_exercise(exerciseName);
    box.add(TrainingSet(exercise: exerciseName,date: DateTime.parse(when),setType: setType,weight: weight,repetitions: repetitions,baseReps: exercise.defaultRepBase,maxReps: exercise.defaultRepMax,increment: exercise.defaultIncrement,machineName: ""));
    return 0;
  }


  Map<int, List<TrainingSet>> get_exercises() {
    Map<int, List<TrainingSet>> data = {};
    List<TrainingSet> trainings = db.getExerciseTrainings(widget.exerciseName);
    trainings = trainings.where((t) => DateTime.now().difference(t.date).inDays < globals.graphNumberOfDays && t.setType > 0).toList();
    for (var t in trainings) {
      int diff = DateTime.now().difference(t.date).inDays;
      if (!data.containsKey(diff)) { data[diff] = []; }
      data[diff]!.add(t);
    }
    return data;
  }

  void updateGraph() {
    for (var t in trainingGraphs) { t.clear(); }
    setState(() {
      var dat = get_exercises();
      for (var k in dat.keys) {
        for (var i = 0; i < 4; ++i) {
          if (i >= dat[k]!.length) {
            trainingGraphs[i].add(FlSpot.nullSpot);
          } else {
            trainingGraphs[i].add(FlSpot(-k.toDouble(), globals.calculateScore(dat[k]![i])));
          }
        }
      }
    });
  }

  _scrollToBottom() { _scrollController.jumpTo(_scrollController.position.maxScrollExtent); }

 @override
  void dispose() {
    timer.cancel(); // Cancel the timer when the state is disposed
    super.dispose();
  }

  void notifyIdle() {
    int numberOfNotifies = 3;
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      HapticFeedback.vibrate();
      if (--numberOfNotifies == 0) { timer.cancel(); }
    });
  }

  void updateLastWeightSetting() {
    print("jo");
    Tuple2<double, int> latestTrainingInfo = db.getLastTrainingInfo(widget.exerciseName);
    double weight = latestTrainingInfo.item1;
    if (_selected == ExerciseType.warmup) {
      weight /= 2.0;
    }
    setState(() {
      // TODO: is redundant, aye
      inputFieldAccessor.weightKg = weight.toInt();
      inputFieldAccessor.weightDg = (weight * 100.0).toInt() % 100;
      inputFieldAccessor.repetitions = latestTrainingInfo.item2;
      weightKg = weight.toInt();
      weightDg = (weight * 100.0).toInt() % 100;
      repetitions = latestTrainingInfo.item2;
    });
  }

  @override
  void initState() {
    super.initState();
    var trainings = db.getTrainings(DateTime.now());
    if (trainings.isNotEmpty) {
      workoutStartTime = trainings[0].date;
      lastActivity = trainings.last.date;
    }
    var duration = DateTime.now().difference(lastActivity);
    var workoutDuration = DateTime.now().difference(workoutStartTime);
    timerText = Text("Working out: ${workoutDuration.toString().split(".")[0]} - Idle: ${duration.toString().split(".")[0]}");

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        var duration = DateTime.now().difference(lastActivity);
        if (duration.inSeconds == globals.idleTimerWakeup) { notifyIdle(); }
        var workoutDuration = DateTime.now().difference(workoutStartTime);
        String workoutString = workoutDuration.toString().split(".")[0]; // ewwww, nasty
        workoutString = workoutString.split(":")[0] + ":" + workoutString.split(":")[1];
        timerText = Text("Working out: ${workoutString} - Idle: ${duration.toString().split(".")[0]}");
      });
    });
    
    updateGraph();
    for (int i = 0; i < trainingGraphs.length; ++i) {
      if (trainingGraphs[i].isNotEmpty) {
        barData.add(LineChartBarData(
          spots: trainingGraphs[i],
          color: graphColors[i])
          );
      }
    }
    if (trainingGraphs[0].isNotEmpty) {
      maxHistoryDistance = min(trainingGraphs[0][0].x*-1, maxHistoryDistance);
    }

    if (widget.workoutDescription != "") {
      var tokens = widget.workoutDescription.split(":");
      numWarmUps = int.parse(tokens[1].split(",")[0]);
      numWorkSets = int.parse(tokens[2].split(",")[0]);
      numDropSets = int.parse(tokens[3]);
    } else {
      numWarmUps = numWorkSets = numDropSets = 0;
    }
    updateTexts();
    updateLastWeightSetting();
  }
  
  void updateTexts() async {
    var box = Hive.box<TrainingSet>('TrainingSets');
    var items = box.values.where((item) => item.exercise == widget.exerciseName).toList();
    var today = DateTime.now();
    items = items.where((item) => item.date.day == today.day &&item.date.month == today.month &&item.date.year == today.year).toList();
    for (var i in items) {
      if (i.setType == 0) { numWarmUps -= 1; }
      else if (i.setType == 1) { numWorkSets -= 1; }
      else { numDropSets -=1; }
    }
    setState(() {
      warmText = numWarmUps > 0 ? Text("${numWarmUps}x Warm") : const Text("Warm");
      workText = numWorkSets > 0 ? Text("${numWorkSets}x Work") : const Text("Work");
      dropText = numDropSets > 0 ? Text("${numDropSets}x Drop") : const Text("Drop");
    });
  }
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    TextEditingController dateInputController = TextEditingController(text: DateTime.now().toString());


    var minScore = 1e6;
    var maxScore = 0.0;
    for (var i = 0; i < 4; ++i) {
      for (var d in trainingGraphs[i]) {
        if (!d.y.isNaN) {
          minScore = min(minScore, d.y);
          maxScore = max(maxScore, d.y);
        }
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
          title: Text(widget.exerciseName),
          bottom: PreferredSize(preferredSize: Size.zero, child: timerText),
          actions: [
            IconButton(
                onPressed: () { Navigator.push(context, MaterialPageRoute( builder: (context) => ExerciseSetupScreen(widget.exerciseName))); },
                icon: const Icon(Icons.edit)),
            IconButton(
                onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ExerciseListScreen(widget.exerciseName))); },
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
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        clipData: const FlClipData.all(),
                        lineBarsData: barData,
                        minY: minScore - 5.0, maxY: maxScore + 5.0,
                        minX: -maxHistoryDistance, maxX: 1.0,
                      ))),
                )),
            const Divider(),
            Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    SegmentedButton<ExerciseType>(
                      showSelectedIcon: false,
                      segments: <ButtonSegment<ExerciseType>>[
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.warmup,
                            label: warmText,
                            icon: const Icon(Icons.local_fire_department)),
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.work,
                            label: workText,
                            icon: const FaIcon(FontAwesomeIcons.handFist)),
                        ButtonSegment<ExerciseType>(
                            value: ExerciseType.dropset,
                            label: dropText,
                            icon: const Icon(Icons.south_east)),
                      ],
                      selected: _selected,
                      onSelectionChanged: (newSelection){
                        setState(() {
                          _selected = newSelection;
                          updateLastWeightSetting();
                        }
                        );},
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
                double new_weight = inputFieldAccessor.weightKg.toDouble() + inputFieldAccessor.weightDg.toDouble() / 100.0;
                if (_selected.first.index == 0) { numWarmUps -= 1; }
                else if (_selected.first.index == 1) { numWorkSets -= 1; }
                else { numDropSets -= 1; }
                addSet(widget.exerciseName, new_weight, inputFieldAccessor.repetitions, _selected.first.index, dateInputController.text);
                updateTexts();
                updateGraph(); 
                lastActivity = DateTime.now();
              }
              
            ),
            const Divider(),
            Expanded(
                child: ValueListenableBuilder(
                    valueListenable: Hive.box<TrainingSet>('TrainingSets').listenable(),
                    builder: (context, Box<TrainingSet> box, _) {
                      var items = box.values.where((item) => item.exercise == widget.exerciseName).toList();
                      var today = DateTime.now();
                      items = items.where((item) => item.date.day == today.day && item.date.month == today.month && item.date.year == today.year).toList();
                      if (items.isNotEmpty) {
                        return ListView.builder(
                            controller: _scrollController,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                leading: CircleAvatar(radius: 17.5, child: FaIcon(workIcons[item.setType])),
                                dense: true,
                                visualDensity: const VisualDensity(vertical: -3),
                                title: Text("${item.weight}kg for ${item.repetitions} reps"),
                                subtitle: Text("${item.date.hour}:${item.date.minute}:${item.date.second}"),
                                trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () {
                                  box.delete(item.key);
                                  updateGraph();
                                }),
                              );
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
            const SizedBox(height: 20),
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

  void update(int kg, int dg, int rep) {
    setState(() {

    });
  }

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
