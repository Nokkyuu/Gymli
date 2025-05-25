import 'dart:convert';
import 'package:http/http.dart' as http;

// Main API base URL (update as needed)
const String baseUrl =
    'https://gymliapi-gyg0ardqh5dadaba.germanywestcentral-01.azurewebsites.net/';

//----------------- Animals Service -----------------//

class AnimalService {
  Future<List<dynamic>> getAnimals() async {
    final response = await http.get(Uri.parse('$baseUrl/animals'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load animals');
    }
  }

  Future<Map<String, dynamic>> getAnimalById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/animals/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch animal');
    }
  }

  Future<void> createAnimal(String name, String sound) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animals'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'sound': sound}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create animal');
    }
  }

  Future<void> updateAnimal(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/animals/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update animal');
    }
  }

  Future<void> deleteAnimal(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/animals/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete animal');
    }
  }
}

//----------------- Exercise Service -----------------//

class ExerciseService {
  Future<List<dynamic>> getExercises({required String userName}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/exercises?user_name=$userName'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load exercises');
    }
  }

  Future<Map<String, dynamic>> getExerciseById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/exercises/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch exercise');
    }
  }

  Future<void> createExercise({
    required String userName,
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
    required double calves,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/exercises'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
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
        'calves': calves,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create exercise');
    }
  }

  Future<void> updateExercise(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/exercises/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update exercise');
    }
  }

  Future<void> deleteExercise(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/exercises/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete exercise');
    }
  }
}

//----------------- Workout Service -----------------//

class WorkoutService {
  Future<List<dynamic>> getWorkouts({required String userName}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/workouts?user_name=$userName'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load workouts');
    }
  }

  Future<Map<String, dynamic>> getWorkoutById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/workouts/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch workout');
    }
  }

  Future<void> createWorkout({
    required String userName,
    required String name,
    // Add other required fields as needed
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workouts'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
        'name': name,
        // Add additional fields here
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create workout');
    }
  }

  Future<void> updateWorkout(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workouts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update workout');
    }
  }

  Future<void> deleteWorkout(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/workouts/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete workout');
    }
  }
}

//----------------- Training Set Service -----------------//

class TrainingSetService {
  Future<List<dynamic>> getTrainingSets({required String userName}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/training_sets?user_name=$userName'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load training sets');
    }
  }

  Future<Map<String, dynamic>> getTrainingSetById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/training_sets/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch training set');
    }
  }

  Future<void> createTrainingSet({
    required String userName,
    required int exerciseId,
    required String date,
    required double weight,
    required int repetitions,
    required int setType,
    required int baseReps,
    required int maxReps,
    required double increment,
    String? machineName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/training_sets'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
        'exercise_id': exerciseId,
        'date': date,
        'weight': weight,
        'repetitions': repetitions,
        'set_type': setType,
        'base_reps': baseReps,
        'max_reps': maxReps,
        'increment': increment,
        'machine_name': machineName,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create training set');
    }
  }

  Future<void> updateTrainingSet(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/training_sets/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update training set');
    }
  }

  Future<void> deleteTrainingSet(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/training_sets/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete training set');
    }
  }
}

//----------------- Workout Unit Service -----------------//

class WorkoutUnitService {
  Future<List<dynamic>> getWorkoutUnits({required String userName}) async {
    final response =
        await http.get(Uri.parse('$baseUrl/workout_units?user_name=$userName'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load workout units');
    }
  }

  Future<Map<String, dynamic>> getWorkoutUnitById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/workout_units/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch workout unit');
    }
  }

  Future<void> createWorkoutUnit({
    required String userName,
    required int workoutId,
    required int exerciseId,
    required int warmups,
    required int worksets,
    required int type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workout_units'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': userName,
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'warmups': warmups,
        'worksets': worksets,
        'type': type,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create workout unit');
    }
  }

  Future<void> updateWorkoutUnit(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workout_units/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update workout unit');
    }
  }

  Future<void> deleteWorkoutUnit(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/workout_units/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete workout unit');
    }
  }
}
