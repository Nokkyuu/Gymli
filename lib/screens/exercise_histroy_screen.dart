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
import '../utils/services/user_service.dart';
import '../utils/api/api_models.dart';

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

class ListEntry {
  final String? header;
  final ApiTrainingSet? set;
  ListEntry.header(this.header) : set = null;
  ListEntry.set(this.set) : header = null;
  bool get isHeader => header != null;
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  List<ListEntry> entries = [];
  final UserService userService = UserService();
  bool _isLoading = true;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadTrainingSets();
  }

  Future<void> _loadTrainingSets() async {
    setState(() => _isLoading = true);
    try {
      final data = await userService.getTrainingSets();
      final trainingSets =
          data.map((item) => ApiTrainingSet.fromJson(item)).toList();
      final filtered = trainingSets
          .where((item) => item.exerciseName == widget.exercise)
          .toList();
      filtered.sort((a, b) => b.date.compareTo(a.date));

      // Build entries with headers
      List<ListEntry> newEntries = [];
      String? lastDate;
      for (final set in filtered) {
        final dateStr = set.date.toString().split(" ")[0];
        if (lastDate != dateStr) {
          newEntries.add(ListEntry.header(dateStr));
          lastDate = dateStr;
        }
        newEntries.add(ListEntry.set(set));
      }

      setState(() {
        entries = [];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < newEntries.length; i++) {
          entries.add(newEntries[i]);
          _listKey.currentState?.insertItem(i);
        }
        setState(() => _isLoading = false);
      });
    } catch (e) {
      print('Error loading training sets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading training sets: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> delete(ApiTrainingSet item) async {
    if (item.id == null) return;
    try {
      // Find the index of the set entry
      int setIndex = entries.indexWhere((e) => e.set?.id == item.id);
      if (setIndex == -1) return;

      // Check if header should also be removed
      bool removeHeader = false;
      if (setIndex > 0 && entries[setIndex - 1].isHeader) {
        // If this is the only set under the header, remove header too
        bool isLastSetForHeader =
            (setIndex + 1 >= entries.length) || entries[setIndex + 1].isHeader;
        if (isLastSetForHeader) removeHeader = true;
      }

      await userService.deleteTrainingSet(item.id!);

      setState(() {
        if (removeHeader) {
          _listKey.currentState?.removeItem(
            setIndex - 1,
            (context, animation) =>
                _buildListEntry(entries[setIndex - 1], animation),
          );
          entries.removeAt(setIndex - 1);
          setIndex -= 1;
        }
        _listKey.currentState?.removeItem(
          setIndex,
          (context, animation) => _buildListEntry(entries[setIndex], animation),
        );
        entries.removeAt(setIndex);
      });
    } catch (e) {
      print('Error deleting training set: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting training set: $e')),
        );
      }
    }
  }

  Widget _buildListEntry(ListEntry entry, Animation<double> animation) {
    if (entry.isHeader) {
      return SizeTransition(
        sizeFactor: animation,
        child: Container(
          color: Theme.of(context).colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            entry.header!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    } else {
      final item = entry.set!;
      return SizeTransition(
        sizeFactor: animation,
        child: ListTile(
          leading: CircleAvatar(
              radius: 17.5, child: FaIcon(workIcons[item.setType])),
          title: Text("${item.weight}kg for ${item.repetitions} reps"),
          subtitle: Text("${item.date}"),
          trailing: IconButton(
              icon: const Icon(Icons.delete), onPressed: () => delete(item)),
        ),
      );
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
          : AnimatedList(
              key: _listKey,
              initialItemCount: entries.length,
              itemBuilder: (context, index, animation) {
                return _buildListEntry(entries[index], animation);
              },
            ),
    );
  }
}
