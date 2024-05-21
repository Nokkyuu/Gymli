import 'package:flutter/material.dart';

/// Flutter code sample for [ListTile].

void main() => runApp(const ListTileApp());

class ListTileApp extends StatelessWidget {
  const ListTileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const ListTileExample(),
    );
  }
}

class ListTileExample extends StatefulWidget {
  const ListTileExample({super.key});

  @override
  State<ListTileExample> createState() => _ListTileExampleState();
}

class _ListTileExampleState extends State<ListTileExample> {
  String exerciseName = "Benchpress";
  int warmUpS = 1;
  int workS = 1;
  int dropS = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ListTile Sample')),
      body: Center(
        child: ListTile(
          enabled: true,
          leading: const Icon(Icons.sports_tennis),
          title: Text(exerciseName),
          subtitle: Text('Warm Ups: $warmUpS, Work Sets: $workS, Drop Sets: $dropS'),
          trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed:  () => print("deleted")
                      ),
        ),
      ),
    );
  }
}
