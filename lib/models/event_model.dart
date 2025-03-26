class EventModel {
  final String eventId;
  final String title;
  final String eventEntry;
  final String createdAt;

  EventModel({
    required this.eventId,
    required this.title,
    required this.eventEntry,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventId: json['_id'],
      title: json['title'],
      eventEntry: json['event_entry'],
      createdAt: json['datetime'],
    );
  }
}