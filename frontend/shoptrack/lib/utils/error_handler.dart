import 'package:flutter/material.dart';

class ErrorHandler {
  static void showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String getReadableError(dynamic error) {
    String errorMessage = error.toString();

    if (errorMessage.contains('MissingPluginException')) {
      return 'This function is not available on this platform.';
    } else if (errorMessage.contains('<!DOCTYPE')) {
      return 'Server communication error. Please try again later.';
    }

    return errorMessage;
  }
}