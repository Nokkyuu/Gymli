import 'package:flutter/material.dart';
import '../controllers/calendar_controller.dart';

Future<void> showDayActionDialog(
  BuildContext context,
  CalendarController controller,
  DateTime date,
) async {
  final noteData = controller.notes[date];
  final noteController = TextEditingController(text: noteData?.note ?? '');
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Note'),
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
            await controller.saveNote(
              date,
              noteController.text.trim().isEmpty
                  ? null
                  : noteController.text.trim(),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> showAddPeriodDialog({
  required BuildContext context,
  required CalendarController controller,
  DateTime? startDate,
}) async {
  DateTime? start = startDate;
  DateTime? end = startDate;
  String? type;
  String? errorText;

  await showDialog(
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
              items: const [
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
                final hasOverlap = controller.periods.any(
                    (p) => (start!.isBefore(p.end) && end!.isAfter(p.start)));
                if (hasOverlap) {
                  setStateDialog(() {
                    errorText = 'Periods cannot overlap!';
                  });
                  return;
                }
                await controller.addPeriod(type!, start!, end!);
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

Future<void> showWorkoutDialog(
  BuildContext context,
  CalendarController controller,
  DateTime date,
) async {
  String? selectedWorkout;
  String repeatType = 'none';
  int intervalDays = 3;
  int durationWeeks = 6;
  final List<String> repeatTypes = ['none', 'weekly', 'interval'];
  String? errorText;

  await showDialog(
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
              items: controller.workoutNames
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
                await controller.addWorkout(date, selectedWorkout!);
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
                  await controller.addWorkout(d, selectedWorkout!);
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
