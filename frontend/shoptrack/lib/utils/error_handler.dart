import 'package:flutter/material.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    String errorMessage = error.toString();

    if (errorMessage.contains('SocketException') || 
        errorMessage.contains('Failed host lookup') ||
        errorMessage.contains('No address associated with hostname') ||
        errorMessage.contains('Network is unreachable') ||
        errorMessage.contains('Connection refused') ||
        errorMessage.contains('Connection timed out') ||
        errorMessage.contains('Connection closed') ||
        errorMessage.contains('No internet')) {
      return 'No internet connection. Please connect your device to a network.';
    }

    return errorMessage;
  }

  static void showErrorDialog(BuildContext context, dynamic error) {
    final errorMessage = getErrorMessage(error);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final errorMessage = getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}