import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ExerciseType { warmup, work, dropset }

class ExerciseScreen extends StatelessWidget {
  static List<ListItem> items = [
          ExerciseItem('10 kg for 6 Reps', '11:42:21', Icons.local_fire_department),
          ExerciseItem('15 kg for 10 Reps', '11:45:43', Icons.rowing),
          ExerciseItem('15 kg for 10 Reps', '11:48:02', Icons.rowing),
          ExerciseItem('15 kg for 10 Reps', '11:41:55', Icons.rowing),
        ];

  const ExerciseScreen({super.key});
  

  @override
  Widget build(BuildContext context) {
    const title = 'Exercise';
    final points = [(10, 1), (20, 1)];
    TextEditingController _weightController = TextEditingController(text: '15');
    TextEditingController _repetitionController = TextEditingController(text: '10');
    TextEditingController _dateInputController = TextEditingController(text: '20.05.2024 11:42');


    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
              width: 500, 
              height: 130,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                    spots: const [ FlSpot(0, 5), FlSpot(1, 10), FlSpot(2, 8), FlSpot(3, 11), FlSpot(4, 12)]
                  ),
                ],
              )
            )
            ),
          new Expanded(
              child: ListView.builder(
              itemCount: items.length,
              // Provide a builder function. This is where the magic happens.
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  // leading: CircleAvatar(radius: 17.5,backgroundColor: Colors.cyan,child: const Icon(Icons.local_fire_department, color: Colors.white,),),
                  leading: item.buildIcon(context),
                  title: item.buildTitle(context),
                  subtitle: 
                      item.buildSubtitle(context)
                );
              })
            ),
            SegmentedButton<ExerciseType>(
              segments: const <ButtonSegment<ExerciseType>>[
                ButtonSegment<ExerciseType>(
                    value: ExerciseType.warmup,
                    label: Text('Warmup'),
                    icon: Icon(Icons.local_fire_department)
                    ),
                ButtonSegment<ExerciseType>(
                    value: ExerciseType.work,
                    label: Text('Work'),
                    icon: Icon(Icons.rowing)
                    ),
                ButtonSegment<ExerciseType>(
                    value: ExerciseType.dropset,
                    label: Text('Dropset'),
                    icon: Icon(Icons.south_east)
                    ),
              ],
              selected: <ExerciseType>{ExerciseType.warmup},
            ),
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 50),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _dateInputController,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                )
            ]),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 50, bottom: 10),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'kg',),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _repetitionController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'reps',),
                  ),
                ),
                TextButton(
                  style: ButtonStyle(),
                  onPressed: () { },
                  child: const Text('Submit'),
                ),
              ])
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50)
          ),]
          //               Row(
          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          // mainAxisSize: MainAxisSize.max,
          // children: <Widget>[
          // TextButton(
          //   style: ButtonStyle(
          //   ),
          //   onPressed: () { },
          //   child: Text('Training Stoppen'),
          // ),
          // const Text("Dauer 00:41:32 ")
          // ]),

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
}