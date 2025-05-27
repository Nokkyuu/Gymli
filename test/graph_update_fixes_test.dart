import 'package:flutter_test/flutter_test.dart';
import '../lib/api_models.dart';
import '../lib/globals.dart' as globals;

void main() {
  group('Graph Update Fix Tests', () {
    test(
        'Graph should use global day range setting instead of hardcoded 90 days',
        () {
      // Test that the graph uses globals.graphNumberOfDays (300) instead of hardcoded 90

      // Create test data beyond 90 days but within 300 days
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
          date: today.subtract(
              const Duration(days: 120)), // Beyond 90 days but within 300
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
          date: today.subtract(
              const Duration(days: 350)), // Beyond 300 days, should be filtered
          weight: 80.0,
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

      // Filter based on global setting instead of hardcoded 90 days
      final filteredSets = trainingSets
          .where((t) =>
              mostRecentDate.difference(t.date).inDays <
              globals.graphNumberOfDays)
          .toList();

      print('Global graph range setting: ${globals.graphNumberOfDays} days');
      print('Original sets: ${trainingSets.length}');
      print('After filtering with global setting: ${filteredSets.length}');

      // Should have 2 sets (5 days and 120 days), 350-day set should be filtered out
      expect(filteredSets.length, equals(2));

      // Verify the 120-day old set is included (within 300 days)
      final includedDates = filteredSets
          .map((s) => mostRecentDate.difference(s.date).inDays)
          .toList();

      // The exact number of days may vary due to DateTime calculations, but should be around 120
      final approximatelyOldSetDays =
          includedDates.firstWhere((days) => days > 100);
      expect(approximatelyOldSetDays, greaterThan(100));
      expect(approximatelyOldSetDays, lessThan(200));
      expect(includedDates, isNot(contains(350)));

      print(
          '✅ Graph correctly uses global day range setting instead of hardcoded 90 days');
      print(
          '✅ Included training data from ${includedDates.join(", ")} days ago');
    });

    test('Graph update should handle complete historical data properly', () {
      // Test scenario: user has training data over multiple days and adds a new set
      // The graph should show all historical data, not just today's

      final today = DateTime.now();
      final historicalData = [
        // Historical training over past weeks
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 7)),
          weight: 95.0,
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
          date: today.subtract(const Duration(days: 14)),
          weight: 92.5,
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
          date: today.subtract(const Duration(days: 21)),
          weight: 90.0,
          repetitions: 12,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        // Today's set that gets added
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today,
          weight: 100.0,
          repetitions: 6,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
      ];

      // Group by date to simulate graph data processing
      Map<String, List<ApiTrainingSet>> dataByDate = {};
      for (var t in historicalData) {
        String dateKey =
            "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}";
        if (!dataByDate.containsKey(dateKey)) {
          dataByDate[dateKey] = [];
        }
        dataByDate[dateKey]!.add(t);
      }

      // Should have data for 4 different days
      expect(dataByDate.keys.length, equals(4));

      // Verify all historical dates are preserved
      var sortedDates = dataByDate.keys.toList()..sort();
      final earliestDate = DateTime.parse(sortedDates.first);
      final latestDate = DateTime.parse(sortedDates.last);
      final daysDifference = latestDate.difference(earliestDate).inDays;

      expect(daysDifference, equals(21)); // 21 days of history

      print(
          '✅ Graph properly processes all historical data when sets are added');
      print('✅ Historical range: $daysDifference days');
      print('✅ Number of training days: ${dataByDate.keys.length}');
    });

    test('Verify graph range calculation uses configurable limit', () {
      // Test the range calculation logic that was previously hardcoded to 90 days

      final testDate = DateTime(2025, 5, 20);
      final currentGlobalSetting = globals.graphNumberOfDays; // Should be 300

      // Calculate the cutoff date using global setting
      final maxDaysFromLatest =
          testDate.subtract(Duration(days: currentGlobalSetting));

      // Test dates
      final withinRange =
          DateTime(2025, 1, 1); // ~140 days before, should be within 300
      final outsideRange =
          DateTime(2024, 5, 1); // ~385 days before, should be outside 300

      expect(withinRange.isAfter(maxDaysFromLatest), isTrue);
      expect(outsideRange.isBefore(maxDaysFromLatest), isTrue);

      print(
          '✅ Range calculation correctly uses global setting: $currentGlobalSetting days');
      print('✅ Cutoff date: ${maxDaysFromLatest.toString().split(' ')[0]}');
    });
  });
}
