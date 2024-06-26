// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Gymli/DataModels.dart';

final workIcons = [
  FontAwesomeIcons.fire,
  FontAwesomeIcons.handFist,
  FontAwesomeIcons.arrowDown
];

class ExerciseListScreen extends StatefulWidget {
  final String exercise;
  const ExerciseListScreen(this.exercise, {super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  late ValueNotifier<bool> exerciseNotifier;
  bool updated = false;
  List<TrainingSet> items = [];
  late Box<TrainingSet> box;
  @override
  void initState() {
    super.initState();
    box = Hive.box<TrainingSet>("TrainingSets");
    items = box.values.toList().where((item) => item.exercise == widget.exercise).toList().reversed.toList();
    exerciseNotifier = ValueNotifier(updated);
  }

  void delete(TrainingSet item) async {
    await box.delete(item.key).then((futureValue) {
      setState(() {
        items = box.values.toList().where((item) => item.exercise == widget.exercise).toList().reversed.toList();
        updated = !updated;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () { Navigator.pop(context); },
          child: const Icon(Icons.arrow_back_ios),
        ),
        title: Text('Set Archive ${widget.exercise}'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[Expanded(
          child:
          ValueListenableBuilder(
            valueListenable: exerciseNotifier,
            builder: (context, bool updated, _) {
              List<Widget> widgets = [];
              String lastDate = "";
              for (int i = 0; i < items.length; ++i) {
                var item = items[i];
                String currentDate = item.date.toString().split(" ")[0];
                if (lastDate != currentDate) {
                  widgets.add(ListTile(title: Text(currentDate), tileColor: Theme.of(context).colorScheme.onSecondary));
                  lastDate = currentDate;
                }
                widgets.add(ListTile(
                    leading: CircleAvatar(radius: 17.5, child: FaIcon(workIcons[item.setType])),
                    title: Text("${item.weight}kg for ${item.repetitions} reps"),
                    subtitle: Text("${item.date}"),
                    trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => { delete(item) })
                ));
              }
              return ListView(children: widgets);
            }
          )
        )
      ]),
    );
  }
}

