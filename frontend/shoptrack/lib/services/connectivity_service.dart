import 'dart:async';
import 'package:flutter_connectivity/flutter_connectivity.dart';
import 'package:log_plus/log_plus.dart';  // Import for LogLevel enum

class ConnectivityService {
  late FlutterConnectivity _connectivity;
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Track the current connection status
  bool _isConnected = true;

  ConnectivityService() {
    // Initialize with your backend endpoint
    _connectivity = FlutterConnectivity(endpoint: 'https://api.shoptrack.com');

    // Configure the connectivity monitoring
    _connectivity.configure(
      allowedFailedRequests: 2, // Number of failed requests before reporting connection loss
      checkInterval: const Duration(seconds: 5), // Check every 5 seconds
      logLevel: LogLevel.error, // Minimal logging
    );

    // Set latency thresholds (in milliseconds)
    _connectivity.setLatencyThresholds(
      disconnected: 10000, // 10 seconds
      slow: 5000,         // 5 seconds
      moderate: 2000,     // 2 seconds
      fast: 500,          // 0.5 seconds
    );

    _init();
  }

  void _init() {
    // Listen to connectivity changes
    _connectivity.listenToLatencyChanges((ConnectivityStatus status, int latency) {
      final bool isConnected = status != ConnectivityStatus.disconnected;

      // Only notify listeners if the connection status has changed
      if (isConnected != _isConnected) {
        _isConnected = isConnected;
        _updateConnectionStatus(isConnected);
      }
    });
  }

  void _updateConnectionStatus(bool isConnected) {
    _connectionStatusController.add(isConnected);
  }

  Future<bool> isConnected() async {
    return _isConnected;
  }

  void pause() {
    _connectivity.pause();
  }

  void resume() {
    _connectivity.resume();
  }

  void dispose() {
    _connectivity.dispose();
    _connectionStatusController.close();
  }
}