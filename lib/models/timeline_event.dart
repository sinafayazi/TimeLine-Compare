class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String category;
  final String? imageUrl;
  final List<String> tags;
  final bool isImportant;

  var details;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    this.imageUrl,
    this.tags = const [],
    this.isImportant = false,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'category': category,
      'imageUrl': imageUrl,
      'tags': tags,
      'isImportant': isImportant,
    };
  }

  // Create from JSON
  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      imageUrl: json['imageUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      isImportant: json['isImportant'] ?? false,
    );
  }

  TimelineEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? category,
    String? imageUrl,
    List<String>? tags,
    bool? isImportant,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isImportant: isImportant ?? this.isImportant,
    );
  }
}

class Timeline {
  final String id;
  final String name;
  final String description;
  final List<TimelineEvent> events;
  final DateTime createdAt;
  final DateTime updatedAt;

  Timeline({
    required this.id,
    required this.name,
    required this.description,
    required this.events,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'events': events.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Timeline.fromJson(Map<String, dynamic> json) {
    return Timeline(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      events: (json['events'] as List)
          .map((e) => TimelineEvent.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Timeline copyWith({
    String? id,
    String? name,
    String? description,
    List<TimelineEvent>? events,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Timeline(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      events: events ?? this.events,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
