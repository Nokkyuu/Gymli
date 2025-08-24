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

class Exercise {
  final int? id;
  //final String userName;
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
    //required this.userName,
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
      //userName: json['user_name'] ?? '',
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
      //'user_name': userName,
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
    String intensitiesString = muscleIntensities.join(';');

    return [
      name,
      "$type",
      "$defaultRepBase",
      "$defaultRepMax",
      "$defaultIncrement",
      intensitiesString // Only the intensity values, no names needed
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
