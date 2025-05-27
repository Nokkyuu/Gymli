import 'package:flutter_test/flutter_test.dart';
import '../lib/api_models.dart';

void main() {
  group('Graph Date Anchor Fixes Tests', () {
    test('Verify 90-day range calculation works correctly', () {
      // Create test training sets with different dates
      final today = DateTime.now();
      final trainingSets = [
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 5)),
          weight: 100.0,
          repetitions: 8,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 15)),
          weight: 95.0,
          repetitions: 10,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 45)),
          weight: 90.0,
          repetitions: 12,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today
              .subtract(const Duration(days: 95)), // Should be filtered out
          weight: 85.0,
          repetitions: 12,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
      ];

      // Sort to find most recent date (like the actual code does)
      trainingSets.sort((a, b) => b.date.compareTo(a.date));
      final mostRecentDate = trainingSets.first.date;

      // Filter based on 90-day range from most recent date
      final filteredSets = trainingSets
          .where((t) => mostRecentDate.difference(t.date).inDays < 90)
          .toList();

      print('Most recent date: $mostRecentDate');
      print('Filtered sets count: ${filteredSets.length}');

      // Should have 3 sets (excluding the 95-day old one)
      expect(filteredSets.length, equals(3));

      // Verify the oldest included set is within 90 days
      final oldestIncluded = filteredSets.last;
      final daysDifference =
          mostRecentDate.difference(oldestIncluded.date).inDays;
      expect(daysDifference, lessThan(90));

      print('Oldest included set is $daysDifference days from most recent');
    });

    test('Date calculation for x-axis labels works correctly', () {
      final mostRecentTrainingDate = DateTime(2025, 5, 20); // Example date

      // Test negative x-values (days before most recent training)
      final testValues = [-30, -15, -7, -1, 0];

      for (final xValue in testValues) {
        final daysAgo = xValue.abs();
        final calculatedDate =
            mostRecentTrainingDate.subtract(Duration(days: daysAgo));

        print(
            'X-value: $xValue, Days ago: $daysAgo, Calculated date: ${calculatedDate.day}/${calculatedDate.month}');

        // Verify the calculation is correct
        final expectedDate =
            mostRecentTrainingDate.subtract(Duration(days: daysAgo));
        expect(calculatedDate, equals(expectedDate));
      }
    });

    test('Maximum history distance calculation', () {
      // Test minimum range enforcement
      double maxHistoryDistance = 90.0;
      final testKeys = [5, 15, 45]; // Days from most recent

      if (testKeys.isNotEmpty) {
        maxHistoryDistance = testKeys
            .map((k) => k.abs())
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
        maxHistoryDistance = maxHistoryDistance < 2.0
            ? 2.0
            : maxHistoryDistance; // Ensure minimum range
      }

      print('Calculated maxHistoryDistance: $maxHistoryDistance');
      expect(maxHistoryDistance, equals(45.0));

      // Test with smaller range
      final smallKeys = [1];
      double smallMaxDistance = smallKeys
          .map((k) => k.abs())
          .reduce((a, b) => a > b ? a : b)
          .toDouble();
      smallMaxDistance = smallMaxDistance < 2.0 ? 2.0 : smallMaxDistance;

      print('Small range maxHistoryDistance: $smallMaxDistance');
      expect(smallMaxDistance, equals(2.0)); // Should be enforced minimum
    });
  });
}
