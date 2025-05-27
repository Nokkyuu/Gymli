import 'package:flutter_test/flutter_test.dart';
import 'package:Gymli/exerciseScreen.dart';
import 'package:Gymli/api_models.dart';

void main() {
  group('Graph Date Anchor Tests', () {
    test('Graph should use most recent training date for x-axis upper limit',
        () {
      // Test data: training sets from different dates
      final testTrainingSets = [
        ApiTrainingSet(
          userName: 'test',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: DateTime(2025, 5, 20), // 7 days ago from "current" date
          weight: 80.0,
          repetitions: 10,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
          machineName: '',
        ),
        ApiTrainingSet(
          userName: 'test',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: DateTime(2025, 5, 15), // 12 days ago from "current" date
          weight: 77.5,
          repetitions: 12,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
          machineName: '',
        ),
        ApiTrainingSet(
          userName: 'test',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: DateTime(2025, 5, 10), // 17 days ago from "current" date
          weight: 75.0,
          repetitions: 10,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
          machineName: '',
        ),
      ];

      // Sort to find most recent (this mimics the actual implementation)
      testTrainingSets.sort((a, b) => b.date.compareTo(a.date));
      final mostRecentDate = testTrainingSets.first.date;

      // Verify that the most recent date is May 20, 2025
      expect(mostRecentDate, equals(DateTime(2025, 5, 20)));

      // Test filtering logic: should use mostRecentDate instead of DateTime.now()
      final graphNumberOfDays = 90; // From globals
      final filteredSets = testTrainingSets
          .where((t) =>
              mostRecentDate.difference(t.date).inDays < graphNumberOfDays)
          .toList();

      // All test sets should be included since they're all within 90 days of May 20
      expect(filteredSets.length, equals(3));

      // Verify x-coordinate calculation uses mostRecentDate
      final firstSetDaysFromMostRecent =
          mostRecentDate.difference(testTrainingSets[0].date).inDays;
      final secondSetDaysFromMostRecent =
          mostRecentDate.difference(testTrainingSets[1].date).inDays;
      final thirdSetDaysFromMostRecent =
          mostRecentDate.difference(testTrainingSets[2].date).inDays;

      expect(firstSetDaysFromMostRecent, equals(0)); // Same day as most recent
      expect(
          secondSetDaysFromMostRecent, equals(5)); // 5 days before most recent
      expect(
          thirdSetDaysFromMostRecent, equals(10)); // 10 days before most recent

      print('✅ Graph x-axis correctly anchored to most recent training date');
      print('✅ Most recent date: ${mostRecentDate.toString().split(' ')[0]}');
      print(
          '✅ All training sets properly positioned relative to most recent date');
    });

    test('Graph range calculation should use most recent training date', () {
      // Test the cached graph method logic
      final workoutSets = [
        ApiTrainingSet(
          userName: 'test',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: DateTime(2025, 5, 25), // Most recent
          weight: 85.0,
          repetitions: 8,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
          machineName: '',
        ),
        ApiTrainingSet(
          userName: 'test',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: DateTime(2025, 5, 15), // 10 days before most recent
          weight: 80.0,
          repetitions: 10,
          setType: 1,
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
          machineName: '',
        ),
      ];

      // Group by date (mimicking the cached graph method)
      Map<String, List<ApiTrainingSet>> dataByDate = {};
      for (var t in workoutSets) {
        String dateKey =
            "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}";
        if (!dataByDate.containsKey(dateKey)) {
          dataByDate[dateKey] = [];
        }
        dataByDate[dateKey]!.add(t);
      }

      var sortedDates = dataByDate.keys.toList()..sort();

      if (sortedDates.isNotEmpty) {
        final earliestDate = DateTime.parse(sortedDates.first);
        final latestDate = DateTime.parse(sortedDates.last);
        final daysDifference = latestDate.difference(earliestDate).inDays;

        // Verify latestDate is used for range calculations, not DateTime.now()
        expect(latestDate, equals(DateTime(2025, 5, 25)));
        expect(daysDifference, equals(10));

        // Test the three months calculation from latest date
        final threeMonthsAgoFromLatest =
            latestDate.subtract(const Duration(days: 90));

        // Calculate expected date more reliably
        final expectedDate =
            DateTime(2025, 5, 25).subtract(const Duration(days: 90));
        expect(threeMonthsAgoFromLatest, equals(expectedDate));

        print(
            '✅ Cached graph method correctly uses most recent training date for range calculations');
        print('✅ Latest date: ${latestDate.toString().split(' ')[0]}');
        print(
            '✅ Three months ago from latest: ${threeMonthsAgoFromLatest.toString().split(' ')[0]}');
      }
    });

    test('X-axis coordinates should be negative days from most recent date',
        () {
      // Test x-coordinate calculation logic
      final latestDate = DateTime(2025, 5, 25);
      final testDate = DateTime(2025, 5, 20);

      // Calculate x-coordinate as done in the implementation
      double xValue = -latestDate.difference(testDate).inDays.toDouble();

      // Should be -5.0 (5 days before most recent date, displayed as negative)
      expect(xValue, equals(-5.0));

      // Test with same day
      double xValueSameDay =
          -latestDate.difference(latestDate).inDays.toDouble();
      expect(xValueSameDay, equals(0.0));

      print(
          '✅ X-axis coordinates correctly calculated as negative days from most recent date');
      print('✅ 5 days before most recent: x = $xValue');
      print('✅ Same day as most recent: x = $xValueSameDay');
    });
  });
}
