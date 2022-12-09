class Snippet {
  final String id;
  final String title;
  final String description;
  final String tags;
  final String code;
  final String language;
  final int timestamp;
  Snippet({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.code,
    required this.language,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tags': tags,
      'code': code,
      'language': language,
      'timestamp': timestamp,
    };
  }
}
