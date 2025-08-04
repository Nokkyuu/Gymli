/// Activity Log Form Widget - Form for logging activities
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../utils/api/api_models.dart';

class ActivityLogFormWidget extends StatelessWidget {
  final List<ApiActivity> activities;
  final String? selectedActivityName;
  final DateTime selectedDate;
  final TextEditingController durationController;
  final Function(String?) onActivityChanged;
  final Function(DateTime) onDateChanged;
  final VoidCallback onSubmit;

  const ActivityLogFormWidget({
    super.key,
    required this.activities,
    required this.selectedActivityName,
    required this.selectedDate,
    required this.durationController,
    required this.onActivityChanged,
    required this.onDateChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Log Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Activity selection dropdown
            const Text('Activity Type',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedActivityName,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: activities.map((activity) {
                return DropdownMenuItem<String>(
                  value: activity.name,
                  child: Text(
                      '${activity.name} (${activity.kcalPerHour.toInt()} kcal/hr)'),
                );
              }).toList(),
              onChanged: onActivityChanged,
            ),
            const SizedBox(height: 16),

            // Date and Duration selection
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const Text('Date',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          onDateChanged(date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text(DateFormat('MMM dd, yyyy')
                                .format(selectedDate)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('Duration (minutes)',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(FontAwesomeIcons.plus),
              label: const Text('Log Activity'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
