// lib/utils/web_stub.dart
// This file provides web functionality and stubs for IO

// Re-export dart:html for web
import 'dart:html' as html;
export 'dart:html' show Blob;

// Create a stub for File class that is compatible with the web
class File {
  final String path;

  File(this.path);

  Future<List<int>> readAsBytes() async {
    throw UnsupportedError('File I/O is not supported on the web');
  }

  Future<void> writeAsBytes(List<int> bytes) async {
    throw UnsupportedError('File I/O is not supported on the web');
  }
}

// Utility class to handle web-specific operations
class WebUtils {
  // Create a blob URL from bytes
  static String createPdfBlobUrl(List<int> bytes) {
    final blob = html.Blob([bytes], 'application/pdf');
    return html.Url.createObjectUrlFromBlob(blob);
  }

  // Open URL in a new tab
  static void openUrl(String url, [String target = '_blank']) {
    html.window.open(url, target);
  }
}