class CalendarPeriod {
  final int? id;
  final PeriodType type;
  final DateTime start;
  final DateTime end;

  CalendarPeriod({
    this.id,
    required this.type,
    required this.start,
    required this.end,
  });

  factory CalendarPeriod.fromMap(Map<String, dynamic> map) {
    return CalendarPeriod(
      id: map['id'] as int?,
      type: PeriodType.fromString(map['type'] as String),
      start: DateTime.parse(map['start_date'] as String),
      end: DateTime.parse(map['end_date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'start_date': start.toIso8601String(),
      'end_date': end.toIso8601String(),
    };
  }

  CalendarPeriod copyWith({
    int? id,
    PeriodType? type,
    DateTime? start,
    DateTime? end,
  }) {
    return CalendarPeriod(
      id: id ?? this.id,
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  bool containsDate(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  bool overlaps(CalendarPeriod other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarPeriod &&
        other.id == id &&
        other.type == type &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode =>
      id.hashCode ^ type.hashCode ^ start.hashCode ^ end.hashCode;

  @override
  String toString() =>
      'CalendarPeriod(id: $id, type: $type, start: $start, end: $end)';
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
