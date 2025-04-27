// Stub implementation for connectivity service
// Original connectivity_plus implementation temporarily disabled due to Gradle compatibility issues
import 'dart:async';

class ConnectivityService {
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  ConnectivityService() {
    _init();
  }

  void _init() async {
    // Always assume connected during development
    _updateConnectionStatus(true);
  }

  void _updateConnectionStatus(bool isConnected) {
    _connectionStatusController.add(isConnected);
  }

  Future<bool> isConnected() async {
    // Always return true during development
    return true;
  }

  void dispose() {
    _connectionStatusController.close();
  }
}