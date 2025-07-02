import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'user_service.dart';

//TODO: Changing the API to return IDs when adding items, so that there is no need for constant reloads

class _Period {
  final int? id;
  final String type; // 'cut', 'bulk', 'other'
  final DateTime start;
  final DateTime end;
  _Period(this.type, this.start, this.end, {this.id});
}

class _CalendarWorkout {
  final int? id;
  final DateTime date;
  final String workoutName;
  _CalendarWorkout(this.date, this.workoutName, {this.id});
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, Map<String, dynamic>> _notes =
      {}; // Store both note and id
  final List<_Period> _periods = [];
  final List<_CalendarWorkout> _calendarWorkouts = [];

  // Dummy workout list for demonstration
  // final List<String> _workouts = [
  //   'Push Day',
  //   'Pull Day',
  //   'Leg Day',
  //   'Full Body',
  //   'Cardio'
  // ];
  List<String> _workoutNames = [];
  final userService = UserService();
  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _loadCalendarNotes();
    _loadCalendarWorkouts();
    _loadPeriods();
  }

  Future<void> _loadWorkouts() async {
    final workouts = await userService.getWorkouts();
    setState(() {
      _workoutNames = workouts.map<String>((w) => w['name'] as String).toList();
    });
  }

  Future<void> _loadCalendarNotes() async {
    final notes = await userService.getCalendarNotes();
    setState(() {
      _notes.clear();
      for (var n in notes) {
        final date = DateTime.parse(n['date']);
        _notes[_normalize(date)] = {
          'note': n['note'] as String,
          'id': n['id'],
        };
      }
    });
  }

  Future<void> _loadCalendarWorkouts() async {
    final workouts = await userService.getCalendarWorkouts();
    setState(() {
      _calendarWorkouts.clear();
      for (var w in workouts) {
        final date = DateTime.parse(w['date']);
        _calendarWorkouts.add(_CalendarWorkout(
          _normalize(date),
          w['workout'],
          id: w['id'],
        ));
      }
    });
  }

  Future<void> _loadPeriods() async {
    final periods = await userService.getPeriods();
    setState(() {
      _periods.clear();
      for (var p in periods) {
        _periods.add(_Period(
          p['type'],
          DateTime.parse(p['start_date']),
          DateTime.parse(p['end_date']),
          id: p['id'],
        ));
      }
    });
  }

  void _saveNote(DateTime date, String? note) async {
    final existingNote = _notes[date];

    if (note == null || note.trim().isEmpty) {
      // Delete note
      if (existingNote != null) {
        await userService.deleteCalendarNote(existingNote['id']);
      }
      setState(() {
        _notes.remove(date);
      });
    } else {
      if (existingNote != null) {
        // Update existing note
        await userService.updateCalendarNote(existingNote['id'],
            note: note, date: date);
        setState(() {
          _notes[date] = {'note': note, 'id': existingNote['id']};
        });
      } else {
        // Create new note
        await userService.createCalendarNote(date: date, note: note);
        await _loadCalendarNotes();
      }
    }
  }

  void _addWorkout(DateTime date, String workoutName) async {
    try {
      await userService.createCalendarWorkout(date: date, workout: workoutName);
      await _loadCalendarWorkouts();
    } catch (e) {
      print('Error adding workout: $e'); // Debug log
    }
  }

  void _addPeriod(String type, DateTime start, DateTime end) async {
    try {
      print('Adding period: $type from $start to $end'); // Debug log
      await userService.createPeriod(
          type: type, startDate: start, endDate: end);

      await _loadPeriods();
    } catch (e) {
      print('Error adding period: $e'); // Debug log
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add period: $e')),
      );
    }
  }

  void _deleteWorkout(_CalendarWorkout workout) async {
    if (workout.id != null) {
      await userService.deleteCalendarWorkout(workout.id!);
    }
    setState(() {
      _calendarWorkouts.remove(workout);
    });
  }

  void _deletePeriod(_Period period) async {
    if (period.id != null) {
      await userService.deletePeriod(period.id!);
    }
    setState(() {
      _periods.remove(period);
    });
  }

  // Helper to normalize dates (remove time part)
  DateTime _normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Color? _periodColor(String type) {
    switch (type) {
      case 'cut':
        return Color.fromARGB(105, 255, 66, 28);
      case 'bulk':
        return const Color.fromARGB(143, 76, 175, 79).withOpacity(0.2);
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
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
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
                return GestureDetector(
                  onSecondaryTapDown: (details) async {
                    setState(() {
                      _selectedDay = day;
                      _focusedDay = day;
                    });
                    // Right-click (desktop) or long-press (mobile)
                    await _showDayPopupMenu(
                        context, day, details.globalPosition);
                  },
                  onLongPress: () async {
                    setState(() {
                      _selectedDay = day;
                      _focusedDay = day;
                    });
                    // Long-press (mobile)
                    final box = context.findRenderObject() as RenderBox;
                    final position = box.localToGlobal(Offset.zero);
                    await _showDayPopupMenu(context, day, position);
                  },
                  child: Stack(
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
                  ),
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
                return GestureDetector(
                  onSecondaryTapDown: (details) async {
                    await _showDayPopupMenu(
                        context, day, details.globalPosition);
                  },
                  onLongPress: () async {
                    final box = context.findRenderObject() as RenderBox;
                    final position = box.localToGlobal(Offset.zero);
                    await _showDayPopupMenu(context, day, position);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
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
                          child:
                              Icon(Icons.note, size: 14, color: Colors.black),
                        ),
                      if (hasWorkout)
                        Positioned(
                          bottom: 4,
                          right: 8,
                          child: Icon(Icons.fitness_center,
                              size: 14, color: Colors.white),
                        ),
                    ],
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
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
                return GestureDetector(
                  onSecondaryTapDown: (details) async {
                    setState(() {
                      _selectedDay = day;
                      _focusedDay = day;
                    });
                    // Right-click (desktop) or long-press (mobile)
                    await _showDayPopupMenu(
                        context, day, details.globalPosition);
                  },
                  onLongPress: () async {
                    setState(() {
                      _selectedDay = day;
                      _focusedDay = day;
                    });
                    // Long-press (mobile)
                    final box = context.findRenderObject() as RenderBox;
                    final position = box.localToGlobal(Offset.zero);
                    await _showDayPopupMenu(context, day, position);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: inPeriod ? _periodColor(period.type) : null,
                          shape: BoxShape.rectangle,
                        ),
                        alignment: Alignment.center,
                        child: Text('${day.day}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            )),
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
                  ),
                );
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
          const Divider(),
          if (_selectedDay != null) _buildDayDetails(_normalize(_selectedDay!)),
          Expanded(
            child: ListView(
              children: [
                if (_notes.isNotEmpty)
                  ..._notes.entries.map((e) => ListTile(
                        leading: const Icon(Icons.note),
                        title: Text('${e.key.toLocal()}'.split(' ')[0]),
                        subtitle: Text(e.value['note']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _saveNote(e.key,
                                null); // This will delete using the stored ID
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
                            _deleteWorkout(w); // Uses stored ID directly
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
                            _deletePeriod(p); // Uses stored ID directly
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
    final noteData = _notes[day];
    final note = noteData?['note'];
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
    final noteData = _notes[normalized];
    final noteController = TextEditingController(text: noteData?['note'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(hintText: 'Enter note...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _saveNote(
                  normalized,
                  noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Popup menu for day cell
  Future<void> _showDayPopupMenu(
      BuildContext context, DateTime day, Offset position) async {
    final normalized = _normalize(day);
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'note',
          child: Row(
            children: const [
              Icon(Icons.note, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Add/Edit Note'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'workout',
          child: Row(
            children: const [
              Icon(Icons.fitness_center, size: 18, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Add Workout'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'period',
          child: Row(
            children: const [
              Icon(Icons.timeline, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text('Add Time Period'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'note') {
        _showDayActionDialog(normalized);
      } else if (value == 'workout') {
        _showWorkoutDialog(normalized);
      } else if (value == 'period') {
        _showAddPeriodDialog(startDate: normalized);
      }
    });
  }

  void _showAddPeriodDialog({DateTime? startDate}) {
    DateTime? start = startDate;
    DateTime? end = startDate;
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
                        locale: const Locale('en', 'GB'),
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
                        locale: const Locale('en', 'GB'),
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
                  _addPeriod(type!, start!, end!);
                  // setState(() {
                  //   //_periods.add(_Period(type!, start!, end!));
                  // });
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

  // Separate dialog for adding a workout
  void _showWorkoutDialog(DateTime date) {
    String? selectedWorkout;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Workout'),
        content: DropdownButtonFormField<String>(
          value: null,
          hint: const Text('Assign workout'),
          items: _workoutNames
              .map((w) => DropdownMenuItem(value: w, child: Text(w)))
              .toList(),
          onChanged: (val) {
            selectedWorkout = val;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (selectedWorkout != null) {
                _addWorkout(date, selectedWorkout!);
                // setState(() {
                //   // _calendarWorkouts
                //   //     .add(_CalendarWorkout(date, selectedWorkout!));
                // });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
