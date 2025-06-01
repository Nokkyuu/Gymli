/// API Data Models for Gymli Application
///
/// This file contains all the data model classes used for API communication
/// and data storage. It defines the structure of exercises, workouts, training sets,
/// workout units, and groups used throughout the application.
///
/// Key features:
/// - Type-safe data models with validation
/// - JSON serialization/deserialization
/// - Muscle group and exercise type definitions
/// - Comprehensive exercise metadata structure
library;

// ignore_for_file: file_names

// Data models for API-based storage

// Exercise type constants - defines the equipment/method categories
final exerciseTypeNames = ["Free", "Machine", "Cable", "Body"];

// Muscle group names - comprehensive list of targeted muscle groups
final muscleGroupNames = [
  "Pectoralis major", // Chest
  "Trapezius", // Upper back/neck
  "Biceps", // Front of upper arm
  "Abdominals", // Core/abs
  "Front Delts", // Front shoulder
  "Deltoids", // Main shoulder
  "Back Delts", // Rear shoulder
  "Latissimus dorsi", // Back/lats
  "Triceps", // Back of upper arm
  "Gluteus maximus", // Glutes
  "Hamstrings", // Back of thigh
  "Quadriceps", // Front of thigh
  "Forearms", // Lower arm
  "Calves" // Lower leg
];

// Training set type constants - categorizes different set purposes
final setTypeNames = ["Warm", "Work", "Drop"];

/// ApiExercise - Represents an exercise entity with comprehensive metadata
///
/// Contains all information about an exercise including muscle activation
/// percentages, default repetition ranges, and user associations.
class ApiExercise {
  final int? id;
  final String userName;
  final String name;
  final int type;
  final int defaultRepBase;
  final int defaultRepMax;
  final double defaultIncrement;
  final double pectoralisMajor;
  final double trapezius;
  final double biceps;
  final double abdominals;
  final double frontDelts;
  final double deltoids;
  final double backDelts;
  final double latissimusDorsi;
  final double triceps;
  final double gluteusMaximus;
  final double hamstrings;
  final double quadriceps;
  final double forearms;
  final double calves;

  ApiExercise({
    this.id,
    required this.userName,
    required this.name,
    required this.type,
    required this.defaultRepBase,
    required this.defaultRepMax,
    required this.defaultIncrement,
    required this.pectoralisMajor,
    required this.trapezius,
    required this.biceps,
    required this.abdominals,
    required this.frontDelts,
    required this.deltoids,
    required this.backDelts,
    required this.latissimusDorsi,
    required this.triceps,
    required this.gluteusMaximus,
    required this.hamstrings,
    required this.quadriceps,
    required this.forearms,
    required this.calves,
  });

  factory ApiExercise.fromJson(Map<String, dynamic> json) {
    return ApiExercise(
      id: json['id'],
      userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 0,
      defaultRepBase: json['default_rep_base'] ?? 8,
      defaultRepMax: json['default_rep_max'] ?? 12,
      defaultIncrement: (json['default_increment'] ?? 0.0).toDouble(),
      pectoralisMajor: (json['pectoralis_major'] ?? 0.0).toDouble(),
      trapezius: (json['trapezius'] ?? 0.0).toDouble(),
      biceps: (json['biceps'] ?? 0.0).toDouble(),
      abdominals: (json['abdominals'] ?? 0.0).toDouble(),
      frontDelts: (json['front_delts'] ?? 0.0).toDouble(),
      deltoids: (json['deltoids'] ?? 0.0).toDouble(),
      backDelts: (json['back_delts'] ?? 0.0).toDouble(),
      latissimusDorsi: (json['latissimus_dorsi'] ?? 0.0).toDouble(),
      triceps: (json['triceps'] ?? 0.0).toDouble(),
      gluteusMaximus: (json['gluteus_maximus'] ?? 0.0).toDouble(),
      hamstrings: (json['hamstrings'] ?? 0.0).toDouble(),
      quadriceps: (json['quadriceps'] ?? 0.0).toDouble(),
      forearms: (json['forearms'] ?? 0.0).toDouble(),
      calves: (json['calves'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'forearms': forearms,
      'calves': calves,
    };
  }

  // Helper getters for compatibility with old code
  List<String> get muscleGroups {
    List<String> groups = [];
    final intensities = muscleIntensities;
    for (int i = 0;
        i < muscleGroupNames.length && i < intensities.length;
        i++) {
      if (intensities[i] > 0.0) {
        groups.add(muscleGroupNames[i]);
      }
    }
    return groups;
  }

  List<double> get muscleIntensities {
    return [
      pectoralisMajor, trapezius, biceps, abdominals, frontDelts,
      deltoids, backDelts, latissimusDorsi, triceps, gluteusMaximus,
      hamstrings, quadriceps, forearms,
      calves // FIXED: Use actual forearms value
    ];
  }

  List<String> toCSVString() {
    String muscleString = "";
    String intensitiesString = "";
    for (var s in muscleGroups) {
      muscleString += "$s;";
    }
    for (var s in muscleIntensities) {
      intensitiesString += "$s;";
    }
    return [
      name,
      "$type",
      muscleString,
      intensitiesString,
      "$defaultRepBase",
      "$defaultRepMax",
      "$defaultIncrement"
    ];
  }

  // Add this new getter method
  List<String> get primaryMuscleGroups {
    List<String> groups = [];
    final intensities = muscleIntensities;
    for (int i = 0;
        i < muscleGroupNames.length && i < intensities.length;
        i++) {
      if (intensities[i] >= 0.75) {
        // Only include muscles with high intensity
        groups.add(muscleGroupNames[i]);
      }
    }
    return groups;
  }
}

/// ApiTrainingSet - Represents a single training session entry for an exercise
///
/// Contains details about the performance of an exercise in a workout, including
/// weights, repetitions, and set types.
class ApiTrainingSet {
  final int? id;
  final String userName;
  final int exerciseId;
  final String exerciseName; // For compatibility
  final DateTime date;
  final double weight;
  final int repetitions;
  final int setType;
  final int baseReps;
  final int maxReps;
  final double increment;
  final String? machineName;

  ApiTrainingSet({
    this.id,
    required this.userName,
    required this.exerciseId,
    required this.exerciseName,
    required this.date,
    required this.weight,
    required this.repetitions,
    required this.setType,
    required this.baseReps,
    required this.maxReps,
    required this.increment,
    this.machineName,
  });

  factory ApiTrainingSet.fromJson(Map<String, dynamic> json) {
    return ApiTrainingSet(
      id: json['id'],
      userName: json['user_name'] ?? '',
      exerciseId: json['exercise_id'] ?? 0,
      exerciseName: json['exercise_name'] ?? '', // Fallback if not provided
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      weight: (json['weight'] ?? 0.0).toDouble(),
      repetitions: json['repetitions'] ?? 0,
      setType: json['set_type'] ?? 0,
      baseReps: json['base_reps'] ?? 8,
      maxReps: json['max_reps'] ?? 12,
      increment: (json['increment'] ?? 0.0).toDouble(),
      machineName: json['machine_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'exercise_id': exerciseId,
      'date': date.toIso8601String(),
      'weight': weight,
      'repetitions': repetitions,
      'set_type': setType,
      'base_reps': baseReps,
      'max_reps': maxReps,
      'increment': increment,
      'machine_name': machineName,
    };
  }

  // Getter for backward compatibility
  String get exercise => exerciseName;

  List<String> toCSVString() {
    return [
      exerciseName,
      date.toString(),
      "$weight",
      "$repetitions",
      "$setType",
      "$baseReps",
      "$maxReps",
      "$increment",
      machineName ?? ""
    ];
  }
}

/// ApiWorkoutUnit - Represents a unit of workout consisting of an exercise and its set details
///
/// Contains information about the exercise performed, including the number of warm-up,
/// work, and drop sets, as well as the type of the workout unit.
class ApiWorkoutUnit {
  final int? id;
  final String userName;
  final int workoutId;
  final int exerciseId;
  final String exerciseName; // For compatibility
  final int warmups;
  final int worksets;
  final int dropsets; // Might need to be added to API
  final int type;

  ApiWorkoutUnit({
    this.id,
    required this.userName,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.warmups,
    required this.worksets,
    this.dropsets = 0,
    required this.type,
  });

  factory ApiWorkoutUnit.fromJson(Map<String, dynamic> json) {
    return ApiWorkoutUnit(
      id: json['id'],
      userName: json['user_name'] ?? '',
      workoutId: json['workout_id'] ?? 0,
      exerciseId: json['exercise_id'] ?? 0,
      exerciseName: json['exercise_name'] ?? '',
      warmups: json['warmups'] ?? 0,
      worksets: json['worksets'] ?? 0,
      dropsets: json['dropsets'] ?? 0,
      type: json['type'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'warmups': warmups,
      'worksets': worksets,
      'dropsets': dropsets,
      'type': type,
    };
  }

  // Getter for backward compatibility
  String get exercise => exerciseName;
}

/// ApiWorkout - Represents a workout consisting of multiple workout units
///
/// Contains the details of a workout session, including the user, workout name,
/// and the units (exercises) included in the workout.
class ApiWorkout {
  final int? id;
  final String userName;
  final String name;
  final List<ApiWorkoutUnit> units;

  ApiWorkout({
    this.id,
    required this.userName,
    required this.name,
    required this.units,
  });

  factory ApiWorkout.fromJson(Map<String, dynamic> json) {
    return ApiWorkout(
      id: json['id'],
      userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      units: (json['units'] as List<dynamic>? ?? [])
          .map((unit) => ApiWorkoutUnit.fromJson(unit))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'name': name,
      'units': units.map((unit) => unit.toJson()).toList(),
    };
  }

  List<String> toCSVString() {
    List<String> row = [name];
    for (ApiWorkoutUnit unit in units) {
      row.add(
          "${unit.exerciseName}, ${unit.warmups}, ${unit.worksets}, ${unit.dropsets}, ${unit.type}");
    }
    return row;
  }
}

/// ApiGroup - Represents a collection of exercises grouped together
///
/// Contains details about a group of exercises, including the user, group name,
/// and the list of exercises in the group.
class ApiGroup {
  final int? id;
  final String userName;
  final String name;
  final List<String> exercises;

  ApiGroup({
    this.id,
    required this.userName,
    required this.name,
    required this.exercises,
  });

  factory ApiGroup.fromJson(Map<String, dynamic> json) {
    return ApiGroup(
      id: json['id'],
      userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      exercises: List<String>.from(json['exercises'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'name': name,
      'exercises': exercises,
    };
  }
}
