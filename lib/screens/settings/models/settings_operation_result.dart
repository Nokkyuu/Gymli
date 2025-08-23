/// Settings Operation Result - Model for operation results
library;

enum OperationStatus { success, error, cancelled, inProgress }

class SettingsOperationResult {
  final OperationStatus status;
  final String? message;
  final int? importedCount;
  final int? skippedCount;
  final int? deletedCount;
  final String? filePath;
  final Exception? error;

  const SettingsOperationResult({
    required this.status,
    this.message,
    this.importedCount,
    this.skippedCount,
    this.deletedCount,
    this.filePath,
    this.error,
  });

  factory SettingsOperationResult.success({
    String? message,
    int? importedCount,
    int? skippedCount,
    int? deletedCount,
    String? filePath,
  }) {
    return SettingsOperationResult(
      status: OperationStatus.success,
      message: message,
      importedCount: importedCount,
      skippedCount: skippedCount,
      deletedCount: deletedCount,
      filePath: filePath,
    );
  }

  factory SettingsOperationResult.error({
    required String message,
    Exception? error,
  }) {
    return SettingsOperationResult(
      status: OperationStatus.error,
      message: message,
      error: error,
    );
  }

  factory SettingsOperationResult.cancelled() {
    return const SettingsOperationResult(
      status: OperationStatus.cancelled,
      message: 'Operation cancelled by user',
    );
  }

  factory SettingsOperationResult.inProgress({String? message}) {
    return SettingsOperationResult(
      status: OperationStatus.inProgress,
      message: message,
    );
  }

  bool get isSuccess => status == OperationStatus.success;
  bool get isError => status == OperationStatus.error;
  bool get isCancelled => status == OperationStatus.cancelled;
  bool get isInProgress => status == OperationStatus.inProgress;

  String get displayMessage {
    switch (status) {
      case OperationStatus.success:
        if (importedCount != null || deletedCount != null) {
          List<String> parts = [];
          if (importedCount != null) {
            parts.add('Imported: $importedCount items');
          }
          if (deletedCount != null) parts.add('Deleted: $deletedCount items');
          if (skippedCount != null && skippedCount! > 0) {
            parts.add('Skipped: $skippedCount items');
          }
          return parts.join('\n');
        }
        return message ?? 'Operation completed successfully';
      case OperationStatus.error:
        return message ?? 'Operation failed';
      case OperationStatus.cancelled:
        return message ?? 'Operation cancelled';
      case OperationStatus.inProgress:
        return message ?? 'Operation in progress...';
    }
  }
}
