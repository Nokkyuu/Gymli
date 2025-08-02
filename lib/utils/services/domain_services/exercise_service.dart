import '../../api/api.dart' as api;
import '../data_service.dart';

class ExerciseService {
  final DataService _dataService = DataService();

  // Getters that delegate to DataService
  bool get isLoggedIn => _dataService.isLoggedIn;
  String get userName => _dataService.userName;

  Future<List<dynamic>> getExercises() async {
    return await _dataService.getData(
      'exercises',
      // API call for authenticated users
      () async => await api.ExerciseService().getExercises(userName: userName),
      // Fallback API call for non-authenticated users
      () async =>
          await api.ExerciseService().getExercises(userName: 'DefaultUser'),
    );
  }

  Future<Map<String, dynamic>> createExercise({
    required String name,
    required int type,
    required int defaultRepBase,
    required int defaultRepMax,
    required double defaultIncrement,
    required double pectoralisMajor,
    required double trapezius,
    required double biceps,
    required double abdominals,
    required double frontDelts,
    required double deltoids,
    required double backDelts,
    required double latissimusDorsi,
    required double triceps,
    required double gluteusMaximus,
    required double hamstrings,
    required double quadriceps,
    required double forearms,
    required double calves,
  }) async {
    final exerciseData = {
      'name': name,
      'type': type,
      'default_rep_base': defaultRepBase,
      'default_rep_max': defaultRepMax,
      'default_increment': defaultIncrement,
      'pectoralis_major': pectoralisMajor,
      'trapezius': trapezius,
      'biceps': biceps,
      'abdominals': abdominals,
      'front_delts': frontDelts,
      'deltoids': deltoids,
      'back_delts': backDelts,
      'latissimus_dorsi': latissimusDorsi,
      'triceps': triceps,
      'gluteus_maximus': gluteusMaximus,
      'hamstrings': hamstrings,
      'quadriceps': quadriceps,
      'forearms': forearms,
      'calves': calves,
    };

    return await _dataService.createData(
      'exercises',
      exerciseData,
      () async {
        await api.ExerciseService().createExercise(
          userName: userName,
          name: name,
          type: type,
          defaultRepBase: defaultRepBase,
          defaultRepMax: defaultRepMax,
          defaultIncrement: defaultIncrement,
          pectoralisMajor: pectoralisMajor,
          trapezius: trapezius,
          biceps: biceps,
          abdominals: abdominals,
          frontDelts: frontDelts,
          deltoids: deltoids,
          backDelts: backDelts,
          latissimusDorsi: latissimusDorsi,
          triceps: triceps,
          gluteusMaximus: gluteusMaximus,
          hamstrings: hamstrings,
          quadriceps: quadriceps,
          forearms: forearms,
          calves: calves,
        );
        // Return the exercise data since API create might not return it
        return {
          'id': _dataService.generateFakeId('exercises'),
          'user_name': userName,
          ...exerciseData,
        };
      },
    );
  }

  Future<void> updateExercise(int id, Map<String, dynamic> data) async {
    await _dataService.updateData(
      'exercises',
      id,
      data,
      () async => await api.ExerciseService().updateExercise(id, data),
    );
  }

  Future<void> deleteExercise(int id) async {
    await _dataService.deleteData(
      'exercises',
      id,
      () async => await api.ExerciseService().deleteExercise(id),
    );
  }

  // Helper methods for import/export - resolve exercise name to ID
  Future<int?> getExerciseIdByName(String exerciseName) async {
    try {
      final exercises = await getExercises();
      final exerciseData = exercises.firstWhere(
        (item) => item['name'] == exerciseName,
        orElse: () => null,
      );
      return exerciseData?['id'];
    } catch (e) {
      print('Error resolving exercise name to ID: $e');
      return null;
    }
  }

  // Helper method for import/export - resolve exercise ID to name
  Future<String?> getExerciseNameById(int exerciseId) async {
    try {
      final exercises = await getExercises();
      final exerciseData = exercises.firstWhere(
        (item) => item['id'] == exerciseId,
        orElse: () => null,
      );
      return exerciseData?['name'];
    } catch (e) {
      print('Error resolving exercise ID to name: $e');
      return null;
    }
  }

  // Clear method for settings screen
  Future<void> clearExercises() async {
    if (isLoggedIn) {
      // Get all exercises for this user and delete them
      final exercises = await getExercises();
      int deletedCount = 0;
      int errorCount = 0;

      for (var exercise in exercises) {
        if (exercise['id'] != null) {
          try {
            await deleteExercise(exercise['id']);
            deletedCount++;
          } catch (e) {
            errorCount++;
            print('Warning: Failed to delete exercise ${exercise['id']}: $e');
            // Continue with other exercises instead of stopping
          }
        }
      }
      print('Cleared exercises: $deletedCount deleted, $errorCount errors');
    } else {
      // Clear in-memory exercises and clear DefaultUser from API
      _dataService.clearSpecificInMemoryData('exercises');
      try {
        final defaultExercises =
            await api.ExerciseService().getExercises(userName: 'DefaultUser');
        int deletedCount = 0;
        int errorCount = 0;

        for (var exercise in defaultExercises) {
          if (exercise['id'] != null) {
            try {
              await api.ExerciseService().deleteExercise(exercise['id']);
              deletedCount++;
            } catch (e) {
              errorCount++;
              print(
                  'Warning: Failed to delete DefaultUser exercise ${exercise['id']}: $e');
              // Continue with other exercises instead of stopping
            }
          }
        }
        // Clear in-memory exercises regardless of API success
        _dataService.clearSpecificInMemoryData('exercises');
        print(
            'Cleared DefaultUser exercises: $deletedCount deleted, $errorCount errors');
      } catch (e) {
        print('Error accessing DefaultUser exercises: $e');
        // Continue anyway - we still cleared in-memory data
      }
    }
  }
}
