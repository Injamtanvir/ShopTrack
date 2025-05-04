import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Timer? _checkTimer;

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Track the current connection status
  bool _isConnected = true;

  ConnectivityService() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkConnectivity();
    });

    _init();
  }

  void _init() {
    _connectionChecker.onStatusChange.listen((InternetConnectionStatus status) {
      final bool isConnected = status == InternetConnectionStatus.connected;

      if (isConnected != _isConnected) {
        _isConnected = isConnected;
        _updateConnectionStatus(isConnected);
      }
    });

    checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    final bool isConnected = await _connectionChecker.hasConnection;
    if (isConnected != _isConnected) {
      _isConnected = isConnected;
      _updateConnectionStatus(isConnected);
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    _connectionStatusController.add(isConnected);
  }

  Future<bool> isConnected() async {
    return _isConnected;
  }

  void pause() {
    _checkTimer?.cancel();
  }

  void resume() {
    if (_checkTimer == null || !_checkTimer!.isActive) {
      _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        checkConnectivity();
      });
    }
  }

  void dispose() {
    _checkTimer?.cancel();
    _connectionStatusController.close();
  }
}