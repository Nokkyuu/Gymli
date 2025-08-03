import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/themes/themes.dart';
import 'calendar/constants/calendar_constants.dart';
import 'calendar/controllers/calendar_controller.dart';
import 'calendar/widgets/widgets.dart';

ThemeColors themeColors = ThemeColors();

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CalendarController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper methods
  DateTime _normalize(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(CalendarConstants.appBarTitle)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
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
                firstDay: CalendarConstants.minDate,
                lastDay: CalendarConstants.maxDate,
                focusedDay: _controller.focusedDay,
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) =>
                    _controller.selectedDay != null &&
                    _normalize(day) == _normalize(_controller.selectedDay!),
                onDaySelected: (selectedDay, focusedDay) {
                  _controller.selectDay(selectedDay, focusedDay);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(
                      context: context,
                      day: day,
                      controller: _controller,
                      selected: false,
                      today: false,
                      onShowPopupMenu: _showDayPopupMenu,
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(
                      context: context,
                      day: day,
                      controller: _controller,
                      selected: true,
                      today: false,
                      onShowPopupMenu: _showDayPopupMenu,
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(
                      context: context,
                      day: day,
                      controller: _controller,
                      selected: false,
                      today: true,
                      onShowPopupMenu: _showDayPopupMenu,
                    );
                  },
                ),
              ),
              const CalendarLegend(),
              const SizedBox(height: 10),
              const Divider(),
              if (_controller.selectedDay != null)
                CalendarDayDetails(
                  day: _normalize(_controller.selectedDay!),
                  controller: _controller,
                ),
              CalendarTabView(controller: _controller),
            ],
          );
        },
      ),
    );
  }

  void _clearNotesAndWorkoutsForDay(DateTime day) async {
    // Use the controller's method to clear notes and workouts for the day
    await _controller.clearNotesAndWorkoutsForDay(day);
  }

  void _showDayActionDialog(DateTime date) {
    final normalized = _normalize(date);
    final noteData = _controller.notes[normalized];
    final noteController = TextEditingController(text: noteData?.note ?? '');
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
            onPressed: () async {
              await _controller.saveNote(
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
        if (_controller.hasNote(_normalize(day)) ||
            _controller.hasWorkout(_normalize(day)))
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
              onPressed: () async {
                if (type != null &&
                    start != null &&
                    end != null &&
                    !end!.isBefore(start!)) {
                  // Check for overlap
                  final hasOverlap = _controller.periods.any(
                      (p) => (start!.isBefore(p.end) && end!.isAfter(p.start)));
                  if (hasOverlap) {
                    setStateDialog(() {
                      errorText = 'Periods cannot overlap!';
                    });
                    return;
                  }
                  await _controller.addPeriod(type!, start!, end!);
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
                items: _controller.workoutNames
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
                  await _controller.addWorkout(date, selectedWorkout!);
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
                    await _controller.addWorkout(d, selectedWorkout!);
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
