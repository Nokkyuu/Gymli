import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/exercise_controller.dart';
import '../../../api_models.dart';

/// Widget for displaying the list of training sets
class TrainingSetsListWidget extends StatefulWidget {
  final ExerciseController controller;
  final bool showTitle;

  const TrainingSetsListWidget({
    super.key,
    required this.controller,
    this.showTitle = false,
  });

  @override
  State<TrainingSetsListWidget> createState() => _TrainingSetsListWidgetState();
}

class _TrainingSetsListWidgetState extends State<TrainingSetsListWidget> {
  final ScrollController _scrollController = ScrollController();

  static const List<IconData> workIcons = [
    FontAwesomeIcons.fire,
    FontAwesomeIcons.handFist,
    FontAwesomeIcons.arrowDown,
  ];

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
          const Divider(),
        ],
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (widget.controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (widget.controller.todaysTrainingSets.isEmpty) {
          return ListView(
            controller: _scrollController,
            children: const [
              ListTile(title: Text("No Training yet.")),
            ],
          );
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: widget.controller.todaysTrainingSets.length,
          itemBuilder: (context, index) {
            final trainingSet = widget.controller.todaysTrainingSets[index];
            return _buildTrainingSetItem(trainingSet);
          },
        );
      },
    );
  }

  Widget _buildTrainingSetItem(ApiTrainingSet trainingSet) {
    return ListTile(
      leading: CircleAvatar(
        radius: 17.5,
        child: FaIcon(
          trainingSet.setType < workIcons.length
              ? workIcons[trainingSet.setType]
              : FontAwesomeIcons.question,
        ),
      ),
      dense: true,
      visualDensity: const VisualDensity(vertical: -3),
      title:
          Text("${trainingSet.weight}kg for ${trainingSet.repetitions} reps"),
      subtitle: Text(_formatTime(trainingSet.date)),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _confirmDelete(trainingSet),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}:"
        "${date.second.toString().padLeft(2, '0')}";
  }

  Future<void> _confirmDelete(ApiTrainingSet trainingSet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Training Set'),
          content: Text(
            'Are you sure you want to delete this training set?\n'
            '${trainingSet.weight}kg for ${trainingSet.repetitions} reps',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.deleteTrainingSet(trainingSet);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Training set deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else if (mounted) {
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
}
