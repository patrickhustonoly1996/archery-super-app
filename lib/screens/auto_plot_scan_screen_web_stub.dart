// Stub implementation for non-web platforms
// This file is used when dart:js_interop is not available

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Stub widget for non-web platforms.
/// The actual web implementation is in auto_plot_scan_screen_web.dart
class AutoPlotScanScreenWeb extends StatelessWidget {
  final String targetType;
  final bool isTripleSpot;

  const AutoPlotScanScreenWeb({
    super.key,
    required this.targetType,
    this.isTripleSpot = false,
  });

  @override
  Widget build(BuildContext context) {
    // This should never be shown - the router should use the native screen
    // on non-web platforms. But just in case:
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'SCAN TARGET',
          style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 20),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Web camera scanning is not available on this platform.\nUse the mobile app for best experience.',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
