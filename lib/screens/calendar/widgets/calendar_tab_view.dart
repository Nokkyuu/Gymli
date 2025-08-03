import 'package:flutter/material.dart';
import '../controllers/calendar_controller.dart';

/// A widget that displays the bottom tab view with three tabs:
/// - Notes: List of all calendar notes
/// - Workouts: List of all calendar workouts
/// - Periods: List of all calendar periods
class CalendarTabView extends StatelessWidget {
  final CalendarController controller;

  const CalendarTabView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Expanded(
        child: Column(
          children: [
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.note), text: 'Notes'),
                Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
                Tab(icon: Icon(Icons.timeline), text: 'Periods'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNotesTab(),
                  _buildWorkoutsTab(),
                  _buildPeriodsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    return controller.notes.isNotEmpty
        ? ListView(
            children:
                (controller.notesList..sort((a, b) => b.date.compareTo(a.date)))
                    .map((note) => ListTile(
                          leading: const Icon(Icons.note),
                          title: Text('${note.date.toLocal()}'.split(' ')[0]),
                          subtitle: Text(note.note),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await controller.deleteNote(note);
                            },
                          ),
                        ))
                    .toList(),
          )
        : const Center(child: Text('No notes yet.'));
  }

  Widget _buildWorkoutsTab() {
    return controller.calendarWorkouts.isNotEmpty
        ? ListView(
            children: (controller.calendarWorkouts.toList()
                  ..sort((a, b) => b.date.compareTo(a.date)))
                .map((w) => ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(w.workoutName),
                      subtitle: Text('${w.date.toLocal()}'.split(' ')[0]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          controller.deleteWorkout(w);
                        },
                      ),
                    ))
                .toList(),
          )
        : const Center(child: Text('No workouts yet.'));
  }

  Widget _buildPeriodsTab() {
    return controller.periods.isNotEmpty
        ? ListView(
            children: (controller.periods.toList()
                  ..sort((a, b) => b.start.compareTo(a.start)))
                .map((p) => ListTile(
                      leading: const Icon(Icons.timeline),
                      title: Text('${p.type.displayName} period'),
                      subtitle: Text('${p.start.toLocal()} - ${p.end.toLocal()}'
                          .replaceAll(' 00:00:00.000', '')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          controller.deletePeriod(p);
                        },
                      ),
                    ))
                .toList(),
          )
        : const Center(child: Text('No periods yet.'));
  }
}
