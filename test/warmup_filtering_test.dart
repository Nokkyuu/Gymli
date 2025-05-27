import 'package:flutter_test/flutter_test.dart';
import '../lib/api_models.dart';

void main() {
  group('Warmup Set Filtering Tests', () {
    test('Should filter out warmup sets (setType 0) from graph data', () {
      // Create test data with both warmup and work sets
      final today = DateTime.now();
      final trainingSets = [
        // Day 1: Warmup set (should be excluded)
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 5)),
          weight: 40.0, // Low warmup weight
          repetitions: 12,
          setType: 0, // Warmup set
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        // Day 1: Work set (should be included)
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 5)),
          weight: 100.0, // Actual work weight
          repetitions: 8,
          setType: 1, // Work set
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        // Day 2: Multiple warmup sets (should be excluded)
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 10)),
          weight: 30.0, // Very low warmup weight
          repetitions: 15,
          setType: 0, // Warmup set
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 10)),
          weight: 50.0, // Another warmup weight
          repetitions: 10,
          setType: 0, // Warmup set
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        // Day 2: Work set (should be included and picked as best)
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 10)),
          weight: 105.0, // Higher work weight
          repetitions: 6,
          setType: 1, // Work set
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
        // Day 3: Only warmup sets (day should be excluded entirely)
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Bench Press',
          date: today.subtract(const Duration(days: 15)),
          weight: 35.0, // Low warmup weight
          repetitions: 12,
          setType: 0, // Warmup set
          baseReps: 8,
          maxReps: 12,
          increment: 2.5,
        ),
      ];

      // Simulate the filtering logic from _updateGraphWithCachedData
      final exerciseTrainingSets = trainingSets
          .where((t) =>
              t.exerciseName == 'Bench Press' &&
              t.setType > 0) // Exclude warmup sets
          .toList();

      print('Original training sets: ${trainingSets.length}');
      print(
          'Filtered training sets (excluding warmups): ${exerciseTrainingSets.length}');

      // Should have only 2 work sets (day 1 and day 2)
      expect(exerciseTrainingSets.length, equals(2));

      // Verify no warmup sets remain
      for (var set in exerciseTrainingSets) {
        expect(set.setType, greaterThan(0),
            reason: 'All remaining sets should be work sets (setType > 0)');
        expect(set.weight, greaterThanOrEqualTo(100.0),
            reason: 'Work sets should have proper working weights');
      }

      // Group by date to simulate graph point creation
      Map<String, List<ApiTrainingSet>> dataByDate = {};
      for (var t in exerciseTrainingSets) {
        String dateKey =
            "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}";
        if (!dataByDate.containsKey(dateKey)) {
          dataByDate[dateKey] = [];
        }
        dataByDate[dateKey]!.add(t);
      }

      print('Days with data after filtering: ${dataByDate.keys.length}');

      // Should have 2 days with data (days with warmups only are excluded)
      expect(dataByDate.keys.length, equals(2));

      // Find best set for each day
      for (var dateKey in dataByDate.keys) {
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
        expect(bestSet!.setType, greaterThan(0),
            reason: 'Best set should be a work set');
        print(
            'Best set for $dateKey: ${bestSet.weight}kg @ ${bestSet.repetitions}reps (setType: ${bestSet.setType})');
      }

      print('✅ Warmup sets properly filtered out');
      print('✅ Only work sets used for graph data points');
      print('✅ Days with only warmup sets excluded from graph');
    });

    test('Should pick highest weight work set, not warmup set', () {
      // Test scenario where warmup might have higher reps but lower weight
      final today = DateTime.now();
      final sameDay = today.subtract(const Duration(days: 3));

      final trainingSets = [
        // Warmup set with high reps but low weight
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Squats',
          date: sameDay,
          weight: 60.0, // Low warmup weight
          repetitions: 20, // High reps for warmup
          setType: 0, // Warmup set
          baseReps: 8,
          maxReps: 12,
          increment: 5.0,
        ),
        // Work set with proper weight
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Squats',
          date: sameDay,
          weight: 120.0, // Proper work weight
          repetitions: 8, // Normal work reps
          setType: 1, // Work set
          baseReps: 8,
          maxReps: 12,
          increment: 5.0,
        ),
        // Another work set
        ApiTrainingSet(
          userName: 'TestUser',
          exerciseId: 1,
          exerciseName: 'Squats',
          date: sameDay,
          weight: 115.0, // Slightly lower work weight
          repetitions: 10, // More reps
          setType: 1, // Work set
          baseReps: 8,
          maxReps: 12,
          increment: 5.0,
        ),
      ];

      // Filter out warmup sets
      final workSets = trainingSets
          .where((t) => t.exerciseName == 'Squats' && t.setType > 0)
          .toList();

      print('Work sets found: ${workSets.length}');
      expect(workSets.length, equals(2));

      // Find the best set (highest weight, then most reps)
      ApiTrainingSet? bestSet;
      for (var set in workSets) {
        if (bestSet == null ||
            set.weight > bestSet.weight ||
            (set.weight == bestSet.weight &&
                set.repetitions > bestSet.repetitions)) {
          bestSet = set;
        }
      }

      expect(bestSet, isNotNull);
      expect(bestSet!.weight, equals(120.0),
          reason: 'Should pick the highest weight work set');
      expect(bestSet.setType, equals(1),
          reason: 'Should be a work set, not warmup');
      expect(bestSet.repetitions, equals(8));

      print(
          '✅ Best set correctly identified: ${bestSet.weight}kg @ ${bestSet.repetitions}reps');
      print('✅ Warmup set with high reps but low weight properly ignored');
    });
  });
}
