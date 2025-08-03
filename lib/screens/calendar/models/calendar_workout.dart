class CalendarWorkout {
  final int? id;
  final DateTime date;
  final String workoutName;

  CalendarWorkout({
    this.id,
    required this.date,
    required this.workoutName,
  });

  factory CalendarWorkout.fromMap(Map<String, dynamic> map) {
    return CalendarWorkout(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      workoutName: map['workout'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'workout': workoutName,
    };
  }

  CalendarWorkout copyWith({
    int? id,
    DateTime? date,
    String? workoutName,
  }) {
    return CalendarWorkout(
      id: id ?? this.id,
      date: date ?? this.date,
      workoutName: workoutName ?? this.workoutName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarWorkout &&
        other.id == id &&
        other.date == date &&
        other.workoutName == workoutName;
  }

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ workoutName.hashCode;

  @override
  String toString() =>
      'CalendarWorkout(id: $id, date: $date, workoutName: $workoutName)';
}
