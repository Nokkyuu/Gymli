class MuscleGroup {
  static const List<String> names = [
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

  const MuscleGroup({
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

  factory MuscleGroup.fromJson(Map<String, dynamic> json) {
    return MuscleGroup(
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

  /// Get all muscle group intensities as a list
  List<double> get intensities {
    return [
      pectoralisMajor,
      trapezius,
      biceps,
      abdominals,
      frontDelts,
      deltoids,
      backDelts,
      latissimusDorsi,
      triceps,
      gluteusMaximus,
      hamstrings,
      quadriceps,
      forearms,
      calves
    ];
  }

  /// Get names of muscle groups with intensity > 0
  List<String> get activeMuscleGroups {
    List<String> groups = [];
    final intensities = this.intensities;
    for (int i = 0; i < names.length && i < intensities.length; i++) {
      if (intensities[i] > 0.0) {
        groups.add(names[i]);
      }
    }
    return groups;
  }

  /// Get names of muscle groups with intensity >= threshold
  List<String> getPrimaryMuscleGroups({double threshold = 0.75}) {
    List<String> groups = [];
    final intensities = this.intensities;
    for (int i = 0; i < names.length && i < intensities.length; i++) {
      if (intensities[i] >= threshold) {
        groups.add(names[i]);
      }
    }
    return groups;
  }

  /// Get muscle intensities as a semicolon-separated string
  String get intensitiesAsString {
    return intensities.join(';');
  }
}

class Exercise {
  final int? id;
  final String name;
  final int type;
  final int defaultRepBase;
  final int defaultRepMax;
  final double defaultIncrement;
  final MuscleGroup muscleGroup;

  Exercise({
    this.id,
    required this.name,
    required this.type,
    required this.defaultRepBase,
    required this.defaultRepMax,
    required this.defaultIncrement,
    required this.muscleGroup,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? 0,
      defaultRepBase: json['default_rep_base'] ?? 8,
      defaultRepMax: json['default_rep_max'] ?? 12,
      defaultIncrement: (json['default_increment'] ?? 0.0).toDouble(),
      muscleGroup: MuscleGroup.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'default_rep_base': defaultRepBase,
      'default_rep_max': defaultRepMax,
      'default_increment': defaultIncrement,
      ...muscleGroup.toJson(),
    };
  }

  // Helper getters for backward compatibility
  List<String> get muscleGroups => muscleGroup.activeMuscleGroups;
  List<double> get muscleIntensities => muscleGroup.intensities;
  List<String> get primaryMuscleGroups => muscleGroup.getPrimaryMuscleGroups();

  // Individual muscle group getters for backward compatibility
  double get pectoralisMajor => muscleGroup.pectoralisMajor;
  double get trapezius => muscleGroup.trapezius;
  double get biceps => muscleGroup.biceps;
  double get abdominals => muscleGroup.abdominals;
  double get frontDelts => muscleGroup.frontDelts;
  double get deltoids => muscleGroup.deltoids;
  double get backDelts => muscleGroup.backDelts;
  double get latissimusDorsi => muscleGroup.latissimusDorsi;
  double get triceps => muscleGroup.triceps;
  double get gluteusMaximus => muscleGroup.gluteusMaximus;
  double get hamstrings => muscleGroup.hamstrings;
  double get quadriceps => muscleGroup.quadriceps;
  double get forearms => muscleGroup.forearms;
  double get calves => muscleGroup.calves;

  List<String> toCSVString() {
    return [
      name,
      "$type",
      "$defaultRepBase",
      "$defaultRepMax",
      "$defaultIncrement",
      muscleGroup.intensitiesAsString
    ];
  }
}
