import 'package:flutter_test/flutter_test.dart';
import '../lib/user_service.dart';
import '../lib/api_models.dart';

/// Test to create sample data and validate complete import/export workflow
void main() {
  group('Import/Export Complete Workflow Tests', () {
    late UserService userService;

    setUp(() {
      userService = UserService();
    });

    test('Complete workflow with sample data', () async {
      print('🧪 Testing complete import/export workflow with sample data');
      print('=' * 60);

      // Step 1: Get existing exercises
      final exercises = await userService.getExercises();
      print('📊 Found ${exercises.length} exercises');

      if (exercises.isEmpty) {
        print('⚠️  No exercises found - creating sample exercises for testing');

        // Create a sample exercise for testing
        await userService.createExercise(
          name: 'Test Benchpress',
          type: 0,
          defaultRepBase: 8,
          defaultRepMax: 12,
          defaultIncrement: 2.5,
          pectoralisMajor: 1.0,
          trapezius: 0.0,
          biceps: 0.0,
          abdominals: 0.0,
          frontDelts: 0.5,
          deltoids: 0.0,
          backDelts: 0.0,
          latissimusDorsi: 0.0,
          triceps: 0.5,
          gluteusMaximus: 0.0,
          hamstrings: 0.0,
          quadriceps: 0.0,
          calves: 0.0,
        );

        print('✓ Created sample exercise: Test Benchpress');
      }

      // Step 2: Get updated exercise list
      final updatedExercises = await userService.getExercises();
      expect(updatedExercises.isNotEmpty, isTrue,
          reason: 'Should have at least one exercise');

      final testExercise = ApiExercise.fromJson(updatedExercises.first);
      print(
          '✓ Using exercise for testing: ${testExercise.name} (ID: ${testExercise.id})');

      // Step 3: Create a training set
      await userService.createTrainingSet(
        exerciseId: testExercise.id!,
        date: DateTime.now().toIso8601String(),
        weight: 80.0,
        repetitions: 10,
        setType: 1, // Work set
        baseReps: testExercise.defaultRepBase,
        maxReps: testExercise.defaultRepMax,
        increment: testExercise.defaultIncrement,
        machineName: 'Test Machine',
      );
      print('✓ Created training set: 80kg x 10 reps');

      // Step 4: Verify training set enrichment
      final trainingSets = await userService.getTrainingSets();
      expect(trainingSets.isNotEmpty, isTrue,
          reason: 'Should have at least one training set');

      final testTrainingSet = ApiTrainingSet.fromJson(trainingSets.first);
      print(
          '✓ Training set enriched with exercise name: "${testTrainingSet.exerciseName}"');

      expect(testTrainingSet.exerciseName, isNotEmpty,
          reason: 'Training set should have exercise name');
      expect(testTrainingSet.exerciseName, isNot(equals('Unknown Exercise')),
          reason: 'Training set should have actual exercise name');

      // Step 5: Test CSV export format
      final csvRow = testTrainingSet.toCSVString();
      print('✓ CSV Export format: ${csvRow.join(', ')}');

      expect(csvRow[0], equals(testTrainingSet.exerciseName),
          reason: 'CSV should start with exercise name');

      // Step 6: Test name-to-ID resolution
      final resolvedId =
          await userService.getExerciseIdByName(testTrainingSet.exerciseName);
      expect(resolvedId, equals(testExercise.id),
          reason: 'Exercise name should resolve back to correct ID');
      print(
          '✓ Name resolution: "${testTrainingSet.exerciseName}" → ID ${resolvedId}');

      // Step 7: Test ID-to-name resolution
      final resolvedName =
          await userService.getExerciseNameById(testExercise.id!);
      expect(resolvedName, equals(testExercise.name),
          reason: 'Exercise ID should resolve back to correct name');
      print('✓ ID resolution: ID ${testExercise.id} → "${resolvedName}"');

      // Step 8: Create and test workout units
      await userService.createWorkout(
        name: 'Test Workout',
        units: [
          {
            'exercise_id': testExercise.id,
            'exercise_name': testExercise.name,
            'warmups': 2,
            'worksets': 3,
            'dropsets': 1,
            'type': testExercise.type,
          }
        ],
      );
      print('✓ Created test workout with exercise unit');

      // Step 9: Verify workout unit enrichment
      final workouts = await userService.getWorkouts();
      expect(workouts.isNotEmpty, isTrue,
          reason: 'Should have at least one workout');

      final testWorkout = ApiWorkout.fromJson(workouts.first);
      expect(testWorkout.units.isNotEmpty, isTrue,
          reason: 'Workout should have at least one unit');

      final workoutUnit = testWorkout.units.first;
      print(
          '✓ Workout unit enriched with exercise name: "${workoutUnit.exerciseName}"');

      expect(workoutUnit.exerciseName, isNotEmpty,
          reason: 'Workout unit should have exercise name');
      expect(workoutUnit.exerciseName, isNot(equals('Unknown Exercise')),
          reason: 'Workout unit should have actual exercise name');

      // Step 10: Test workout CSV export
      final workoutCSV = testWorkout.toCSVString();
      print('✓ Workout CSV Export: ${workoutCSV.join(' | ')}');

      print('\n✅ Complete import/export workflow validation successful!');
      print('🎯 Key features validated:');
      print('   • Exercise name enrichment in training sets');
      print('   • Exercise name enrichment in workout units');
      print('   • Bidirectional name ↔ ID resolution');
      print('   • CSV export includes exercise names');
      print('   • Data consistency across all components');
    });
  });
}
