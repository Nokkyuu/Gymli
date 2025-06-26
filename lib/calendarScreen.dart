import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class _Period {
  final String type; // 'cut', 'bulk', 'other'
  final DateTime start;
  final DateTime end;
  _Period(this.type, this.start, this.end);
}

class _CalendarWorkout {
  final DateTime date;
  final String workoutName;
  _CalendarWorkout(this.date, this.workoutName);
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, String> _notes = {};
  final List<_Period> _periods = [];
  final List<_CalendarWorkout> _calendarWorkouts = [];

  // Dummy workout list for demonstration
  final List<String> _workouts = [
    'Push Day',
    'Pull Day',
    'Leg Day',
    'Full Body',
    'Cardio'
  ];

  // Helper to normalize dates (remove time part)
  DateTime _normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Color? _periodColor(String type) {
    switch (type) {
      case 'cut':
        return Color.fromARGB(217, 33, 149, 243);
      case 'bulk':
        return Colors.green.withOpacity(0.2);
      default:
        return Colors.orange.withOpacity(0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar & Notes')),
      body: Column(
        children: [
          TableCalendar(
            headerVisible: false,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) =>
                _selectedDay != null &&
                _normalize(day) == _normalize(_selectedDay!),
            onDayLongPressed: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showDayActionDialog(selectedDay);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              // _showDayActionDialog(selectedDay);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final normalized = _normalize(day);
                final hasNote = _notes.containsKey(normalized);
                final hasWorkout = _calendarWorkouts
                    .any((w) => _normalize(w.date) == normalized);
                final period = _periods.firstWhere(
                  (p) =>
                      !normalized.isBefore(p.start) &&
                      !normalized.isAfter(p.end),
                  orElse: () => _Period('', DateTime(1900), DateTime(1900)),
                );
                final inPeriod = period.type.isNotEmpty;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: inPeriod ? _periodColor(period.type) : null,
                        shape: BoxShape.rectangle,
                      ),
                      alignment: Alignment.center,
                      child: Text('${day.day}'),
                    ),
                    if (hasNote)
                      Positioned(
                        bottom: 4,
                        left: 8,
                        child: Icon(Icons.note, size: 14, color: Colors.blue),
                      ),
                    if (hasWorkout)
                      Positioned(
                        bottom: 4,
                        right: 8,
                        child: Icon(Icons.fitness_center,
                            size: 14, color: Colors.deepPurple),
                      ),
                  ],
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                final normalized = _normalize(day);
                final hasNote = _notes.containsKey(normalized);
                final hasWorkout = _calendarWorkouts
                    .any((w) => _normalize(w.date) == normalized);
                final period = _periods.firstWhere(
                  (p) =>
                      !normalized.isBefore(p.start) &&
                      !normalized.isAfter(p.end),
                  orElse: () => _Period('', DateTime(1900), DateTime(1900)),
                );
                final inPeriod = period.type.isNotEmpty;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary, // <-- your selected day color
                        shape: BoxShape.rectangle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (hasNote)
                      Positioned(
                        bottom: 4,
                        left: 8,
                        child: Icon(Icons.note, size: 14, color: Colors.blue),
                      ),
                    if (hasWorkout)
                      Positioned(
                        bottom: 4,
                        right: 8,
                        child: Icon(Icons.fitness_center,
                            size: 14, color: Colors.white),
                      ),
                  ],
                );
              },
              todayBuilder: (context, day, focusedDay) {
                // Customize the appearance of the current day
                return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface, // <-- your custom color for today
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .primary, // <-- text color),
                      ),
                    ));
              },
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                _legendDot(_periodColor('cut')!),
                const Text('Cut  '),
                _legendDot(_periodColor('bulk')!),
                const Text('Bulk  '),
                _legendDot(_periodColor('other')!),
                const Text('Other  '),
                Icon(Icons.note, size: 16, color: Colors.blue),
                const Text(' Note  '),
                Icon(Icons.fitness_center, size: 16, color: Colors.deepPurple),
                const Text(' Workout'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.timeline),
            label: const Text('Add Time Period'),
            onPressed: _showAddPeriodDialog,
          ),
          const Divider(),
          // Day details
          if (_selectedDay != null) _buildDayDetails(_normalize(_selectedDay!)),
          Expanded(
            child: ListView(
              children: [
                if (_notes.isNotEmpty)
                  ..._notes.entries.map((e) => ListTile(
                        leading: const Icon(Icons.note),
                        title: Text('${e.key.toLocal()}'.split(' ')[0]),
                        subtitle: Text(e.value),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _notes.remove(e.key);
                            });
                          },
                        ),
                      )),
                if (_calendarWorkouts.isNotEmpty)
                  ..._calendarWorkouts.map((w) => ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text('${w.workoutName}'),
                        subtitle: Text('${w.date.toLocal()}'.split(' ')[0]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _calendarWorkouts.remove(w);
                            });
                          },
                        ),
                      )),
                if (_periods.isNotEmpty)
                  ..._periods.map((p) => ListTile(
                        leading: const Icon(Icons.timeline),
                        title: Text(
                            '${p.type[0].toUpperCase()}${p.type.substring(1)} period'),
                        subtitle: Text(
                            '${p.start.toLocal()} - ${p.end.toLocal()}'
                                .replaceAll(' 00:00:00.000', '')),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _periods.remove(p);
                            });
                          },
                        ),
                      )),
                if (_notes.isEmpty &&
                    _periods.isEmpty &&
                    _calendarWorkouts.isEmpty)
                  const ListTile(
                      title: Text('No notes, workouts, or periods yet.')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.rectangle,
      ),
    );
  }

  Widget _buildDayDetails(DateTime day) {
    final note = _notes[day];
    final workouts = _calendarWorkouts
        .where((w) => _normalize(w.date) == day)
        .map((w) => w.workoutName)
        .toList();
    if (note == null && workouts.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details for ${day.toLocal()}'.split(' ')[0],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (note != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(child: Text(note)),
                ],
              ),
            ],
            if (workouts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.fitness_center,
                      size: 16, color: Colors.deepPurple),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Workouts: ${workouts.join(', ')}')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDayActionDialog(DateTime date) {
    final normalized = _normalize(date);
    final noteController =
        TextEditingController(text: _notes[normalized] ?? '');
    String? selectedWorkout;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Day Actions (${normalized.toLocal()}'.split(' ')[0] + ')'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(hintText: 'Enter note...'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: null,
              hint: const Text('Assign workout'),
              items: _workouts
                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: (val) {
                selectedWorkout = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (noteController.text.trim().isEmpty) {
                  _notes.remove(normalized);
                } else {
                  _notes[normalized] = noteController.text.trim();
                }
                if (selectedWorkout != null) {
                  _calendarWorkouts
                      .add(_CalendarWorkout(normalized, selectedWorkout!));
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddPeriodDialog() {
    DateTime? start;
    DateTime? end;
    String? type;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Time Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                hint: const Text('Select type'),
                items: [
                  DropdownMenuItem(value: 'cut', child: Text('Cut')),
                  DropdownMenuItem(value: 'bulk', child: Text('Bulk')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) => setStateDialog(() => type = val),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Start:'),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: start ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setStateDialog(() => start = picked);
                    },
                    child: Text(start == null
                        ? 'Select'
                        : '${start!.toLocal()}'.split(' ')[0]),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('End:'),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: end ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setStateDialog(() => end = picked);
                    },
                    child: Text(end == null
                        ? 'Select'
                        : '${end!.toLocal()}'.split(' ')[0]),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (type != null &&
                    start != null &&
                    end != null &&
                    !end!.isBefore(start!)) {
                  setState(() {
                    _periods.add(_Period(type!, start!, end!));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
