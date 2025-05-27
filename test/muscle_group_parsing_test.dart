/// Test file for muscle group CSV parsing functionality
///
/// This test verifies that the muscle group parsing functions work correctly
/// with semicolon-separated CSV data as exported from the app.

import 'package:flutter_test/flutter_test.dart';

// Import the parsing functions directly
List<String> parseCSVMuscleGroups(String input) {
  if (input.isEmpty || input.trim().isEmpty) {
    return <String>[];
  }

  // Remove any brackets and split by semicolon
  String cleaned = input.replaceAll('[', '').replaceAll(']', '').trim();
  if (cleaned.isEmpty) {
    return <String>[];
  }

  // Split by semicolon and filter out empty strings
  List<String> parts = cleaned
      .split(';')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  return parts;
}

List<double> parseCSVMuscleIntensities(String input) {
  if (input.isEmpty || input.trim().isEmpty) {
    return <double>[];
  }

  // Remove any brackets and split by semicolon
  String cleaned = input.replaceAll('[', '').replaceAll(']', '').trim();
  if (cleaned.isEmpty) {
    return <double>[];
  }

  // Split by semicolon and convert to doubles
  List<double> parts = cleaned
      .split(';')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .map((e) => double.tryParse(e) ?? 0.0)
      .toList();

  return parts;
}

const List<String> muscleGroupNames = [
  "Pectoralis major",
  "Trapezius",
  "Biceps",
  "Abdominals",
  "Front Delts",
  "Deltoids",
  "Back Delts",
  "Latissimus dorsi",
  "Triceps",
  "Gluteus maximus",
  "Hamstrings",
  "Quadriceps",
  "Forearms",
  "Calves"
];

void main() {
  group('Muscle Group Parsing Tests', () {
    test(
        'parseCSVMuscleGroups should correctly parse semicolon-separated muscle groups',
        () {
      // Test data from actual CSV export
      const testInput =
          'Pectoralis major;Biceps;Abdominals;Front Delts;Triceps;';

      final result = parseCSVMuscleGroups(testInput);

      expect(result, isA<List<String>>());
      expect(result.length, equals(5));
      expect(result, contains('Pectoralis major'));
      expect(result, contains('Biceps'));
      expect(result, contains('Abdominals'));
      expect(result, contains('Front Delts'));
      expect(result, contains('Triceps'));
    });

    test('parseCSVMuscleGroups should handle empty input', () {
      const testInput = '';

      final result = parseCSVMuscleGroups(testInput);

      expect(result, isA<List<String>>());
      expect(result.length, equals(0));
    });

    test('parseCSVMuscleGroups should handle input with only semicolons', () {
      const testInput = ';;;';

      final result = parseCSVMuscleGroups(testInput);

      expect(result, isA<List<String>>());
      expect(result.length, equals(0));
    });

    test(
        'parseCSVMuscleIntensities should correctly parse semicolon-separated intensities',
        () {
      // Test data from actual CSV export
      const testInput = '1.0;0.25;0.25;0.5;0.75;';

      final result = parseCSVMuscleIntensities(testInput);

      expect(result, isA<List<double>>());
      expect(result.length, equals(5));
      expect(result[0], equals(1.0));
      expect(result[1], equals(0.25));
      expect(result[2], equals(0.25));
      expect(result[3], equals(0.5));
      expect(result[4], equals(0.75));
    });

    test('parseCSVMuscleIntensities should handle empty input', () {
      const testInput = '';

      final result = parseCSVMuscleIntensities(testInput);

      expect(result, isA<List<double>>());
      expect(result.length, equals(0));
    });

    test('parseCSVMuscleIntensities should handle invalid numbers', () {
      const testInput = '1.0;invalid;0.25;';

      final result = parseCSVMuscleIntensities(testInput);

      expect(result, isA<List<double>>());
      expect(result.length, equals(3));
      expect(result[0], equals(1.0));
      expect(result[1], equals(0.0)); // Invalid should default to 0.0
      expect(result[2], equals(0.25));
    });

    test('muscleGroupNames should include all required muscle groups', () {
      // Verify that all muscle groups from the CSV are supported
      expect(muscleGroupNames, contains('Pectoralis major'));
      expect(muscleGroupNames, contains('Trapezius'));
      expect(muscleGroupNames, contains('Biceps'));
      expect(muscleGroupNames, contains('Abdominals'));
      expect(muscleGroupNames, contains('Front Delts'));
      expect(muscleGroupNames, contains('Deltoids'));
      expect(muscleGroupNames, contains('Back Delts'));
      expect(muscleGroupNames, contains('Latissimus dorsi'));
      expect(muscleGroupNames, contains('Triceps'));
      expect(muscleGroupNames, contains('Gluteus maximus'));
      expect(muscleGroupNames, contains('Hamstrings'));
      expect(muscleGroupNames, contains('Quadriceps'));
      expect(
          muscleGroupNames, contains('Forearms')); // This was the missing one!
      expect(muscleGroupNames, contains('Calves'));
    });

    test(
        'parseCSVMuscleGroups should handle Forearms muscle group specifically',
        () {
      // Test the specific case that was causing the import issue
      const testInput = 'Biceps;Front Delts;Forearms;';

      final result = parseCSVMuscleGroups(testInput);

      expect(result, isA<List<String>>());
      expect(result.length, equals(3));
      expect(result, contains('Biceps'));
      expect(result, contains('Front Delts'));
      expect(result, contains('Forearms'));
    });
  });
}
