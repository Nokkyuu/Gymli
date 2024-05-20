import 'package:flutter/material.dart';

class ExerciseListScreen extends StatelessWidget {
  static List<ListItem> items = [
    DateItem("10.02.2024"),
    ExerciseItem('10 kg for 6 Reps', '11:42:21', Icons.local_fire_department),
    ExerciseItem('15 kg for 10 Reps', '11:45:43', Icons.rowing),
    ExerciseItem('15 kg for 10 Reps', '11:48:02', Icons.rowing),
    ExerciseItem('15 kg for 10 Reps', '11:41:55', Icons.rowing),
    DateItem("08.02.2024"),
    ExerciseItem('10 kg for 6 Reps', '11:42:21', Icons.local_fire_department),
    ExerciseItem('15 kg for 10 Reps', '11:45:43', Icons.rowing),
    ExerciseItem('15 kg for 10 Reps', '11:48:02', Icons.rowing),
    ExerciseItem('15 kg for 10 Reps', '11:41:55', Icons.rowing),
  ];

  const ExerciseListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const title = 'ExercliseList';
    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          leading: InkWell( onTap: () {Navigator.pop(context); },
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.black54,
          ),),
          title: const Text(title),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
          new Expanded(
              child: ListView.builder(
              itemCount: items.length,
              // Provide a builder function. This is where the magic happens.
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  tileColor: item.getColor(context),
                  leading: item.buildIcon(context),
                  title: item.buildTitle(context),
                  subtitle: item.buildSubtitle(context)
                );
              })
            )
          ]
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
  Color getColor(BuildContext context);
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
  Color getColor(BuildContext context) => const Color.fromARGB(255, 196, 104, 104);
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
  @override
  Color getColor(BuildContext context) => Colors.transparent;
}