class Note {
  final int id;
  String title;
  String description;
  final DateTime date; // Date the note was created

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  // ── JSON serialization for SharedPreferences persistence ─────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}
