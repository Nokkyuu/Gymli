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
  //final String userName;
  final PeriodType type; // Changed from String to enum
  final DateTime startDate;
  final DateTime endDate;

  CalendarPeriod({
    this.id,
    // required this.userName,
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  factory CalendarPeriod.fromJson(Map<String, dynamic> json) => CalendarPeriod(
        id: json['id'],
        //    userName: json['user_name'],
        type: PeriodType.fromString(json['type']),
        startDate: DateTime.parse(json['start_date']),
        endDate: DateTime.parse(json['end_date']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        // 'user_name': userName,
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
      // userName: userName ?? this.userName,
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
        // other.userName == userName &&
        other.type == type &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      //userName.hashCode ^
      type.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;

  @override
  String toString() =>
      'ApiPeriod(id: $id, type: $type, startDate: $startDate, endDate: $endDate)';
}

class CalendarNote {
  final int? id;
  //final String userName;
  final DateTime date;
  final String note;

  CalendarNote({
    this.id,
    // required this.userName,
    required this.date,
    required this.note,
  });

  factory CalendarNote.fromJson(Map<String, dynamic> json) => CalendarNote(
        id: json['id'],
        //userName: json['user_name'],
        date: DateTime.parse(json['date']),
        note: json['note'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        //'user_name': userName,
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
      // userName: userName ?? this.userName,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarNote &&
        other.id == id &&
        //other.userName == userName &&
        other.date == date &&
        other.note == note;
  }

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ note.hashCode;

  @override
  String toString() => 'ApiCalendarNote(id: $id, date: $date, note: $note)';
}

class CalendarWorkout {
  final int? id;
  //final String userName;
  final DateTime date;
  final String workout;

  CalendarWorkout({
    this.id,
    //required this.userName,
    required this.date,
    required this.workout,
  });

  factory CalendarWorkout.fromJson(Map<String, dynamic> json) =>
      CalendarWorkout(
        id: json['id'],
        //userName: json['user_name'],
        date: DateTime.parse(json['date']),
        workout: json['workout'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        //'user_name': userName,
        'date': date.toIso8601String(),
        'workout': workout,
      };

  // Add methods from CalendarWorkout
  CalendarWorkout copyWith({
    int? id,
    // String? userName,
    DateTime? date,
    String? workout,
  }) {
    return CalendarWorkout(
      id: id ?? this.id,
      //userName: userName ?? this.userName,
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
        //other.userName == userName &&
        other.date == date &&
        other.workout == workout;
  }

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ workout.hashCode;

  @override
  String toString() =>
      'ApiCalendarWorkout(id: $id, date: $date, workout: $workout)';
}
