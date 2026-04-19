/// Announcement model
class Announcement {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final int authorId;
  final String? authorName;
  final int? classGroupId;
  final String? classGroupName;
  final bool isGlobal;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.authorId,
    this.authorName,
    this.classGroupId,
    this.classGroupName,
    required this.isGlobal,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) => value == null ? null : (value as num).toInt();

    final targetGroupId =
        asInt(json['classGroupId']) ?? asInt(json['targetStudentGroupId']);

    return Announcement(
      id: asInt(json['id']) ?? 0,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorId: asInt(json['authorId']) ?? 0,
      authorName: json['authorName'] as String?,
      classGroupId: targetGroupId,
      classGroupName:
          json['classGroupName'] as String? ??
          json['targetStudentGroupName'] as String?,
      isGlobal:
          json['isGlobal'] as bool? ??
          (targetGroupId == null &&
              (json['targetRole'] == null ||
                  (json['targetRole'] as String).trim().isEmpty)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'authorId': authorId,
      'authorName': authorName,
      'classGroupId': classGroupId,
      'classGroupName': classGroupName,
      'isGlobal': isGlobal,
    };
  }
}
