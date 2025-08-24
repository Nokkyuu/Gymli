import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/exercise_controller.dart';
import '../../../utils/models/data_models.dart';
import 'package:Gymli/utils/themes/themes.dart' show setIcons;
import 'package:get_it/get_it.dart';
import '../../../utils/workout_data_cache.dart';

/// Widget for displaying the list of training sets
class TrainingSetsListWidget extends StatefulWidget {
  final ExerciseController controller;
  final bool showTitle;

  final List<TrainingSet> lastSessionSets;

  const TrainingSetsListWidget({
    super.key,
    required this.controller,
    this.showTitle = false,
    this.lastSessionSets = const [],
  });

  @override
  State<TrainingSetsListWidget> createState() => _TrainingSetsListWidgetState();
}

class _TrainingSetsListWidgetState extends State<TrainingSetsListWidget> {
  final ScrollController _scrollController = ScrollController();

  static const List<IconData> _SetTypeIcons = setIcons;
  WorkoutDataCache get _cache => GetIt.I<WorkoutDataCache>();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showTitle) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Today's Training Sets",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        const Divider(),
        Expanded(child: _buildList()),
        const Divider(),
      ],
    );
  }

  Widget _buildList() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final today = widget.controller.todaysTrainingSets;
        final last = widget.lastSessionSets;

        final todayWarmups = today.where((s) => s.setType == 0).toList();
        final todayWork = today.where((s) => s.setType > 0).toList();
        final lastWork = last.where((s) => s.setType > 0).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        final ghostSets = <TrainingSet>[];
        for (int i = 0; i < lastWork.length; i++) {
          if (i >= todayWork.length) {
            ghostSets.add(lastWork[i]);
          }
        }

        final combined = [...todayWarmups, ...ghostSets, ...todayWork];

        return widget.controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                itemCount: combined.length,
                itemBuilder: (context, index) {
                  final set = combined[index];
                  final isGhost = ghostSets.contains(set);
                  return _buildTrainingSetItem(set, isGhost);
                },
              );
      },
    );
  }

  Widget _buildTrainingSetItem(TrainingSet trainingSet, [bool isGhost = false]) {
    return Opacity(
      opacity: isGhost ? 0.4 : 1.0,
      child: ListTile(
        leading: CircleAvatar(
          radius: 17.5,
          backgroundColor: isGhost ? Colors.grey.shade300 : null,
          child: isGhost
              ? const Icon(Icons.history, size: 18, color: Colors.black45)
              : FaIcon(
                  trainingSet.setType < _SetTypeIcons.length
                      ? _SetTypeIcons[trainingSet.setType]
                      : FontAwesomeIcons.question,
                ),
        ),
        dense: true,
        visualDensity: const VisualDensity(vertical: -3),
        title: Text("${trainingSet.weight}kg for ${trainingSet.repetitions} reps"),
        subtitle: Text(
          isGhost
              ? "${_formatTime(trainingSet.date)} @ ${_daysAgo(trainingSet.date)}"
              : _formatTime(trainingSet.date),
        ),
        trailing: isGhost
            ? null
            : IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(trainingSet),
              ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}:"
        "${date.second.toString().padLeft(2, '0')}";
  }

  Future<void> _confirmDelete(TrainingSet trainingSet) async {
    final success = await widget.controller.deleteTrainingSet(trainingSet);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Training set deleted'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await widget.controller.addTrainingSet(
                widget.controller.currentExercise?.name ?? '',
                trainingSet.weight,
                trainingSet.repetitions,
                trainingSet.setType,
                trainingSet.date.toIso8601String(),
                trainingSet.phase,
                trainingSet.myoreps,
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage ??
              'Failed to delete training set'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

  String _daysAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    return diff == 0
        ? "today"
        : diff == 1
            ? "1 day ago"
            : "$diff days ago";
  }