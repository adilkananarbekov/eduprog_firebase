/// Class group (class) model
class ClassGroup {
  final int id;
  final String name;
  final int? grade;
  final int? monthlyFee;
  final int? studentCount;

  ClassGroup({
    required this.id,
    required this.name,
    this.grade,
    this.monthlyFee,
    this.studentCount,
  });

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) => value == null ? null : (value as num).toInt();

    final students = json['students'];

    return ClassGroup(
      id: asInt(json['id']) ?? 0,
      name: json['name'] as String,
      grade: asInt(json['grade']) ?? asInt(json['year']),
      monthlyFee: json['monthlyFee'] as int?,
      studentCount:
          asInt(json['studentCount']) ??
          asInt(json['student_count']) ??
          (students is List ? students.length : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'monthlyFee': monthlyFee,
      'studentCount': studentCount,
    };
  }
}
