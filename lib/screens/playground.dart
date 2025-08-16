import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'dart:math';

class PlaygroundScreen extends StatelessWidget {
  const PlaygroundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fake exercise data simulating the exercise graph widget
    final exerciseData = _generateFakeExerciseData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playground - Exercise Graph'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Exercise Progress Graph',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Chart(
                data: exerciseData,
                variables: {
                  'day': Variable(
                    accessor: (Map map) => map['day'] as num,
                    scale: LinearScale(min: -30, max: 0),
                  ),
                  'score': Variable(
                    accessor: (Map map) => map['score'] as num,
                    scale: LinearScale(min: 0, max: 100),
                  ),
                  'type': Variable(
                    accessor: (Map map) => map['type'] as String,
                  ),
                },
                marks: [
                  // Line marks for best and lowest performance
                  LineMark(
                    position: Varset('day') * Varset('score'),
                    color: ColorEncode(
                      variable: 'type',
                      values: [
                        Colors.blue,
                        Colors.blue.withOpacity(0.4),
                      ],
                    ),
                    size: SizeEncode(
                      variable: 'type',
                      values: [2, 1.5],
                    ),
                    shape: ShapeEncode(value: BasicLineShape(smooth: true)),
                  ),
                  // Point marks for data points
                  PointMark(
                    position: Varset('day') * Varset('score'),
                    color: ColorEncode(
                      variable: 'type',
                      values: [
                        Colors.blue,
                        Colors.blue.withOpacity(0.4),
                      ],
                    ),
                    size: SizeEncode(
                      variable: 'type',
                      values: [3, 2],
                    ),
                  ),
                ],
                axes: [
                  Defaults.horizontalAxis,
                  Defaults.verticalAxis,
                ],
                selections: {
                  'tooltipMouse': PointSelection(
                    on: {GestureType.hover, GestureType.tap},
                    devices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
                  )
                },
                tooltip: TooltipGuide(
                  followPointer: [false, true],
                  align: Alignment.topLeft,
                  offset: const Offset(-20, -30),
                  backgroundColor: Colors.black87,
                  elevation: 4,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegend(),
            const SizedBox(height: 10),
            const Text(
              'This graph shows exercise progress over the last 30 days.\nBlue line represents best performance, lighter line shows lowest performance.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Data points: ${exerciseData.length ~/ 2} workout days',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue, 'Best Performance'),
        const SizedBox(width: 20),
        _buildLegendItem(Colors.blue.withOpacity(0.4), 'Lowest Performance'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _generateFakeExerciseData() {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();

    // Generate data for the last 30 days
    for (int i = -30; i <= 0; i++) {
      final date = now.add(Duration(days: i));

      // Skip some days to simulate real workout patterns (but keep more data points)
      if (i % 4 == 0) continue;

      // Generate best performance scores (trending upward)
      final bestScore = 30 + (i + 30) * 1.2 + sin(i * 0.2) * 15;
      // Generate lowest performance scores (always lower than best)
      final lowestScore = bestScore - 20 - cos(i * 0.25) * 8;

      data.add({
        'day': i,
        'score': bestScore.clamp(10, 90).toDouble(),
        'type': 'best',
        'date': '${date.day}/${date.month}',
      });

      data.add({
        'day': i,
        'score': lowestScore.clamp(5, 80).toDouble(),
        'type': 'lowest',
        'date': '${date.day}/${date.month}',
      });
    }

    print('Generated ${data.length} data points'); // Debug print
    return data;
  }
}
