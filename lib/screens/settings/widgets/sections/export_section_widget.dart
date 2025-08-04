/// Export Section Widget - Handles data export operations
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/settings_controller.dart';
import '../../models/settings_data_type.dart';
import '../dialogs/progress_dialog.dart';

class ExportSectionWidget extends StatelessWidget {
  const ExportSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.download,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Export Data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Export your data to CSV files for backup or analysis.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                // Individual export buttons
                ...SettingsDataType.values.map((dataType) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: controller.isAnyOperationInProgress
                            ? null
                            : () => _exportData(context, controller, dataType),
                        icon: Icon(dataType.icon, size: 18),
                        label: Text('Export ${dataType.displayName}'),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // Export all button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.isAnyOperationInProgress
                        ? null
                        : () => _exportAllData(context, controller),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export All Data'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportData(
    BuildContext context,
    SettingsController controller,
    SettingsDataType dataType,
  ) async {
    try {
      // Check if data exists
      final hasData = await controller.hasData(dataType);
      if (!hasData) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No ${dataType.displayName.toLowerCase()} to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        final result = await ProgressDialog.show(
          context,
          title: 'Exporting ${dataType.displayName}',
          message:
              'Preparing and saving ${dataType.displayName.toLowerCase()}...',
          operation: controller.exportData(dataType, context),
        );

        if (result != null && context.mounted) {
          await ProgressDialog.showResult(
            context,
            result,
            title: 'Export ${dataType.displayName}',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting ${dataType.displayName}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAllData(
    BuildContext context,
    SettingsController controller,
  ) async {
    try {
      // Check if any data exists
      final hasAnyData = await controller.hasAnyData();
      if (!hasAnyData) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        final result = await ProgressDialog.show(
          context,
          title: 'Exporting All Data',
          message: 'Exporting all application data...',
          operation: controller.exportAllData(context),
        );

        if (result != null && context.mounted) {
          await ProgressDialog.showResult(
            context,
            result,
            title: 'Export All Data',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting all data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
