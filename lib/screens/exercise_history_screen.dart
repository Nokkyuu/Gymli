///Screen to display the history of training sets.
///Screen is accessed from the ExerciseScreen and shows all sets for a specific exercise.
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Gymli/utils/themes/themes.dart' show setIcons;
import '../utils/api/api_models.dart';
import 'exercise/repositories/exercise_repository.dart';
import 'exercise_history/controller/history_list_controller.dart';

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
  late final HistoryListController controller;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<ListEntry> _oldEntries = [];

  @override
  void initState() {
    super.initState();
    controller = HistoryListController(
      exercise: widget.exercise,
      exerciseRepository: widget.exerciseRepository,
    );
    controller.loadTrainingSets();
    controller.entries.addListener(_onEntriesChanged);
  }

  @override
  void dispose() {
    controller.entries.removeListener(_onEntriesChanged);
    super.dispose();
  }

  void _onEntriesChanged() {
    final newEntries = controller.entries.value;
    // AnimatedList synchronisieren (nur einfache Variante: alles neu laden)
    if (_listKey.currentState != null) {
      final diff = _oldEntries.length - newEntries.length;
      if (diff > 0) {
        for (int i = 0; i < diff; i++) {
          _listKey.currentState!.removeItem(
            0,
            (context, animation) => const SizedBox.shrink(),
          );
        }
      }
      if (diff < 0) {
        for (int i = 0; i < -diff; i++) {
          _listKey.currentState!.insertItem(_oldEntries.length + i);
        }
      }
    }
    _oldEntries = List.from(newEntries);
    setState(() {});
  }

  void _delete(ApiTrainingSet item) async {
    await controller.delete(item);
    if (widget.onSetDeleted != null) {
      widget.onSetDeleted!();
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
              icon: const Icon(Icons.delete), onPressed: () => _delete(item)),
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
      body: ValueListenableBuilder<bool>(
        valueListenable: controller.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return AnimatedList(
            key: _listKey,
            initialItemCount: controller.entries.value.length,
            itemBuilder: (context, index, animation) {
              return _buildListEntry(
                  controller.entries.value[index], animation);
            },
          );
        },
      ),
    );
  }
}
