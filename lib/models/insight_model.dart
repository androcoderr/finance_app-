/*class Insight {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isSeen;

  Insight({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isSeen = false,
  });

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'],
    content: json['content'],
    createdAt: DateTime.parse(json['created_at']),
    isSeen: json['is_seen'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'is_seen': isSeen,
  };
}
*/
