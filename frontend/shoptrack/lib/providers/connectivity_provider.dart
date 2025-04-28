import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  NetworkStatus _status = NetworkStatus.online;
  bool _showBanner = false;
  bool _hasBeenOnlineBefore = true;
  
  // Status getters
  NetworkStatus get status => _status;
  bool get isOnline => _status == NetworkStatus.online;
  bool get isOffline => _status == NetworkStatus.offline;
  bool get showBanner => _showBanner;
  
  // Was online and then went offline
  bool get isConnectionLost => isOffline && _hasBeenOnlineBefore;

  ConnectivityProvider(this._connectivityService) {
    // Initialize with the current status
    _status = _connectivityService.currentStatus;
    
    // Listen for status changes
    _connectivityService.networkStatusStream.listen((NetworkStatus newStatus) {
      // Update status
      _status = newStatus;
      
      // If we were online before, remember that
      if (newStatus == NetworkStatus.online) {
        _hasBeenOnlineBefore = true;
      }
      
      // Show banner when offline, but don't hide automatically
      if (newStatus == NetworkStatus.offline) {
        _showBanner = true;
      }
      
      // Notify listeners about the change
      notifyListeners();
    });
  }
  
  // Check connectivity explicitly
  Future<void> checkConnectivity() async {
    final status = await _connectivityService.checkConnectivity();
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }
  
  // Manually hide the banner if needed
  void hideBanner() {
    if (_showBanner) {
      _showBanner = false;
      notifyListeners();
    }
  }
  
  // Method to check if user can perform network operations
  bool canPerformNetworkOperation() {
    return isOnline;
  }
} 