class CalendarNote {
  final int? id;
  final DateTime date;
  final String note;

  CalendarNote({
    this.id,
    required this.date,
    required this.note,
  });

  factory CalendarNote.fromMap(Map<String, dynamic> map) {
    return CalendarNote(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  CalendarNote copyWith({
    int? id,
    DateTime? date,
    String? note,
  }) {
    return CalendarNote(
      id: id ?? this.id,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarNote &&
        other.id == id &&
        other.date == date &&
        other.note == note;
  }

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ note.hashCode;

  @override
  String toString() => 'CalendarNote(id: $id, date: $date, note: $note)';
}
