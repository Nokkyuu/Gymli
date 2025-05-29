/// Exercise List Screen - Training History Display
///
/// This screen displays the complete training history for a specific exercise,
/// showing all past training sets with performance metrics and visual indicators.
///
/// Features:
/// - Chronological list of all training sets for an exercise
/// - Visual workout intensity indicators using FontAwesome icons
/// - Performance metrics display (weight, reps, calculated 1RM)
/// - Loading states and error handling
/// - Interactive list with detailed training set information
///
/// The screen helps users track their progress over time for individual
/// exercises and analyze their training patterns and improvements.
library;

// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'user_service.dart';
import 'api_models.dart';

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
  List<ApiTrainingSet> items = [];
  final UserService userService = UserService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainingSets();
  }

  Future<void> _loadTrainingSets() async {
    setState(() => _isLoading = true);

    try {
      final data = await userService.getTrainingSets();
      print('ExerciseListScreen - Total training sets: ${data.length}');
      print('ExerciseListScreen - Looking for exercise: "${widget.exercise}"');

      final trainingSets =
          data.map((item) => ApiTrainingSet.fromJson(item)).toList();

      // Debug: Print all exercise names
      for (var item in trainingSets) {
        print('ExerciseListScreen - Found exercise: "${item.exerciseName}"');
      }

      items = trainingSets
          .where((item) => item.exerciseName == widget.exercise)
          .toList();

      // Sort by date in descending order (newest first)
      items.sort((a, b) => b.date.compareTo(a.date));

      print('ExerciseListScreen - Filtered training sets: ${items.length}');
    } catch (e) {
      print('Error loading training sets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading training sets: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> delete(ApiTrainingSet item) async {
    if (item.id == null) return;

    try {
      await userService.deleteTrainingSet(item.id!);
      await _loadTrainingSets();
    } catch (e) {
      print('Error deleting training set: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting training set: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
        title: Text('Set Archive ${widget.exercise}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[Expanded(child: _buildTrainingSetsList())],
            ),
    );
  }

  Widget _buildTrainingSetsList() {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No training sets found for this exercise',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    List<Widget> widgets = [];
    String lastDate = "";

    for (int i = 0; i < items.length; ++i) {
      var item = items[i];
      String currentDate = item.date.toString().split(" ")[0];

      if (lastDate != currentDate) {
        widgets.add(ListTile(
            title: Text(currentDate),
            tileColor: Theme.of(context).colorScheme.onSecondary));
        lastDate = currentDate;
      }

      widgets.add(ListTile(
          leading: CircleAvatar(
              radius: 17.5, child: FaIcon(workIcons[item.setType])),
          title: Text("${item.weight}kg for ${item.repetitions} reps"),
          subtitle: Text("${item.date}"),
          trailing: IconButton(
              icon: const Icon(Icons.delete), onPressed: () => delete(item))));
    }

    return ListView(children: widgets);
  }
}
