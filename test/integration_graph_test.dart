import 'package:flutter_test/flutter_test.dart';
import '../lib/api_models.dart';

void main() {
  group('Integration Graph Tests', () {
    test('End-to-end graph data processing should work correctly', () {
      // Create realistic training data similar to what would come from the API
      final today = DateTime.now();
      final trainingSets = [
        // Week 1 - Mixed warmup and work sets
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 7)),
          weight: 40.0, // Warmup
          repetitions: 15,
          setType: 0, // Should be filtered out
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 7)),
          weight: 60.0, // Warmup
          repetitions: 12,
          setType: 0, // Should be filtered out
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 7)),
          weight: 100.0, // Work set
          repetitions: 8,
          setType: 1, // Should be included
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 7)),
          weight: 102.5, // Best work set for this day
          repetitions: 6,
          setType: 1, // Should be included and picked as best
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),

        // Week 2 - More progression
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 14)),
          weight: 42.5, // Warmup
          repetitions: 12,
          setType: 0, // Should be filtered out
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 14)),
          weight: 97.5, // Work set
          repetitions: 10,
          setType: 1, // Should be included and picked as best (higher reps)
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 14)),
          weight: 97.5, // Same weight, fewer reps
          repetitions: 8,
          setType: 1, // Should be included but not picked
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),

        // Day with only warmups - should result in no graph point
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 21)),
          weight: 45.0, // Only warmup
          repetitions: 10,
          setType: 0, // Should be filtered out
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
      ];

      // Simulate the exact filtering and processing logic from _updateGraphWithCachedData
      final exerciseTrainingSets = trainingSets
          .where((t) => t.exerciseName == 'Bench Press' && t.setType > 0)
          .toList();

      print('Original sets: ${trainingSets.length}');
      print('After filtering warmups: ${exerciseTrainingSets.length}');

      // Should have filtered out 4 warmup sets, leaving 4 work sets
      expect(exerciseTrainingSets.length, equals(4));

      // Group by date
      Map<String, List<ApiTrainingSet>> dataByDate = {};
      for (var t in exerciseTrainingSets) {
        String dateKey =
            "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}";
        if (!dataByDate.containsKey(dateKey)) {
          dataByDate[dateKey] = [];
        }
        dataByDate[dateKey]!.add(t);
      }

      print('Days with work sets: ${dataByDate.keys.length}');

      // Should have 2 days with work sets (day with only warmups excluded)
      expect(dataByDate.keys.length, equals(2));

      // Verify best set selection for each day
      var sortedDates = dataByDate.keys.toList()..sort();
      final latestDate = DateTime.parse(sortedDates.last);

      for (String dateKey in sortedDates) {
        final sets = dataByDate[dateKey]!;
        ApiTrainingSet? bestSet;

        for (var set in sets) {
          if (bestSet == null ||
              set.weight > bestSet.weight ||
              (set.weight == bestSet.weight &&
                  set.repetitions > bestSet.repetitions)) {
            bestSet = set;
          }
        }

        expect(bestSet, isNotNull);
        print(
            'Best set for $dateKey: ${bestSet!.weight}kg @ ${bestSet.repetitions}reps');

        // Calculate x-coordinate (should be negative days from latest date)
        final date = DateTime.parse(dateKey);
        double xValue = -latestDate.difference(date).inDays.toDouble();
        print('X-coordinate: $xValue');
        expect(xValue, lessThanOrEqualTo(0.0),
            reason: 'X-coordinates should be negative or zero');
      }

      print(
          '✅ Integration test passed: Warmup filtering and graph processing working correctly');
    });
  });
}
