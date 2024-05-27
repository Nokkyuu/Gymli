// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/DataModels.dart';

final workIcons = [
  FontAwesomeIcons.fire,
  FontAwesomeIcons.handFist,
  FontAwesomeIcons.arrowDown
];

class ExerciseListScreen extends StatelessWidget {
  static String exercise = "Benchpress";
  // static List<ListItem> items = [
  //   DateItem("10.02.2024"),
  //   ExerciseItem('10 kg for 6 Reps', '11:42:21', workIcons.first),
  //   ExerciseItem('15 kg for 10 Reps', '11:45:43', workIcons[1]),
  //   ExerciseItem('15 kg for 10 Reps', '11:48:02', workIcons[1]),
  //   ExerciseItem('15 kg for 10 Reps', '11:41:55', workIcons[1]),
  //   DateItem("08.02.2024"),
  //   ExerciseItem('10 kg for 6 Reps', '11:42:21', workIcons[0]),
  //   ExerciseItem('15 kg for 10 Reps', '11:45:43', workIcons[1]),
  //   ExerciseItem('15 kg for 10 Reps', '11:48:02', workIcons[1]),
  //   ExerciseItem('15 kg for 10 Reps', '11:41:55', workIcons[1]),
  // ];

  const ExerciseListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const title = 'ExerciseList';
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
        title: const Text(title),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
                child: ValueListenableBuilder(
                    valueListenable:
                        Hive.box<TrainingSet>('TrainingSets').listenable(),
                    builder: (context, Box<TrainingSet> box, _) {
                      var items = box.values.toList();
                      items = box.values
                          .where((item) => item.exercise == exercise)
                          .toList()
                          .reversed
                          .toList();
                      if (items.isNotEmpty) {
                        return ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                  leading: CircleAvatar(
                                      radius: 17.5,
                                      child: FaIcon(workIcons[item.setType])),
                                  title: Text(
                                      "${item.weight}kg for ${item.repetitions} reps"),
                                  subtitle: Text("${item.date}"),
                                  trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => {
                                            box.delete(item.key)
                                            // print("Delete funzt nicht.")
                                          }));
                            });
                      } else {
                        return Text("None");
                      }
                    }))
          ]),
    );
  }
}

/// The base class for the different types of items the list can contain.
abstract class ListItem {
  Widget buildTitle(BuildContext context);
  Widget buildSubtitle(BuildContext context);
  Widget buildIcon(BuildContext context);
  Color getColor(BuildContext context);
  Widget buildTrailing(BuildContext context);
}

class DateItem implements ListItem {
  final String exerciseDate;
  DateItem(this.exerciseDate);
  @override
  Widget buildTitle(BuildContext context) => Text(exerciseDate);
  @override
  Widget buildSubtitle(BuildContext context) => const Text("");
  @override
  Widget buildIcon(BuildContext context) => const Text("");
  @override
  Color getColor(BuildContext context) => Theme.of(context).hoverColor;
  @override
  Widget buildTrailing(BuildContext context) => const Text("");
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
        child: FaIcon(
          workIcon,
        ),
      );
  @override
  Color getColor(BuildContext context) => Colors.transparent;
  @override
  Widget buildTrailing(BuildContext context) => IconButton(
      icon: const Icon(Icons.delete), onPressed: () => print("deleted"));
}
