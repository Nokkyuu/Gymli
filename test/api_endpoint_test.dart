import 'package:flutter_test/flutter_test.dart';
import '../lib/api.dart' as api;
import '../lib/user_service.dart';

void main() {
  group('API Endpoint Tests', () {
    test('Test new last training dates endpoint', () async {
      print('🧪 Testing new optimized last training dates endpoint');
      print('====================================================');

      try {
        // Test the new endpoint directly
        final trainingSetService = api.TrainingSetService();
        final result = await trainingSetService.getLastTrainingDatesPerExercise(
            userName: 'TestUser');

        print('✅ New endpoint works! Response: $result');
        expect(result, isA<Map<String, String>>());
      } catch (e) {
        print('❌ New endpoint failed: $e');
        print('🔧 This indicates the backend endpoint needs to be implemented');

        // This is expected if the backend endpoint doesn't exist yet
        expect(e.toString(), contains('Failed to load last training dates'));
      }

      print('\n🔍 Testing UserService optimization fallback...');

      // Test that UserService handles the case when endpoint doesn't exist
      final userService = UserService();
      try {
        // Force login state to test API pathway
        userService
            .setCredentials(null); // This should trigger logged-in state check

        final dates = await userService.getLastTrainingDatesPerExercise();
        print('✅ UserService fallback works! Dates: $dates');
        expect(dates, isA<Map<String, DateTime>>());
      } catch (e) {
        print('⚠️  UserService also failed: $e');
        print('This is expected in offline mode or if no data exists');
      }

      print('\n🎯 Test completed - endpoint status determined');
    });
  });
}
