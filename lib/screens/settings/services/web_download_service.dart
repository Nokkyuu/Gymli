/// Web Download Service - Handles web-specific download operations
library;

import 'dart:convert';
import 'dart:html' as html;

class WebDownloadService {
  /// Download CSV file in web browser
  static void downloadCsv(String csvData, String fileName) {
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
