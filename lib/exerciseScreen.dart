import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class ExerciseScreen extends StatelessWidget {
  static List<ListItem> items = [
          ExerciseItem('Deadlift', '15 kg'),
          ExerciseItem('Benchpress', '12 kg'),
        ];

  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Exercise';
    final points = [(10, 1), (20, 1)];
    TextEditingController _weightController = TextEditingController(text: '15');
    TextEditingController _repetitionController = TextEditingController(text: '10');


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
                  leading: CircleAvatar(radius: 17.5,backgroundColor: Colors.cyan,child: const Icon(Icons.timer_outlined, color: Colors.white,),),
                  title: item.buildTitle(context),
                  subtitle: 
                        Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                  item.buildSubtitle(context),
                  Text(" 12847 reps")
                  ])
                );
              })
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                const Text("20.Mai 11:23"),
                const Text("Kg "),
                const Text("Reps")
            ]),
            Row(
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
                  child: Text('Submit'),
                ),
            ]),
            ]
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
}
// add new button?
class ExerciseItem implements ListItem {
  final String exerciseName;
  final String meta;

  ExerciseItem(this.exerciseName, this.meta);
  @override
  Widget buildTitle(BuildContext context) => Text(exerciseName);

  @override
  Widget buildSubtitle(BuildContext context) => Text(meta);
}