class Activity {
  final int? id;
  //final String userName;
  final String name;
  final double kcalPerHour;

  Activity({
    this.id,
    // required this.userName,
    required this.name,
    required this.kcalPerHour,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      // userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      kcalPerHour: (json['kcal_per_hour'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      //'user_name': userName,
      'name': name,
      'kcal_per_hour': kcalPerHour,
    };
  }
}

class ActivityLog {
  final int? id;
  //final String userName;
  final String activityName;
  final DateTime date;
  final int durationMinutes;
  final double caloriesBurned;
  final String? notes;

  ActivityLog({
    this.id,
    //required this.userName,
    required this.activityName,
    required this.date,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.notes,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      // userName: json['user_name'] ?? '',
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
      //'user_name': userName,
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
