import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/food_data_controller.dart';
import '../controllers/food_logging_controller.dart';
import '../../../utils/themes/responsive_helper.dart';

/// Widget for date and weight input with log button
class DateWeightInputWidget extends StatelessWidget {
  const DateWeightInputWidget({super.key});

  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _logFood(BuildContext context) async {
    final dataController =
        Provider.of<FoodDataController>(context, listen: false);
    final loggingController =
        Provider.of<FoodLoggingController>(context, listen: false);

    if (dataController.selectedFoodName == null) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Please select a food');
      }
      return;
    }

    try {
      await loggingController.logFood(
        selectedFoodName: dataController.selectedFoodName!,
        selectedDate: dataController.selectedDate,
        foods: dataController.foods,
      );

      if (!context.mounted) return;

      // Reset selected date
      dataController.setSelectedDate(DateTime.now());

      // Reload data
      await dataController.loadData();

      if (!context.mounted) return;

      _showSuccessSnackBar(context, 'Food logged successfully!');
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FoodDataController, FoodLoggingController>(
      builder: (context, dataController, loggingController, child) {
        return Column(
          children: [
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
                          initialDate: dataController.selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          dataController.setSelectedDate(date);
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
                                .format(dataController.selectedDate)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('Weight (grams)',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: loggingController.gramsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          // Trigger rebuild to update calculated nutrition
                          // This is handled by Consumer widgets listening to the controller
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                if (!ResponsiveHelper.isMobile(context))
                  Column(
                    children: [
                      const Text(""),
                      ElevatedButton(
                        onPressed: () => _logFood(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Text('Log Food'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (ResponsiveHelper.isMobile(context))
              Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _logFood(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Log Food'),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
