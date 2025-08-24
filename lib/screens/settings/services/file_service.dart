/// File Service - JSON-only import/export helpers
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
  // Deprecated CSV-named wrapper for backward compatibility
  static Future<SettingsOperationResult> saveCSVFile({
    required String csvData,
    required String fileName,
    required String dataType,
  }) async {
    return saveJsonFile(jsonData: csvData, fileName: fileName, dataType: dataType);
  }

  /// Save JSON data to file
  static Future<SettingsOperationResult> saveJsonFile({
    required String jsonData,
    required String fileName,
    required String dataType,
  }) async {
    try {
      if (kIsWeb) {
        return await _saveWebFile(jsonData, fileName, dataType);
      } else {
        return await _saveMobileFile(jsonData, fileName, dataType);
      }
    } catch (e) {
      return SettingsOperationResult.error(
        message: 'Error saving $dataType: ${e.toString()}',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // Deprecated CSV-named wrapper for backward compatibility
  static Future<SettingsOperationResult> pickAndReadCSVFile({
    required String dataType,
  }) async {
    return pickAndReadJsonFile(dataType: dataType);
  }

  /// Pick and read JSON file
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
      String jsonContent;
      if (result.files.first.bytes != null) {
        // Web platform - file content is available as bytes
        jsonContent = String.fromCharCodes(result.files.first.bytes!);
      } else if (result.files.first.path != null) {
        // Mobile platforms - file content is available via file path
        jsonContent = await File(result.files.first.path!).readAsString();
      } else {
        return SettingsOperationResult.error(
          message: 'Unable to read file content',
        );
      }

      return SettingsOperationResult.success(
        message: jsonContent,
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
    String jsonData,
    String fileName,
    String dataType,
  ) async {
    try {
      final bytes = utf8.encode(jsonData);

      final params = SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
        mimeTypesFilter: ['application/json'],
      );

      // Use web download service for fallback
      WebDownloadService.downloadCsv(jsonData, fileName);

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
        message: jsonData, // Return JSON data for display
        filePath: 'web_fallback',
      );
    }
  }

  /// Save file on mobile platform
  static Future<SettingsOperationResult> _saveMobileFile(
    String jsonData,
    String fileName,
    String dataType,
  ) async {
    try {
      final directory = (await getApplicationSupportDirectory()).path;
      final path = "$directory/$fileName";

      final File file = File(path);
      await file.writeAsString(jsonData, encoding: utf8);

      final params = SaveFileDialogParams(
        sourceFilePath: path,
        fileName: fileName,
        mimeTypesFilter: ['application/json'],
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
