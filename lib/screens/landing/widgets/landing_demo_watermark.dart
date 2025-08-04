/// Landing Demo Watermark - Demo mode overlay widget
library;

import 'package:flutter/material.dart';

class LandingDemoWatermark extends StatelessWidget {
  final bool isLoggedIn;

  const LandingDemoWatermark({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: -0.3, // Slight rotation for watermark effect
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DEMO MODE\nNo data will be saved\nplease log in',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.withValues(alpha: 0.4),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
