/// Data Models for Gymli Application
library;

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

class Exercise {
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

  Exercise({
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

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
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
    // Remove muscle group names entirely - just export the 14 intensity values as comma-separated
    String intensitiesString = muscleIntensities.join(',');

    return [
      name,
      "$type",
      intensitiesString, // Only the intensity values, no names needed
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
class TrainingSet {
  final int? id;
  final String userName;
  final int exerciseId;
  final String exerciseName; // For compatibility
  final DateTime date;
  final double weight;
  final int repetitions;
  final int setType;
  final String? phase;
  final bool? myoreps;
  // final int baseReps;
  // final int maxReps;
  // final double increment;
  // final String? machineName;

  TrainingSet({
    this.id,
    required this.userName,
    required this.exerciseId,
    required this.exerciseName,
    required this.date,
    required this.weight,
    required this.repetitions,
    required this.setType,
    this.phase,
    this.myoreps,
    // required this.baseReps,
    // required this.maxReps,
    // required this.increment,
    // this.machineName,
  });

  factory TrainingSet.fromJson(Map<String, dynamic> json) {
    return TrainingSet(
        id: json['id'],
        userName: json['user_name'] ?? '',
        exerciseId: json['exercise_id'] ?? 0,
        exerciseName: json['exercise_name'] ?? '', // Fallback if not provided
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        weight: (json['weight'] ?? 0.0).toDouble(),
        repetitions: json['repetitions'] ?? 0,
        setType: json['set_type'] ?? 0,
        phase: json['phase'], // Optional, can be null
        myoreps: json['myoreps'] // Optional, can be null
        // baseReps: json['base_reps'] ?? 8,
        // maxReps: json['max_reps'] ?? 12,
        // increment: (json['increment'] ?? 0.0).toDouble(),
        // machineName: json['machine_name'],
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
      'phase': phase,
      'myoreps': myoreps,
      // 'base_reps': baseReps,
      // 'max_reps': maxReps,
      // 'increment': increment,
      // 'machine_name': machineName,
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
      phase ?? "", // Add phase column (empty string if null)
      myoreps?.toString() ?? "", // Add myoreps column (empty string if null)
      // "$baseReps",
      // "$maxReps",
      // "$increment",
      // machineName ?? ""
    ];
  }
}

/// ApiWorkoutUnit - Represents a unit of workout consisting of an exercise and its set details
///
/// Contains information about the exercise performed, including the number of warm-up,
/// work, and drop sets, as well as the type of the workout unit.
class WorkoutUnit {
  final int? id;
  final String userName;
  final int workoutId;
  final int exerciseId;
  String exerciseName; // For compatibility
  final int warmups;
  final int worksets;
  final int dropsets; // Might need to be added to API
  final int type;

  WorkoutUnit({
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

  factory WorkoutUnit.fromJson(Map<String, dynamic> json) {
    return WorkoutUnit(
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
class Workout {
  final int? id;
  final String userName;
  final String name;
  List<WorkoutUnit> units;

  Workout({
    this.id,
    required this.userName,
    required this.name,
    required this.units,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      units: (json['units'] as List<dynamic>? ?? [])
          .map((unit) => WorkoutUnit.fromJson(unit))
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
    for (WorkoutUnit unit in units) {
      row.add(
          "${unit.exerciseName}, ${unit.warmups}, ${unit.worksets}, ${unit.dropsets}, ${unit.type}");
    }
    return row;
  }
}

class Activity {
  final int? id;
  final String userName;
  final String name;
  final double kcalPerHour;

  Activity({
    this.id,
    required this.userName,
    required this.name,
    required this.kcalPerHour,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      kcalPerHour: (json['kcal_per_hour'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'name': name,
      'kcal_per_hour': kcalPerHour,
    };
  }
}

/// ApiActivityLog - Represents a logged activity session
///
/// Contains details about an activity session including duration and calculated calories
class ActivityLog {
  final int? id;
  final String userName;
  final String activityName;
  final DateTime date;
  final int durationMinutes;
  final double caloriesBurned;
  final String? notes;

  ActivityLog({
    this.id,
    required this.userName,
    required this.activityName,
    required this.date,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.notes,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      userName: json['user_name'] ?? '',
      activityName: json['activity_name'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      durationMinutes: json['duration_minutes'] ?? 0,
      caloriesBurned: (json['calories_burned'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'activity_name': activityName,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'notes': notes,
    };
  }

  List<String> toCSVString() {
    return [
      activityName,
      date.toString(),
      "$durationMinutes",
      "$caloriesBurned",
      notes ?? ""
    ];
  }
}

class FoodItem {
  final int? id;
  final String userName;
  final String name;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String? notes;

  FoodItem({
    this.id,
    required this.userName,
    required this.name,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.notes,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      kcalPer100g: (json['kcal_per_100g'] ?? 0.0).toDouble(),
      proteinPer100g: (json['protein_per_100g'] ?? 0.0).toDouble(),
      carbsPer100g: (json['carbs_per_100g'] ?? 0.0).toDouble(),
      fatPer100g: (json['fat_per_100g'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'name': name,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'notes': notes,
    };
  }

  List<String> toCSVString() {
    return [
      name,
      kcalPer100g.toString(),
      proteinPer100g.toString(),
      carbsPer100g.toString(),
      fatPer100g.toString(),
      notes ?? '',
    ];
  }
}

class FoodLog {
  final int? id;
  final String userName;
  final String foodName;
  final DateTime date;
  final double grams;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  FoodLog({
    this.id,
    required this.userName,
    required this.foodName,
    required this.date,
    required this.grams,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['id'],
      userName: json['user_name'] ?? '',
      foodName: json['food_name'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      grams: (json['grams'] ?? 0.0).toDouble(),
      kcalPer100g: (json['kcal_per_100g'] ?? 0.0).toDouble(),
      proteinPer100g: (json['protein_per_100g'] ?? 0.0).toDouble(),
      carbsPer100g: (json['carbs_per_100g'] ?? 0.0).toDouble(),
      fatPer100g: (json['fat_per_100g'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'food_name': foodName,
      'date': date.toIso8601String(),
      'grams': grams,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
    };
  }
}

enum PeriodType {
  cut('cut'),
  bulk('bulk'),
  other('other');

  const PeriodType(this.value);

  final String value;

  static PeriodType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cut':
        return PeriodType.cut;
      case 'bulk':
        return PeriodType.bulk;
      case 'other':
      default:
        return PeriodType.other;
    }
  }

  String get displayName {
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class CalendarPeriod {
  final int? id;
  final String userName;
  final PeriodType type; // Changed from String to enum
  final DateTime startDate;
  final DateTime endDate;

  CalendarPeriod({
    this.id,
    required this.userName,
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  factory CalendarPeriod.fromJson(Map<String, dynamic> json) => CalendarPeriod(
        id: json['id'],
        userName: json['user_name'],
        type: PeriodType.fromString(json['type']),
        startDate: DateTime.parse(json['start_date']),
        endDate: DateTime.parse(json['end_date']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_name': userName,
        'type': type.value,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };

  // Add helper methods from CalendarPeriod
  bool containsDate(DateTime date) {
    return !date.isBefore(startDate) && !date.isAfter(endDate);
  }

  bool overlaps(CalendarPeriod other) {
    return startDate.isBefore(other.endDate) &&
        endDate.isAfter(other.startDate);
  }

  CalendarPeriod copyWith({
    int? id,
    String? userName,
    PeriodType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CalendarPeriod(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  // Getters for backward compatibility with CalendarPeriod
  DateTime get start => startDate;
  DateTime get end => endDate;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarPeriod &&
        other.id == id &&
        other.userName == userName &&
        other.type == type &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      userName.hashCode ^
      type.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;

  @override
  String toString() =>
      'ApiPeriod(id: $id, userName: $userName, type: $type, startDate: $startDate, endDate: $endDate)';
}

class CalendarNote {
  final int? id;
  final String userName;
  final DateTime date;
  final String note;

  CalendarNote({
    this.id,
    required this.userName,
    required this.date,
    required this.note,
  });

  factory CalendarNote.fromJson(Map<String, dynamic> json) => CalendarNote(
        id: json['id'],
        userName: json['user_name'],
        date: DateTime.parse(json['date']),
        note: json['note'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_name': userName,
        'date': date.toIso8601String(),
        'note': note,
      };

  // Add methods from CalendarNote
  CalendarNote copyWith({
    int? id,
    String? userName,
    DateTime? date,
    String? note,
  }) {
    return CalendarNote(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarNote &&
        other.id == id &&
        other.userName == userName &&
        other.date == date &&
        other.note == note;
  }

  @override
  int get hashCode =>
      id.hashCode ^ userName.hashCode ^ date.hashCode ^ note.hashCode;

  @override
  String toString() =>
      'ApiCalendarNote(id: $id, userName: $userName, date: $date, note: $note)';
}

class CalendarWorkout {
  final int? id;
  final String userName;
  final DateTime date;
  final String workout;

  CalendarWorkout({
    this.id,
    required this.userName,
    required this.date,
    required this.workout,
  });

  factory CalendarWorkout.fromJson(Map<String, dynamic> json) =>
      CalendarWorkout(
        id: json['id'],
        userName: json['user_name'],
        date: DateTime.parse(json['date']),
        workout: json['workout'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_name': userName,
        'date': date.toIso8601String(),
        'workout': workout,
      };

  // Add methods from CalendarWorkout
  CalendarWorkout copyWith({
    int? id,
    String? userName,
    DateTime? date,
    String? workout,
  }) {
    return CalendarWorkout(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      workout: workout ?? this.workout,
    );
  }

  // Getter for backward compatibility
  String get workoutName => workout;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarWorkout &&
        other.id == id &&
        other.userName == userName &&
        other.date == date &&
        other.workout == workout;
  }

  @override
  int get hashCode =>
      id.hashCode ^ userName.hashCode ^ date.hashCode ^ workout.hashCode;

  @override
  String toString() =>
      'ApiCalendarWorkout(id: $id, userName: $userName, date: $date, workout: $workout)';
}
