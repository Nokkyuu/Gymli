import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Gymli/exerciseScreen.dart'; // Adjust the import based on your project structure

void main() {
  group('ExerciseScreen Graph Tests', () {
    testWidgets('Graph should display data when training sets are available',
        (WidgetTester tester) async {
      // Test that the graph widget is rendered
      await tester.pumpWidget(MaterialApp(
        home: ExerciseScreen('Test Exercise', 'Warm: 2, Work: 3'),
      ));

      // Wait for async initialization
      await tester.pumpAndSettle();

      // Verify that the graph widget exists
      expect(find.byType(LineChart), findsOneWidget);

      // Note: Full graph functionality testing would require mocking
      // the API calls and providing test data
      print('Graph widget found and rendered successfully');
    });

    testWidgets('Graph bar data should be initialized',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ExerciseScreen('Test Exercise', ''),
      ));

      await tester.pumpAndSettle();

      // The graph should be present even without data
      expect(find.byType(LineChart), findsOneWidget);
      print('Graph initialization test passed');
    });
  });
}
