class EventModel {
  final String EventId;
  final String title;
  final String journalEntry;
  final String createdAt;

  var eventEntry;

  EventModel({
    required this.EventId,
    required this.title,
    required this.journalEntry,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      EventId: json['id'],
      title: json['title'],
      journalEntry: json['journal_entry'],
      createdAt: json['datetime'],
    );
  }
}
