class WorkoutUnit {
  final int? id;
  //final String userName;
  final int workoutId;
  final int exerciseId;
  String exerciseName; // For compatibility
  final int warmups;
  final int worksets;
  final int dropsets; // Might need to be added to API
  final int type;

  WorkoutUnit({
    this.id,
    //required this.userName,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.warmups,
    required this.worksets,
    this.dropsets = 0,
    required this.type,
  });

  factory WorkoutUnit.fromJson(Map<String, dynamic> json) {
    return WorkoutUnit(
      id: json['id'],
      //userName: json['user_name'] ?? '',
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
      //'user_name': userName,
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

class Workout {
  final int? id;
  //final String userName;
  final String name;
  List<WorkoutUnit> units;

  Workout({
    this.id,
    // required this.userName,
    required this.name,
    required this.units,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      // userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      units: (json['units'] as List<dynamic>? ?? [])
          .map((unit) => WorkoutUnit.fromJson(unit))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      //'user_name': userName,
      'name': name,
      'units': units.map((unit) => unit.toJson()).toList(),
    };
  }

  List<String> toCSVString() {
    List<String> row = [name];
    for (WorkoutUnit unit in units) {
      row.add(
          "${unit.exerciseName}, ${unit.warmups}, ${unit.worksets}, ${unit.dropsets}, ${unit.type}");
    }
    return row;
  }
}
