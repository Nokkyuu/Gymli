class TrainingSet {
  final int? id;
  //final String userName;
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
    //required this.userName,
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
        //userName: json['user_name'] ?? '',
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
      //'user_name': userName,
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
