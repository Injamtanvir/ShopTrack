import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

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

  // Instance of connection checker
  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker();

  // Constructor with optional initial check
  ConnectivityService({bool checkImmediately = true}) {
    // Initialize listener for connectivity changes
    _connectionChecker.onStatusChange.listen((InternetConnectionStatus status) {
      _updateConnectionStatus(status);
    });

    if (checkImmediately) {
      checkConnectivity();
    }
  }

  // Check connectivity immediately
  Future<NetworkStatus> checkConnectivity() async {
    final bool isConnected = await _connectionChecker.hasConnection;
    _updateConnectionStatus(
      isConnected ? InternetConnectionStatus.connected : InternetConnectionStatus.disconnected
    );
    return _currentStatus;
  }

  // Update the connection status based on connectivity result
  void _updateConnectionStatus(InternetConnectionStatus status) {
    NetworkStatus previousStatus = _currentStatus;
    
    if (status == InternetConnectionStatus.disconnected) {
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