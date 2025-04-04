// lib/utils/platform_helper.dart
import 'package:flutter/foundation.dart' show kIsWeb;

// Helper class to consolidate platform-specific logic
class PlatformHelper {
  static bool get isWeb => kIsWeb;
}