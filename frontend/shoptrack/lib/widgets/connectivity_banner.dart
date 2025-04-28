import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../providers/connectivity_provider.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _showRestoreMessage = false;

  @override
  Widget build(BuildContext context) {
    // Listen to network status changes
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        // Show the "Connection Restored" message briefly when we come back online
        if (connectivityProvider.isOnline && connectivityProvider.showBanner) {
          // Show restoration message briefly
          _showRestoreMessage = true;
          
          // Auto-hide restoration message after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showRestoreMessage = false;
              });
              // Hide the main banner too since we're back online
              connectivityProvider.hideBanner();
            }
          });
        }

        return Stack(
          children: [
            widget.child,
            
            // Offline banner (red warning)
            if (connectivityProvider.isOffline && connectivityProvider.showBanner)
              _buildNetworkBanner(
                message: 'No internet connection. Some features will be disabled.',
                icon: Icons.wifi_off,
                color: kNewErrorColor,
                onClose: () => connectivityProvider.hideBanner(),
              ),
              
            // Connection restored banner (green success)
            if (connectivityProvider.isOnline && _showRestoreMessage)
              _buildNetworkBanner(
                message: 'Internet connection restored.',
                icon: Icons.wifi,
                color: kNewSuccessColor,
                onClose: () {
                  setState(() {
                    _showRestoreMessage = false;
                  });
                  connectivityProvider.hideBanner();
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildNetworkBanner({
    required String message,
    required IconData icon,
    required Color color,
    required VoidCallback onClose,
  }) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: color,
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 