/// Settings Header Widget - App branding and version info
library;

import 'package:flutter/material.dart';

class SettingsHeaderWidget extends StatelessWidget {
  const SettingsHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background image with reduced opacity
          Opacity(
            opacity:
                0.15, // Adjust this value (0.0 to 1.0) for desired transparency
            child: Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'images/Icon-App_3_Darkmode.png'
                  : 'images/Icon-App_3.png',
              fit: BoxFit.fill,
            ),
          ),
          // Text overlay
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Gymli',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Son of Gain, part of the Fellowship of the Gym',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.1.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
              const SizedBox(height: 15),
              Text(
                'You should be lifting instead of fumbling with settings, son.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
