/// Statistics Date Picker Widget
/// Handles date selection for statistics filtering
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/statistics_main_controller.dart';

class StatisticsDatePicker extends StatelessWidget {
  const StatisticsDatePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsMainController>(
      builder: (context, controller, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 16),
            // Left side - date pickers with constraints
            Flexible(
              flex: 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 250,
                  maxWidth: 400,
                ),
                child: Column(
                  children: [
                    // Start Date Picker
                    _buildDatePickerField(
                      context: context,
                      label: 'Select Start Date',
                      value: controller.tempStartingDate,
                      onDateSelected: (date) {
                        controller.setTempStartingDate(
                            DateFormat('dd-MM-yyyy').format(date));
                      },
                    ),
                    const SizedBox(height: 10),
                    // End Date Picker
                    _buildDatePickerField(
                      context: context,
                      label: 'Select End Date',
                      value: controller.tempEndingDate,
                      onDateSelected: (date) {
                        controller.setTempEndingDate(
                            DateFormat('dd-MM-yyyy').format(date));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right side - buttons with constraints
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 80,
                maxWidth: 120,
              ),
              child: Column(
                children: [
                  // Confirm button
                  ElevatedButton(
                    onPressed: () async {
                      await controller.confirmDateSelection();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Confirm"),
                  ),
                  const SizedBox(height: 8),
                  // Clear button
                  TextButton(
                    onPressed: () async {
                      await controller.clearDateSelection();
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Clear", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        );
      },
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required String? value,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime initialDate =
            value != null ? _parseDate(value) : DateTime.now();

        final DateTime? picked = await showDatePicker(
          locale: const Locale('en', 'GB'),
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          helpText: label,
        );

        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                color: value != null ? Colors.black : Colors.grey[600],
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  DateTime _parseDate(String dateString) {
    try {
      final parts = dateString.split('-');
      return DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
    } catch (e) {
      return DateTime.now();
    }
  }
}
