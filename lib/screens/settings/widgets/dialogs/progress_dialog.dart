/// Progress Dialog - Shows operation progress with cancellation support
library;

import 'package:flutter/material.dart';
import '../../models/settings_operation_result.dart';

class ProgressDialog extends StatelessWidget {
  final String title;
  final String? message;
  final double? progress;
  final bool isCompleted;
  final VoidCallback? onCancel;

  const ProgressDialog({
    super.key,
    required this.title,
    this.message,
    this.progress,
    this.isCompleted = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCompleted) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            if (message != null)
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                '${((progress ?? 0) * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ] else ...[
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text('Operation completed successfully!'),
          ],
        ],
      ),
      actions: [
        if (!isCompleted && onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        if (isCompleted)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }

  /// Show simple progress dialog with static message
  static Future<T?> showWithProgress<T>(
    BuildContext context, {
    required String title,
    required Future<T> operation,
    String? message,
    VoidCallback? onCancel,
  }) async {
    T? result;
    Exception? error;
    bool isDialogDismissed = false;

    // Show dialog and store the dialog context
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ProgressDialog(
        title: title,
        message: message ?? 'Processing...',
        onCancel: onCancel,
      ),
    );

    try {
      // Execute operation
      result = await operation;
    } catch (e) {
      error = e is Exception ? e : Exception(e.toString());
    }

    // More robust dialog dismissal
    if (!isDialogDismissed) {
      try {
        // Try using the root navigator first for file dialog scenarios
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          isDialogDismissed = true;
        }
      } catch (e) {
        // If root navigator fails, try regular navigator
        try {
          if (context.mounted) {
            Navigator.of(context).pop();
            isDialogDismissed = true;
          }
        } catch (e2) {
          // Dialog might already be dismissed
          isDialogDismissed = true;
        }
      }
    }

    // Give more time for the dialog to close and any navigation to settle
    await Future.delayed(const Duration(milliseconds: 250));

    // Show result dialog if there was an error
    if (error != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return result;
  }

  /// Legacy method for backward compatibility
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Future<T> operation,
    String? message,
    VoidCallback? onCancel,
  }) async {
    return showWithProgress<T>(
      context,
      title: title,
      operation: operation,
      message: message,
      onCancel: onCancel,
    );
  }

  /// Show result dialog for operation results
  static Future<void> showResult(
    BuildContext context,
    SettingsOperationResult result, {
    String? title,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? (result.isSuccess ? 'Success' : 'Error')),
        content: Text(result.displayMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
