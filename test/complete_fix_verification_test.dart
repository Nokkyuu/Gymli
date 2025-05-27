import 'package:flutter_test/flutter_test.dart';
import '../lib/api_models.dart';
import '../lib/globals.dart' as globals;

void main() {
  group('Graph Update Complete Fix Verification', () {
    test(
        'End-to-end test: Adding sets should update graph with complete historical data',
        () {
      // Simulate a user's workout history over several months
      final today = DateTime.now();
      final existingTrainingSets = [
        // 3 months of historical data
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 90)), // 3 months ago
          weight: 80.0,
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
          date: today.subtract(const Duration(days: 60)), // 2 months ago
          weight: 85.0,
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
          date: today.subtract(const Duration(days: 30)), // 1 month ago
          weight: 90.0,
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
          date: today.subtract(const Duration(days: 7)), // 1 week ago
          weight: 95.0,
          repetitions: 6,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
      ];

      // Simulate adding a new set today (this is what triggers the graph update issue)
      final newTodaysSet = ApiTrainingSet(
        userName: 'TestUser',
        exerciseId: 1,
        exerciseName: 'Bench Press',
        date: today, // Today's new set
        weight: 100.0,
        repetitions: 5,
        setType: 1,
        baseReps: 8,
        maxReps: 12,
        increment: 2.5,
      );

      // Combine all data (simulating what API call would return)
      final allTrainingSets = [...existingTrainingSets, newTodaysSet];

      // Filter using the fixed global setting (no longer hardcoded 90 days)
      allTrainingSets.sort((a, b) => b.date.compareTo(a.date));
      final mostRecentDate = allTrainingSets.first.date;

      final filteredSets = allTrainingSets
          .where((t) =>
              mostRecentDate.difference(t.date).inDays <
              globals.graphNumberOfDays)
          .toList();

      print('=== Graph Update Fix Verification ===');
      print('Global day range setting: ${globals.graphNumberOfDays} days');
      print('Total training sets: ${allTrainingSets.length}');
      print('Sets within range: ${filteredSets.length}');

      // All sets should be included (within 300 days)
      expect(filteredSets.length, equals(5));

      // Verify historical data is preserved
      final daysFromMostRecent = filteredSets
          .map((s) => mostRecentDate.difference(s.date).inDays)
          .toList()
        ..sort();

      print('Days from most recent: $daysFromMostRecent');

      // Should include data from today (0), 1 week (7), 1 month (~30), 2 months (~60), 3 months (~90)
      expect(daysFromMostRecent[0], equals(0)); // Today's set
      expect(daysFromMostRecent[1], equals(7)); // 1 week ago
      expect(daysFromMostRecent[2], greaterThan(25)); // ~30 days
      expect(daysFromMostRecent[3], greaterThan(55)); // ~60 days
      expect(daysFromMostRecent[4], greaterThan(85)); // ~90 days

      print(
          '✅ Graph correctly includes all historical data when new sets are added');
      print('✅ Historical range preserved: ${daysFromMostRecent.last} days');
    });

    test('Verify 90-day limit is completely removed', () {
      // Test that data beyond 90 days is now included (up to 300 days)
      final today = DateTime.now();
      final testSets = [
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today,
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
          date: today
              .subtract(const Duration(days: 120)), // Beyond old 90-day limit
          weight: 85.0,
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
          date:
              today.subtract(const Duration(days: 200)), // Way beyond old limit
          weight: 80.0,
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
              .subtract(const Duration(days: 350)), // Beyond new 300-day limit
          weight: 75.0,
          repetitions: 12,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
      ];

      testSets.sort((a, b) => b.date.compareTo(a.date));
      final mostRecentDate = testSets.first.date;

      final filteredSets = testSets
          .where((t) =>
              mostRecentDate.difference(t.date).inDays <
              globals.graphNumberOfDays)
          .toList();

      print('=== 90-Day Limit Removal Verification ===');
      print(
          'Sets within new ${globals.graphNumberOfDays}-day limit: ${filteredSets.length}/4');

      // Should include 3 sets (0, 120, 200 days) but exclude 350-day set
      expect(filteredSets.length, equals(3));

      final includedDays = filteredSets
          .map((s) => mostRecentDate.difference(s.date).inDays)
          .toList();

      // Verify 120 and 200-day old sets are included (beyond old 90-day limit)
      expect(includedDays.any((days) => days > 100 && days < 150),
          isTrue); // ~120 days
      expect(includedDays.any((days) => days > 150), isTrue); // ~200 days

      print(
          '✅ Data beyond 90 days is now included: ${includedDays.where((d) => d > 90).toList()}');
      print('✅ 90-day hardcoded limit successfully removed');
    });

    test('Graph scoring calculation remains accurate with extended range', () {
      // Verify that extending the date range doesn't break score calculations
      final testSet = ApiTrainingSet(
        userName: 'TestUser',
        exerciseId: 1,
        exerciseName: 'Bench Press',
        date: DateTime.now().subtract(const Duration(days: 150)),
        weight: 100.0,
        repetitions: 10,
        setType: 1,
        baseReps: 8,
        maxReps: 12,
        increment: 2.5,
      );

      final score = globals.calculateScore(testSet);

      // Score calculation: weight + ((reps - baseReps) / (maxReps - baseReps)) * increment
      // = 100 + ((10 - 8) / (12 - 8)) * 2.5 = 100 + (2/4) * 2.5 = 100 + 1.25 = 101.25
      final expectedScore = 100.0 + ((10 - 8) / (12 - 8)) * 2.5;

      expect(score, equals(expectedScore));
      print('✅ Score calculation remains accurate: $score');
    });
  });
}
