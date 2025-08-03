///Screen to display the history of training sets.
///Screen is accessed from the ExerciseScreen and shows all sets for a specific exercise.
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Gymli/utils/services/service_container.dart';
import 'package:Gymli/utils/themes/themes.dart' show setIcons;
import '../utils/api/api_models.dart';
import 'exercise/repositories/exercise_repository.dart';

final _setTypeIcons = setIcons;

class ExerciseListScreen extends StatefulWidget {
  final String exercise;
  final VoidCallback? onSetDeleted;
  final ExerciseRepository? exerciseRepository;

  const ExerciseListScreen(
    this.exercise, {
    super.key,
    this.onSetDeleted,
    this.exerciseRepository,
  });

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
  final ServiceContainer container = ServiceContainer();
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
      final data = await container.trainingSetService.getTrainingSets();
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
      int headerIndex = -1;
      if (setIndex > 0 && entries[setIndex - 1].isHeader) {
        // If this is the only set under the header, remove header too
        bool isLastSetForHeader =
            (setIndex + 1 >= entries.length) || entries[setIndex + 1].isHeader;
        if (isLastSetForHeader) {
          removeHeader = true;
          headerIndex = setIndex - 1;
        }
      }

      // Delete from backend first
      await container.trainingSetService.deleteTrainingSet(item.id!);

      // Force refresh the exercise repository cache to ensure consistency
      // Use the passed repository instance if available
      try {
        if (widget.exerciseRepository != null) {
          await widget.exerciseRepository!.refreshCache();
        } else {
          final exerciseRepo = ExerciseRepository();
          await exerciseRepo.refreshCache();
        }
      } catch (e) {
        print('Warning: Could not refresh exercise repository cache: $e');
      }

      setState(() {
        // Remove items in correct order (set first, then header if needed)
        // This prevents negative index issues

        // Remove the set entry
        if (setIndex >= 0 && setIndex < entries.length) {
          _listKey.currentState?.removeItem(
            setIndex,
            (context, animation) =>
                _buildListEntry(entries[setIndex], animation),
          );
          entries.removeAt(setIndex);
        }

        // Remove header if needed (after set removal, headerIndex is now setIndex - 1)
        if (removeHeader && headerIndex >= 0 && headerIndex < entries.length) {
          _listKey.currentState?.removeItem(
            headerIndex,
            (context, animation) =>
                _buildListEntry(entries[headerIndex], animation),
          );
          entries.removeAt(headerIndex);
        }

        if (widget.onSetDeleted != null) {
          widget.onSetDeleted!();
        }
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
              radius: 17.5, child: FaIcon(_setTypeIcons[item.setType])),
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
