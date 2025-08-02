import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
//import '../utils/services/user_service.dart';
import 'package:Gymli/utils/services/service_container.dart';
import '../utils/themes/themes.dart';

final themeColors = ThemeColors();

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
  final container = ServiceContainer();
  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _loadCalendarNotes();
    _loadCalendarWorkouts();
    _loadPeriods();
  }

  Future<void> _loadWorkouts() async {
    final workouts = await container.workoutService.getWorkouts();
    setState(() {
      _workoutNames = workouts.map<String>((w) => w['name'] as String).toList();
    });
  }

  Future<void> _loadCalendarNotes() async {
    final notes = await container.calendarService.getCalendarNotes();
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
    final workouts = await container.calendarService.getCalendarWorkouts();
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
    final periods = await container.calendarService.getPeriods();
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
        await container.calendarService.deleteCalendarNote(existingNote['id']);
      }
      setState(() {
        _notes.remove(date);
      });
    } else {
      if (existingNote != null) {
        // Update existing note
        await container.calendarService
            .updateCalendarNote(existingNote['id'], note: note, date: date);
        setState(() {
          _notes[date] = {'note': note, 'id': existingNote['id']};
        });
      } else {
        // Create new note - now returns the created note with ID
        final createdNote = await container.calendarService
            .createCalendarNote(date: date, note: note);
        setState(() {
          _notes[date] = {'note': note, 'id': createdNote['id']};
        });
      }
    }
  }

  void _addWorkout(DateTime date, String workoutName) async {
    try {
      final createdWorkout = await container.calendarService
          .createCalendarWorkout(date: date, workout: workoutName);
      setState(() {
        _calendarWorkouts.add(_CalendarWorkout(
          _normalize(date),
          workoutName,
          id: createdWorkout['id'],
        ));
      });
    } catch (e) {
      if (kDebugMode) print('Error adding workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add workout: $e')),
      );
    }
  }

  void _addPeriod(String type, DateTime start, DateTime end) async {
    try {
      if (kDebugMode) print('Adding period: $type from $start to $end');
      final createdPeriod = await container.calendarService
          .createPeriod(type: type, startDate: start, endDate: end);

      setState(() {
        _periods.add(_Period(
          type,
          start,
          end,
          id: createdPeriod['id'],
        ));
      });
    } catch (e) {
      print('Error adding period: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add period: $e')),
      );
    }
  }

  void _deleteWorkout(_CalendarWorkout workout) async {
    if (workout.id != null) {
      await container.calendarService.deleteCalendarWorkout(workout.id!);
    }
    setState(() {
      _calendarWorkouts.remove(workout);
    });
  }

  void _deletePeriod(_Period period) async {
    if (period.id != null) {
      await container.calendarService.deletePeriod(period.id!);
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
        return themeColors.periodColors['cut'];
      case 'bulk':
        return themeColors.periodColors['bulk'];
      default:
        return themeColors.periodColors['other'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar & Notes')),
      body: Column(
        children: [
          TableCalendar(
            headerVisible: true,
            headerStyle: const HeaderStyle(
              titleCentered: false,
              formatButtonVisible: false,
              leftChevronVisible: true,
              rightChevronVisible: true,
              leftChevronIcon: Icon(null),
              rightChevronIcon: Icon(null),
            ),
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
          DefaultTabController(
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
                        // Notes Tab
                        _notes.isNotEmpty
                            ? ListView(
                                children: (_notes.entries.toList()
                                      ..sort((a, b) => b.key.compareTo(a.key)))
                                    .map((e) => ListTile(
                                          leading: const Icon(Icons.note),
                                          title: Text('${e.key.toLocal()}'
                                              .split(' ')[0]),
                                          subtitle: Text(e.value['note']),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              _saveNote(e.key, null);
                                            },
                                          ),
                                        ))
                                    .toList(),
                              )
                            : const Center(child: Text('No notes yet.')),
                        // Workouts Tab
                        _calendarWorkouts.isNotEmpty
                            ? ListView(
                                children: (_calendarWorkouts.toList()
                                      ..sort(
                                          (a, b) => b.date.compareTo(a.date)))
                                    .map((w) => ListTile(
                                          leading:
                                              const Icon(Icons.fitness_center),
                                          title: Text('${w.workoutName}'),
                                          subtitle: Text('${w.date.toLocal()}'
                                              .split(' ')[0]),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              _deleteWorkout(w);
                                            },
                                          ),
                                        ))
                                    .toList(),
                              )
                            : const Center(child: Text('No workouts yet.')),
                        // Periods Tab
                        _periods.isNotEmpty
                            ? ListView(
                                children: (_periods.toList()
                                      ..sort(
                                          (a, b) => b.start.compareTo(a.start)))
                                    .map((p) => ListTile(
                                          leading: const Icon(Icons.timeline),
                                          title: Text(
                                              '${p.type[0].toUpperCase()}${p.type.substring(1)} period'),
                                          subtitle: Text(
                                              '${p.start.toLocal()} - ${p.end.toLocal()}'
                                                  .replaceAll(
                                                      ' 00:00:00.000', '')),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              _deletePeriod(p);
                                            },
                                          ),
                                        ))
                                    .toList(),
                              )
                            : const Center(child: Text('No periods yet.')),
                      ],
                    ),
                  ),
                ],
              ),
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

  void _clearNotesAndWorkoutsForDay(DateTime day) async {
    // Remove note
    if (_notes.containsKey(day)) {
      await container.calendarService.deleteCalendarNote(_notes[day]!['id']);
      setState(() {
        _notes.remove(day);
      });
    }
    // Remove all workouts for that day
    final workoutsToRemove =
        _calendarWorkouts.where((w) => _normalize(w.date) == day).toList();
    for (final w in workoutsToRemove) {
      if (w.id != null) {
        await container.calendarService.deleteCalendarWorkout(w.id!);
      }
    }
    setState(() {
      _calendarWorkouts.removeWhere((w) => _normalize(w.date) == day);
    });
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
        const PopupMenuItem(
          value: 'note',
          child: Row(
            children: const [
              Icon(Icons.note, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Add/Edit Note'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'workout',
          child: Row(
            children: const [
              Icon(Icons.fitness_center, size: 18, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Add Workout'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'period',
          child: Row(
            children: const [
              Icon(Icons.timeline, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text('Add Time Period'),
            ],
          ),
        ),
        if (_notes.containsKey(_normalize(day)) ||
            _calendarWorkouts.any((w) => _normalize(w.date) == _normalize(day)))
          const PopupMenuItem(
            value: 'clear',
            child: Row(
              children: [
                Icon(Icons.clear, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Clear Notes & Workouts'),
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
      } else if (value == 'clear') {
        _clearNotesAndWorkoutsForDay(normalized);
      }
    });
  }

  void _showAddPeriodDialog({DateTime? startDate}) {
    DateTime? start = startDate;
    DateTime? end = startDate;
    String? type;
    String? errorText;

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
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (type != null &&
                    start != null &&
                    end != null &&
                    !end!.isBefore(start!)) {
                  // Check for overlap
                  final hasOverlap = _periods.any(
                      (p) => (start!.isBefore(p.end) && end!.isAfter(p.start)));
                  if (hasOverlap) {
                    setStateDialog(() {
                      errorText = 'Periods cannot overlap!';
                    });
                    return;
                  }
                  _addPeriod(type!, start!, end!);
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
    String repeatType = 'none'; // 'none', 'weekly', 'interval'
    int intervalDays = 3;
    int durationWeeks = 6;
    final List<String> repeatTypes = ['none', 'weekly', 'interval'];
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Workout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedWorkout,
                hint: const Text('Assign workout'),
                items: _workoutNames
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
                onChanged: (val) => setStateDialog(() => selectedWorkout = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: repeatType,
                items: repeatTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t == 'none'
                                ? 'No Repeat'
                                : t == 'weekly'
                                    ? 'Repeat Weekly'
                                    : 'Repeat Every X Days',
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setStateDialog(() => repeatType = val!),
                decoration: const InputDecoration(labelText: 'Repeat'),
              ),
              if (repeatType == 'weekly') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Duration (weeks):'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: durationWeeks.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            setStateDialog(() => durationWeeks = parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (repeatType == 'interval') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('with'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: TextFormField(
                        initialValue: intervalDays.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            setStateDialog(() => intervalDays = parsed + 1);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('days rest'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Duration (weeks):'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: durationWeeks.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            setStateDialog(() => durationWeeks = parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectedWorkout == null) {
                  setStateDialog(() => errorText = 'Please select a workout');
                  return;
                }
                if (repeatType == 'none') {
                  _addWorkout(date, selectedWorkout!);
                } else {
                  if (durationWeeks <= 0) {
                    setStateDialog(
                        () => errorText = 'Duration must be at least 1 week');
                    return;
                  }
                  DateTime current = date;
                  DateTime endDate1 =
                      date.add(Duration(days: (durationWeeks * 7) - 7));
                  DateTime endDate2 =
                      date.add(Duration(days: (durationWeeks * 7)));
                  List<DateTime> dates = [];
                  if (repeatType == 'weekly') {
                    while (!current.isAfter(endDate1)) {
                      dates.add(current);
                      current = current.add(const Duration(days: 7));
                    }
                  } else if (repeatType == 'interval') {
                    while (!current.isAfter(endDate2)) {
                      dates.add(current);
                      current = current.add(Duration(days: intervalDays));
                    }
                  }
                  for (final d in dates) {
                    _addWorkout(d, selectedWorkout!);
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
