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

