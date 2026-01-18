import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'auto_plot_scan_screen.dart';
import 'auto_plot_scan_screen_web.dart';

/// Routes to the appropriate Auto-Plot scan screen based on platform.
/// Uses native camera + gyroscope on mobile, web APIs on browser.
class AutoPlotScanRouter extends StatelessWidget {
  final String targetType;
  final bool isTripleSpot;

  const AutoPlotScanRouter({
    super.key,
    required this.targetType,
    this.isTripleSpot = false,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return AutoPlotScanScreenWeb(
        targetType: targetType,
        isTripleSpot: isTripleSpot,
      );
    }

    return AutoPlotScanScreen(
      targetType: targetType,
      isTripleSpot: isTripleSpot,
    );
  }
}
