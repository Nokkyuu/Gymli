/// File Service - Handles file operations for import/export
library;

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:file_picker/file_picker.dart';
import '../models/settings_operation_result.dart';
import 'web_download_service.dart';

class FileService {
  /// Save CSV data to file
  static Future<SettingsOperationResult> saveJsonFile({
    required String csvData,
    required String fileName,
    required String dataType,
  }) async {
    try {
      if (kIsWeb) {
        return await _saveWebFile(csvData, fileName, dataType);
      } else {
        return await _saveMobileFile(csvData, fileName, dataType);
      }
    } catch (e) {
      return SettingsOperationResult.error(
        message: 'Error saving $dataType: ${e.toString()}',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Pick and read CSV file
  static Future<SettingsOperationResult> pickAndReadJsonFile({
    required String dataType,
  }) async {
    try {
      // Use file_picker for cross-platform file picking (including web)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return SettingsOperationResult.cancelled();
      }

      // Read the file content - handle both web and mobile platforms
      String JsonContent;
      if (result.files.first.bytes != null) {
        // Web platform - file content is available as bytes
        JsonContent = String.fromCharCodes(result.files.first.bytes!);
      } else if (result.files.first.path != null) {
        // Mobile platforms - file content is available via file path
        JsonContent = await File(result.files.first.path!).readAsString();
      } else {
        return SettingsOperationResult.error(
          message: 'Unable to read file content',
        );
      }

      return SettingsOperationResult.success(
        message: JsonContent,
        // Don't set filePath to avoid web issues
      );
    } catch (e) {
      return SettingsOperationResult.error(
        message: 'Error reading $dataType file: ${e.toString()}',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Save file on web platform
  static Future<SettingsOperationResult> _saveWebFile(
    String csvData,
    String fileName,
    String dataType,
  ) async {
    try {
      final bytes = utf8.encode(csvData);

      final params = SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
        mimeTypesFilter: ['text/csv'],
      );

      // Use web download service for fallback
      WebDownloadService.downloadCsv(csvData, fileName);

      final result = await FlutterFileDialog.saveFile(params: params);

      if (result != null) {
        return SettingsOperationResult.success(
          message: '$dataType exported successfully',
          filePath: result,
        );
      } else {
        return SettingsOperationResult.cancelled();
      }
    } catch (e) {
      // Fallback to showing data in dialog
      return SettingsOperationResult.success(
        message: csvData, // Return CSV data for display
        filePath: 'web_fallback',
      );
    }
  }

  /// Save file on mobile platform
  static Future<SettingsOperationResult> _saveMobileFile(
    String csvData,
    String fileName,
    String dataType,
  ) async {
    try {
      final directory = (await getApplicationSupportDirectory()).path;
      final path = "$directory/$fileName";

      final File file = File(path);
      await file.writeAsString(csvData, encoding: utf8);

      final params = SaveFileDialogParams(
        sourceFilePath: path,
        fileName: fileName,
        mimeTypesFilter: ['text/csv'],
      );

      final result = await FlutterFileDialog.saveFile(params: params);

      if (result != null) {
        return SettingsOperationResult.success(
          message: '$dataType exported successfully to $result',
          filePath: result,
        );
      } else {
        return SettingsOperationResult.cancelled();
      }
    } catch (e) {
      rethrow;
    }
  }
}
