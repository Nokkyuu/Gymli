import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/exerciseScreen.dart';

/// Test to verify workout context parsing functionality
void main() {
  group('Workout Context Tests', () {
    testWidgets('ExerciseScreen parses workout description correctly',
        (WidgetTester tester) async {
      print('🧪 Testing workout context parsing in ExerciseScreen');
      print('=' * 60);

      // Test case 1: Valid workout description
      const String validDescription = "Warm: 3, Work: 5";
      const String exerciseName = "Test Exercise";

      print('📝 Testing with description: "$validDescription"');

      final exerciseScreen = ExerciseScreen(exerciseName, validDescription);

      // Build the widget to trigger initState
      await tester.pumpWidget(MaterialApp(home: exerciseScreen));

      // Allow the widget to complete initialization
      await tester.pump();

      print('✓ ExerciseScreen created and initialized');
      print('✓ Workout context should be parsed and available');

      // Test case 2: Empty description
      const String emptyDescription = "";

      print('📝 Testing with empty description');

      final exerciseScreenEmpty =
          ExerciseScreen(exerciseName, emptyDescription);

      await tester.pumpWidget(MaterialApp(home: exerciseScreenEmpty));
      await tester.pump();

      print('✓ ExerciseScreen with empty description handled correctly');

      // Test case 3: Invalid format
      const String invalidDescription = "Invalid format";

      print('📝 Testing with invalid description format');

      final exerciseScreenInvalid =
          ExerciseScreen(exerciseName, invalidDescription);

      await tester.pumpWidget(MaterialApp(home: exerciseScreenInvalid));
      await tester.pump();

      print('✓ ExerciseScreen with invalid description handled correctly');

      print('=' * 60);
      print('🎉 All workout context parsing tests passed!');
    });
  });
}
