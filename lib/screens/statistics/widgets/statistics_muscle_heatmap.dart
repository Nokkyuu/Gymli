/// Statistics Muscle Heatmap Widget
/// Displays muscle usage heatmap visualization
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/statistics_main_controller.dart';

class StatisticsMuscleHeatmap extends StatelessWidget {
  final double width;
  final double height;

  const StatisticsMuscleHeatmap({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsMainController>(
      builder: (context, controller, child) {
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double availableHeight = constraints.maxHeight;
                double availableWidth = constraints.maxWidth;

                if (kDebugMode) {
                  print(
                      'Heatmap dimensions: $availableHeight x $availableWidth');
                }

                // Calculate appropriate dimensions while maintaining aspect ratio
                double imageWidth = availableWidth * 0.5;
                double imageHeight = availableHeight;
                double totalImageWidth =
                    imageWidth * 2; // Two images side by side

                // Ensure we don't exceed available space
                if (totalImageWidth > availableWidth * 0.8) {
                  imageWidth = (availableWidth * 0.8) / 2;
                }

                return Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scaleX: -1,
                          child: Image(
                            fit: BoxFit.fill,
                            width: imageWidth,
                            height: imageHeight,
                            image:
                                const AssetImage('images/muscles/Front_bg.png'),
                          ),
                        ),
                        Image(
                          fit: BoxFit.fill,
                          width: imageWidth,
                          height: imageHeight,
                          image: const AssetImage('images/muscles/Back_bg.png'),
                        ),
                      ],
                    ),
                    ...List.generate(
                      controller.heatMapMulti.length,
                      (i) => _buildHeatDot(
                        controller: controller,
                        index: i,
                        availableWidth: availableWidth,
                        availableHeight: availableHeight,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeatDot({
    required StatisticsMainController controller,
    required int index,
    required double availableWidth,
    required double availableHeight,
  }) {
    if (index >= controller.heatMapMulti.length ||
        index >= controller.heatMapCoordinates.length) {
      return const SizedBox.shrink();
    }

    final intensity = controller.heatMapMulti[index];
    final coordinates = controller.heatMapCoordinates[index];

    // Calculate dot size and position (matching original heatDot logic)
    final dotSize = 30 + (50 * intensity);
    final xPos = (availableWidth * coordinates[0]) - (dotSize / 2);
    final yPos = (availableHeight * coordinates[1]) - (dotSize / 2);
    final opacity = intensity == 0 ? 0 : 200;

    return HeatDot(
      x: xPos,
      y: yPos,
      dia: dotSize,
      opa: opacity,
      lerp: intensity,
      text: "${(intensity * 100).round()}%",
    );
  }
}

/// Heat Dot Widget - Individual muscle activation dot
/// Originally part of statistics_screen.dart, now properly encapsulated
class HeatDot extends StatelessWidget {
  const HeatDot({
    super.key,
    required this.y,
    required this.x,
    required this.dia,
    required this.opa,
    required this.lerp,
    required this.text,
  });

  final double y;
  final double x;
  final double dia;
  final int opa;
  final double lerp;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: y, // Changed from bottom to top to fix upside-down issue
      left: x,
      child: Container(
        width: dia,
        height: dia,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(
            Color.fromARGB(opa, 255, 200, 50), // Yellow/orange
            Color.fromARGB(opa, 255, 30, 50), // Red
            lerp,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: lerp > 0.5 ? Colors.white : Colors.black,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
