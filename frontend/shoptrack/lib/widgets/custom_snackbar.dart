import 'package:flutter/material.dart';

class CustomSnackbar {
  static void show(BuildContext context, String message, {bool isError = false, Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration ?? Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
  
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    show(context, message, isError: false, duration: duration);
  }
  
  static void showError(BuildContext context, String message, {Duration? duration}) {
    show(context, message, isError: true, duration: duration);
  }
  
  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: duration ?? Duration(seconds: 3),
      ),
    );
  }
} 