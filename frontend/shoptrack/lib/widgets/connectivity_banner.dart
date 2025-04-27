import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class ConnectivityBanner extends StatelessWidget {
  final Widget child;
  final bool showBanner;

  const ConnectivityBanner({
    Key? key,
    required this.child,
    this.showBanner = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: kNewWarningColor,
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No internet connection. Some features may be limited.',
                        style: TextStyle(
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
                      onPressed: () {
                        // This would normally dismiss the banner
                        // But since we're not implementing connectivity check
                        // this is just a placeholder
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
} 