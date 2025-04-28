import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  // Create a stream controller to broadcast connection changes
  final StreamController<NetworkStatus> _networkStatusController = 
      StreamController<NetworkStatus>.broadcast();

  // Expose the stream to listen to
  Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;

  // Store the current connectivity status
  NetworkStatus _currentStatus = NetworkStatus.online;
  NetworkStatus get currentStatus => _currentStatus;

  // Constructor with optional initial check
  ConnectivityService({bool checkImmediately = true}) {
    // Initialize listener for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });

    if (checkImmediately) {
      checkConnectivity();
    }
  }

  // Check connectivity immediately
  Future<NetworkStatus> checkConnectivity() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
    return _currentStatus;
  }

  // Update the connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    NetworkStatus previousStatus = _currentStatus;
    
    if (result == ConnectivityResult.none) {
      _currentStatus = NetworkStatus.offline;
    } else {
      _currentStatus = NetworkStatus.online;
    }

    // Only add to stream if status has changed
    if (previousStatus != _currentStatus) {
      _networkStatusController.add(_currentStatus);
    }
  }

  // Dispose the controller when done
  void dispose() {
    _networkStatusController.close();
  }
}