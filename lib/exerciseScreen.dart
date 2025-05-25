// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:Gymli/exerciseListScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:Gymli/exerciseSetupScreen.dart';
import 'globals.dart' as globals;
import 'package:flutter/services.dart';
import 'user_service.dart';
import 'api_models.dart';

enum ExerciseType { warmup, work }

const List<Color> graphColors = [
  Color.fromARGB(255, 0, 109, 44),
  Color.fromARGB(255, 44, 162, 95),
  Color.fromARGB(255, 102, 194, 164),
  Color.fromARGB(255, 153, 216, 201),
];

const List<Color> additionalColors = [
  Color.fromARGB(255, 253, 204, 138),
  Color.fromARGB(255, 252, 141, 89),
  Color.fromARGB(255, 215, 48, 31)
];

final workIcons = [
  FontAwesomeIcons.fire,
  FontAwesomeIcons.handFist,
  FontAwesomeIcons.arrowDown
];

class ExerciseScreen extends StatefulWidget {
  final String exerciseName;
  final String workoutDescription;
  const ExerciseScreen(this.exerciseName, this.workoutDescription, {super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreen();
}

double itemHeight = 35.0;
double itemWidth = 50.0;

class _ExerciseScreen extends State<ExerciseScreen> {
  //final String exerciseName;
  final ScrollController _scrollController = ScrollController();
  int weightKg = 40;
  int weightDg = 0;
  int repetitions = 10;
  var minScore = 1e6;

  final List<int> _values = List<int>.generate(30, (i) => i + 1);
  Map<int, Color> _colorMap = {};
  var maxScore = 0.0;
  double maxHistoryDistance = globals.graphNumberOfDays.toDouble();
  late Timer timer;
  List<LineChartBarData> barData = [];
  Text timerText = const Text("");
  DateTime lastActivity = DateTime.now();
  DateTime workoutStartTime = DateTime.now();

  Text warmText = const Text('Warm');
  Text workText = const Text('Work');
  late int numWarmUps, numWorkSets;

  String hintText = "Only 1 more Rep until weight increase!";

  Set<ExerciseType> _selected = {ExerciseType.work};

  List<List<FlSpot>> trainingGraphs = [[], [], [], []];
  List<List<FlSpot>> additionalGraphs = [];
  // List<LineTooltipItem> graphToolTip = [];
  List<String> groupExercises = [];
  Map<int, List<String>> graphToolTip = {};

  // State variable for training sets to avoid constant reloading
  List<ApiTrainingSet> _todaysTrainingSets = [];
  bool _isLoadingTrainingSets = false;
  Future<void> _loadTodaysTrainingSets() async {
    if (_isLoadingTrainingSets) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoadingTrainingSets = true;
    });

    try {
      final userService = UserService();
      final trainingSets = await userService.getTrainingSets();
      print('Total training sets retrieved: ${trainingSets.length}');

      final items = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((item) => item.exerciseName == widget.exerciseName)
          .toList();
      print('Training sets for ${widget.exerciseName}: ${items.length}');

      var today = DateTime.now();
      print('Today: ${today.day}/${today.month}/${today.year}');

      for (var item in items) {
        print(
            'Training set date: ${item.date}, day: ${item.date.day}/${item.date.month}/${item.date.year}');
      }

      final todaysItems = items
          .where((item) =>
              item.date.day == today.day &&
              item.date.month == today.month &&
              item.date.year == today.year)
          .toList();
      print('Today\'s training sets: ${todaysItems.length}');

      setState(() {
        _todaysTrainingSets = todaysItems;
        _isLoadingTrainingSets = false;
      });
    } catch (e) {
      print('Error loading today\'s training sets: $e');
      setState(() {
        _isLoadingTrainingSets = false;
      });
    }
  }

  Future<void> _deleteTrainingSet(ApiTrainingSet trainingSet) async {
    try {
      final userService = UserService();
      await userService.deleteTrainingSet(trainingSet.id!);
    } catch (e) {
      print('Error deleting training set: $e');
    }
  }

  Future<int> addSet(String exerciseName, double weight, int repetitions,
      int setType, String when) async {
    try {
      print(
          'Adding set: exercise=$exerciseName, weight=$weight, reps=$repetitions, setType=$setType, when=$when');
      final userService = UserService();
      final exercises = await userService.getExercises();
      final exerciseData = exercises.firstWhere(
        (item) => item['name'] == exerciseName,
        orElse: () => null,
      );

      if (exerciseData != null) {
        final exercise = ApiExercise.fromJson(exerciseData);
        await userService.createTrainingSet(
          exerciseId: exercise.id!,
          date: when,
          weight: weight,
          repetitions: repetitions,
          setType: setType,
          baseReps: exercise.defaultRepBase,
          maxReps: exercise.defaultRepMax,
          increment: exercise.defaultIncrement,
          machineName: "",
        );
        print('Training set created successfully');
      } else {
        print('Exercise not found: $exerciseName');
      }
      return 0;
    } catch (e) {
      print('Error adding training set: $e');
      return -1;
    }
  }

  Future<Map<int, List<ApiTrainingSet>>> get_trainingsets() async {
    try {
      final userService = UserService();
      final trainingSets = await userService.getTrainingSets();

      Map<int, List<ApiTrainingSet>> data = {};
      List<ApiTrainingSet> trainings = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((t) => t.exerciseName == widget.exerciseName)
          .toList();

      trainings = trainings
          .where((t) =>
              DateTime.now().difference(t.date).inDays <
                  globals.graphNumberOfDays &&
              t.setType > 0)
          .toList();

      for (var t in trainings) {
        int diff = DateTime.now().difference(t.date).inDays;
        if (!data.containsKey(diff)) {
          data[diff] = [];
        }
        data[diff]!.add(t);
      }
      return data;
    } catch (e) {
      print('Error getting training sets: $e');
      return {};
    }
  }

  void updateGraph() async {
    for (var t in trainingGraphs) {
      t.clear();
    }

    try {
      if (globals.detailedGraph) {
        var data = await get_trainingsets();
        var ii = data.keys.length;
        for (var k in data.keys) {
          List<String> tips = List.filled(groupExercises.length + 6, "");
          for (var i = 0; i < 4; ++i) {
            if (i < data[k]!.length) {
              trainingGraphs[i].add(
                  FlSpot(-ii.toDouble(), globals.calculateScore(data[k]![i])));
              tips[i] =
                  "${data[k]![i].weight}kg @ ${data[k]![i].repetitions}reps";
            }
          }
          graphToolTip[-ii] = tips;
          ii -= 1;
        }

        // Additional exercise graphs are simplified for now
        // TODO: Implement group-based exercise graphs if needed
      } else {
        var dat = await get_trainingsets();
        var ii = dat.keys.length;
        for (var k in dat.keys) {
          double maxScore = 0.0;
          int reps = 0;
          double weight = 0;
          for (var i = 0; i < dat[k]!.length; ++i) {
            maxScore = max(maxScore, globals.calculateScore(dat[k]![i]));
            reps = dat[k]![i].repetitions;
            weight = dat[k]![i].weight;
          }
          trainingGraphs[0].add(FlSpot(-ii.toDouble(), maxScore));
          graphToolTip[-ii] = ["${weight}kg @ ${reps}reps"];
          ii -= 1;
        }
      }

      setState(() {
        // Graph data updated
      });
    } catch (e) {
      print('Error updating graph: $e');
    }
  }

  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  void dispose() {
    timer.cancel(); // Cancel the timer when the state is disposed
    super.dispose();
  }

  void notifyIdle() {
    int numberOfNotifies = 3;
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      HapticFeedback.vibrate();
      if (--numberOfNotifies == 0) {
        timer.cancel();
      }
    });
  }

  void updateLastWeightSetting() async {
    try {
      final userService = UserService();
      final exercises = await userService.getExercises();
      final exerciseData = exercises.firstWhere(
        (item) => item['name'] == widget.exerciseName,
        orElse: () => null,
      );

      if (exerciseData != null) {
        final exercise = ApiExercise.fromJson(exerciseData);
        final trainingSets = await userService.getTrainingSets();
        final todaysSets = trainingSets
            .map((item) => ApiTrainingSet.fromJson(item))
            .where((t) => t.exerciseName == widget.exerciseName)
            .toList();

        double weight = exercise.defaultIncrement;
        int reps = exercise.defaultRepBase;

        if (todaysSets.isNotEmpty) {
          final lastSet = todaysSets.last;
          weight = lastSet.weight;
          reps = lastSet.repetitions;
        }

        if (_selected.first == ExerciseType.warmup) {
          weight /= 2.0;
          weight = (weight / exercise.defaultIncrement).round() *
              exercise.defaultIncrement;
        }

        var data = await get_trainingsets();
        if (data.isNotEmpty) {
          var last = data[data.keys.last]!.last;
          for (int i = last.baseReps; i <= last.maxReps; ++i) {
            _colorMap[i] = Colors.red;
          }
        }

        setState(() {
          weightKg = weight.toInt();
          weightDg = (weight * 100.0).toInt() % 100;
          repetitions = reps;
        });
      }
    } catch (e) {
      print('Error updating last weight setting: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        var duration = DateTime.now().difference(lastActivity);
        if (duration.inSeconds == globals.idleTimerWakeup) {
          notifyIdle();
        }
        var workoutDuration = DateTime.now().difference(workoutStartTime);
        String workoutString =
            workoutDuration.toString().split(".")[0]; // ewwww, nasty
        workoutString =
            "${workoutString.split(":")[0]}:${workoutString.split(":")[1]}";
        timerText = Text(
            "Working out: $workoutString - Idle: ${duration.toString().split(".")[0]}");
      });
    });
  }

  void _initializeScreen() async {
    try {
      final userService = UserService();
      final trainingSets = await userService.getTrainingSets();
      final todaysTrainingSets = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((t) =>
              t.date.day == DateTime.now().day &&
              t.date.month == DateTime.now().month &&
              t.date.year == DateTime.now().year)
          .toList();

      if (todaysTrainingSets.isNotEmpty) {
        workoutStartTime = todaysTrainingSets.first.date;
        lastActivity = todaysTrainingSets.last.date;
      }

      var duration = DateTime.now().difference(lastActivity);
      var workoutDuration = DateTime.now().difference(workoutStartTime);
      timerText = Text(
          "Working out: ${workoutDuration.toString().split(".")[0]} - Idle: ${duration.toString().split(".")[0]}");

      // Initialize group exercises (simplified for now - no group support)
      groupExercises = [];
      additionalGraphs = List.filled(groupExercises.length, []);

      updateGraph();
      _loadTodaysTrainingSets(); // Load today's training sets on screen open

      for (int i = 0; i < trainingGraphs.length; ++i) {
        if (trainingGraphs[i].isNotEmpty) {
          bool allNan = true;
          for (var t in trainingGraphs[i]) {
            if (!t.x.isNaN) {
              allNan = false;
            }
          }
          if (!allNan) {
            barData.add(
              LineChartBarData(spots: trainingGraphs[i], color: graphColors[i]),
            );
          }
        }
      }

      for (int i = 0; i < additionalGraphs.length; ++i) {
        if (additionalGraphs[i].isNotEmpty) {
          barData.add(
            LineChartBarData(
                spots: additionalGraphs[i], color: additionalColors[i]),
          );
        }
      }

      for (var i = 0; i < 4; ++i) {
        for (var d in trainingGraphs[i]) {
          if (!d.y.isNaN) {
            minScore = min(minScore, d.y);
            maxScore = max(maxScore, d.y);
          }
        }
      }

      if (trainingGraphs[0].isNotEmpty) {
        maxHistoryDistance =
            min(trainingGraphs[0][0].x * -1, maxHistoryDistance);
      }

      if (widget.workoutDescription != "") {
        var tokens = widget.workoutDescription.split(":");
        numWarmUps = int.parse(tokens[1].split(",")[0]);
        numWorkSets = int.parse(tokens[2].split(",")[0]);
        // Skip dropsets - tokens[3] is ignored
      } else {
        numWarmUps = numWorkSets = 0;
      }

      updateTexts();
      updateLastWeightSetting();

      setState(() {
        // Update UI with loaded data
      });
    } catch (e) {
      print('Error initializing screen: $e');
    }
  }

  void updateTexts() async {
    try {
      final userService = UserService();
      final trainingSets = await userService.getTrainingSets();
      final items = trainingSets
          .map((item) => ApiTrainingSet.fromJson(item))
          .where((item) => item.exerciseName == widget.exerciseName)
          .toList();

      var today = DateTime.now();
      final todaysItems = items
          .where((item) =>
              item.date.day == today.day &&
              item.date.month == today.month &&
              item.date.year == today.year)
          .toList();

      for (var i in todaysItems) {
        if (i.setType == 0) {
          numWarmUps -= 1;
        } else if (i.setType == 1) {
          numWorkSets -= 1;
        }
        // No longer handling dropsets (setType == 2)
      }

      setState(() {
        warmText =
            numWarmUps > 0 ? Text("${numWarmUps}x Warm") : const Text("Warm");
        workText =
            numWorkSets > 0 ? Text("${numWorkSets}x Work") : const Text("Work");
      });
    } catch (e) {
      print('Error updating texts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    TextEditingController dateInputController =
        TextEditingController(text: DateTime.now().toString());

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ExerciseSetupScreen(widget.exerciseName)));
                },
                icon: const Icon(Icons.edit)),
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ExerciseListScreen(widget.exerciseName)));
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
                          right: 10.0, top: 10.0, left: 0.0),
                      child: LineChart(LineChartData(
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        clipData: const FlClipData.all(),
                        lineBarsData: barData,
                        lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 0.0,
                          showOnTopOfTheChartBoxArea: false,
                          fitInsideVertically: true,
                          tooltipMargin: 0,
                          getTooltipItems: (value) {
                            return value.map((e) {
                              return LineTooltipItem(
                                  graphToolTip[e.x.toInt()]![e.barIndex],
                                  const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ));
                            }).toList();
                          },
                        )),
                        minY: minScore - 5.0,
                        maxY: maxScore + 5.0,
                        minX: -maxHistoryDistance,
                        maxX: 0,
                      ))),
                )),
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: (() {
                var boxdim = 8.0;
                List<Widget> widgets = [
                  const SizedBox(width: 20),
                  const Text("Sets", style: const TextStyle(fontSize: 8.0)),
                  const SizedBox(width: 10)
                ];
                for (int i = 0; i < 4; i++) {
                  widgets.add(Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                            width: boxdim,
                            height: boxdim,
                            color: graphColors[i]),
                        Text("  $i", style: const TextStyle(fontSize: 8.0)),
                        const SizedBox(width: 10)
                      ]));
                }
                for (int i = 0; i < groupExercises.length; ++i) {
                  widgets.add(Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                            width: boxdim,
                            height: boxdim,
                            color: additionalColors[i]),
                        Text("  ${groupExercises[i]}",
                            style: const TextStyle(fontSize: 8.0)),
                        const SizedBox(width: 10)
                      ]));
                }
                return widgets;
              })(),
            ),
            // const Divider(),
            // Row(mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Image.asset('images/fairy.png',
            //       fit: BoxFit.contain,
            //       height: 18,
            //       ),
            //       const SizedBox(width: 10),
            //       Text(hintText),
            //   ],
            // ),
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
                      ],
                      selected: _selected,
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          if (_selected.first == ExerciseType.warmup ||
                              newSelection.first == ExerciseType.warmup) {
                            _selected = newSelection;
                            updateLastWeightSetting();
                          }
                          _selected = newSelection;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Spacer(),
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.calculator),
                        onPressed: () {
                          setState(() {
                            showModalBottomSheet<dynamic>(
                              context: context,
                              builder: (BuildContext context) {
                                return WeightConfigurator(weightKg.toDouble() +
                                    weightDg.toDouble() / 100.0);
                              },
                            );
                          });
                        },
                      ),
                      NumberPicker(
                        //selectedTextStyle: TextStyle(color: Colors.black),
                        value: weightKg,
                        minValue: -70, maxValue: 250,
                        haptics: true,
                        itemHeight: itemHeight, itemWidth: itemWidth,
                        onChanged: (value) => setState(() => weightKg = value),
                      ),
                      const Text(","),
                      NumberPicker(
                        value: weightDg,
                        minValue: 0,
                        maxValue: 75,
                        step: 25,
                        haptics: true,
                        itemHeight: itemHeight,
                        itemWidth: itemWidth,
                        onChanged: (value) => setState(() => weightDg = value),
                      ),
                      const Text("kg"),
                      const Spacer(),
                      // NumberPicker(
                      //   value: repetitions,
                      //   minValue: 1, maxValue: 30,

                      //   haptics: true,
                      //   itemHeight: itemHeight, itemWidth: itemWidth,
                      //   onChanged: (value) => setState(() => repetitions = value),
                      // ),
                      Container(
                        height: 100,
                        width: 100,
                        child: ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(
                              initialItem: repetitions - 1),
                          itemExtent: 40,
                          physics: const FixedExtentScrollPhysics(),
                          useMagnifier: true,
                          magnification: 1.4,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              repetitions = _values[index];
                              HapticFeedback.selectionClick();
                              // print(_currentValue);
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              final value = _values[index];
                              final color = _colorMap.containsKey(value)
                                  ? _colorMap[value]
                                  : Colors.black;
                              return Center(
                                child: Text(
                                  value.toString(),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 20,
                                      fontFamily: 'Roboto'),
                                ),
                              );
                            },
                            childCount: _values.length,
                          ),
                        ),
                      ),
                      const Text("Reps."),
                      const Spacer(),
                      const Spacer()
                    ])
                  ],
                )),
            ElevatedButton.icon(
                style: const ButtonStyle(),
                label: const Text('Submit'),
                icon: const Icon(Icons.send),
                onPressed: () {
                  double new_weight =
                      weightKg.toDouble() + weightDg.toDouble() / 100.0;
                  // if (_selected.first.index == 0) { numWarmUps -= 1; }
                  // else if (_selected.first.index == 1) { numWorkSets -= 1; }
                  // else { numDropSets -= 1; }
                  addSet(widget.exerciseName, new_weight, repetitions,
                      _selected.first.index, dateInputController.text);
                  updateTexts();
                  updateGraph();
                  _loadTodaysTrainingSets(); // Reload training sets after adding
                  lastActivity = DateTime.now();
                }),
            const Divider(),
            Expanded(
                child: _isLoadingTrainingSets
                    ? const Center(child: CircularProgressIndicator())
                    : _todaysTrainingSets.isNotEmpty
                        ? ListView.builder(
                            controller: _scrollController,
                            itemCount: _todaysTrainingSets.length,
                            itemBuilder: (context, index) {
                              final item = _todaysTrainingSets[index];
                              return ListTile(
                                leading: CircleAvatar(
                                    radius: 17.5,
                                    child: FaIcon(workIcons[item.setType])),
                                dense: true,
                                visualDensity:
                                    const VisualDensity(vertical: -3),
                                title: Text(
                                    "${item.weight}kg for ${item.repetitions} reps"),
                                subtitle: Text(
                                    "${item.date.hour}:${item.date.minute}:${item.date.second}"),
                                trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await _deleteTrainingSet(item);
                                      _loadTodaysTrainingSets(); // Reload after deletion
                                      updateGraph();
                                    }),
                              );
                            })
                        : ListView(
                            controller: _scrollController,
                            children: const [
                              ListTile(title: Text("No Training yet.")),
                            ],
                          )),
            const SizedBox(height: 20),
          ]),
    );
  }
}

class WeightConfigurator extends StatefulWidget {
  const WeightConfigurator(this.weight, {super.key});
  final double weight;
  @override
  State<WeightConfigurator> createState() => _WeightConfigurator();
}

enum ExerciseDevice { dumbbell, barbell20, barbellhome }

class _WeightConfigurator extends State<WeightConfigurator> {
  double itemHeight = 50.0;
  double itemWidth = 30.0;
  ExerciseDevice selectedDevice = ExerciseDevice.dumbbell;
  List<String> leftContainer = [];
  List<String> rightContainer = [];
  late ValueNotifier<List<String>> leftNotifier, rightNotifier;

  List<TextEditingController> kg_controller = [];
  late String weightText;
  late String leftWeight;
  late String midWeight;
  late String rightWeight;

  void updateWeight() {
    setState(() {
      leftContainer.clear();
      rightContainer.clear();
      if (selectedDevice == ExerciseDevice.dumbbell) {
        List<double> matches = globals.mappableWeightsDumb;
        double workWeight = widget.weight;
        workWeight /= 2.0;
        workWeight -= 2.3;
        int bestIndex = 0;
        double bestDistance = 999;
        for (int i = 0; i < matches.length; ++i) {
          if ((matches[i] - workWeight).abs() < bestDistance) {
            bestDistance = (matches[i] - workWeight).abs();
            bestIndex = i;
          }
        }
        // double bestWeight = matches[bestIndex];
        List<double> bestSet = globals.weightCombinationsDumb[bestIndex];
        leftWeight = "";
        rightWeight = "";
        for (int i = 0; i < bestSet.length; i += 2) {
          rightContainer.add(bestSet[i].toString());
        }
        var rights = [];
        for (int i = 1; i < bestSet.length; i += 2) {
          rights.add(bestSet[i]);
        }
        for (var r in rights.reversed) {
          leftContainer.add(r.toString());
        }
        double sum = bestSet.reduce((a, b) => a + b);
        sum += 2.3;
        double all = sum * 2;
        weightText = "Best match: $sum kg ea. ($all)";
      }
      if (selectedDevice == ExerciseDevice.barbellhome) {
        List<double> matches = globals.mappableWeightsBar;
        double workWeight = widget.weight - 8.6;
        workWeight /= 2;
        int bestIndex = 0;
        double bestDistance = 999;
        for (int i = 0; i < matches.length; ++i) {
          if ((matches[i] - workWeight).abs() < bestDistance) {
            bestDistance = (matches[i] - workWeight).abs();
            bestIndex = i;
          }
        }
        // double bestWeight = matches[bestIndex];
        List<double> bestSet = globals.weightCombinationsBar[bestIndex];

        for (int i = 0; i < bestSet.length; ++i) {
          rightContainer.add(bestSet[i].toString());
        }
        for (int i = bestSet.length - 1; i >= 0; --i) {
          leftContainer.add(bestSet[i].toString());
        }
        double sum = bestSet.reduce((a, b) => a + b);
        sum *= 2.0;
        sum += 8.6;
        weightText = "Best match: $sum kg";
      }
    });
  }

  @override
  void initState() {
    super.initState();

    leftNotifier = ValueNotifier(leftContainer);
    rightNotifier = ValueNotifier(rightContainer);
    weightText = "Stacked weight: ${widget.weight} kg";
    updateWeight();
    setState(() {});
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
            ElevatedButton(
              child: const Text('x'),
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
            Text(
              weightText,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20.0),
            SegmentedButton<ExerciseDevice>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<ExerciseDevice>>[
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.dumbbell, label: Text('Dumbbell')),
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.barbellhome,
                      label: Text('Barbell Home')),
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.barbell20,
                      label: Text('Barbell Gym'))
                ],
                selected: <ExerciseDevice>{selectedDevice},
                onSelectionChanged: (Set<ExerciseDevice> newSelection) {
                  setState(() {
                    selectedDevice = newSelection.first;
                    updateWeight();
                  });
                }),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ValueListenableBuilder(
                  valueListenable: rightNotifier,
                  builder: (context, List<String> weights, _) {
                    List<Widget> discs = [];
                    for (var txt in weights) {
                      discs.add(RotatedBox(
                        quarterTurns: 1,
                        child: Container(
                            color: Colors.black45,
                            width: 110 - (10.0 - double.parse(txt)) * 5.0,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(1),
                            child: Text(txt,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10.0))),
                      ));
                    }
                    return Row(children: discs);
                  }),
              Container(
                color: Colors.black54,
                width: 50,
                alignment: Alignment.center,
                child: const Text('bar',
                    style: TextStyle(color: Colors.white, fontSize: 10.0)),
              ),
              // acceptRow2,
              ValueListenableBuilder(
                  valueListenable: leftNotifier,
                  builder: (context, List<String> weights, _) {
                    List<Widget> discs = [];
                    for (var txt in weights) {
                      discs.add(RotatedBox(
                        quarterTurns: 1,
                        child: Container(
                            color: Colors.black45,
                            width: 110 - (10.0 - double.parse(txt)) * 5.0,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(1),
                            child: Text(txt,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10.0))),
                      ));
                    }
                    return Row(children: discs);
                  })
              // child: ValueListenableBuilder(
              //     valueListenable:
              //         Hive.box<TrainingSet>('TrainingSets').listenable(),
              //     builder: (context, Box<TrainingSet> box, _) {
              //       var items = box.values.toList();
              //       if (items.isNotEmpty) {
              //         return ListView.builder(
              //             itemCount: items.length,
              //             itemBuilder: (context, index) {
              //               final item = items[index];
              //               return ListTile(
              //                   leading: CircleAvatar(
              //                       radius: 17.5,
              //                       child: FaIcon(workIcons[item.setType])),
              //                   title: Text(
              //                       "${item.weight}kg for ${item.repetitions} reps"),
              //                   subtitle: Text("${item.date}"),
              //                   trailing: IconButton(
              //                       icon: const Icon(Icons.delete),
              //                       onPressed: () => {
              //                             box.delete(item.key)
              //                           }));
              //             });
              //       } else {
              //         return const Text("None");
              //       }
              //     })
            ]),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
