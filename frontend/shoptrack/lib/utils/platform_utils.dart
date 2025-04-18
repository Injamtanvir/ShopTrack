import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Utility class for platform-specific operations
class PlatformUtils {
  /// Checks if the app is running on a desktop platform
  static bool get isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (e) {
      debugPrint('Error checking platform: $e');
      return false;
    }
  }

  /// Checks if the app is running on a mobile platform
  static bool get isMobile {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      debugPrint('Error checking platform: $e');
      return false;
    }
  }

  /// Checks if the app is running on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (e) {
      debugPrint('Error checking for Android: $e');
      return false;
    }
  }

  /// Checks if the app is running on iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (e) {
      debugPrint('Error checking for iOS: $e');
      return false;
    }
  }

  /// Gets the platform name for debugging
  static String get platformName {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isFuchsia) return 'fuchsia';
      return 'unknown';
    } catch (e) {
      debugPrint('Error getting platform name: $e');
      return 'unknown';
    }
  }

  /// Shows a platform-specific dialog
  static void showPlatformDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? cancelText,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelText),
            ),
          if (confirmText != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) onConfirm();
              },
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }
} 