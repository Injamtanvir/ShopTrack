// lib/utils/io_stub.dart
// A stub for WebUtils that's needed for the mobile platform

class WebUtils {
  // Stubs for web-specific operations
  static String createPdfBlobUrl(List<int> bytes) {
    throw UnsupportedError('createPdfBlobUrl is not supported on mobile platforms');
  }

  static void openUrl(String url, [String target = '_blank']) {
    throw UnsupportedError('openUrl is not supported on mobile platforms');
  }
}