/// Grade model
class Grade {
  final int id;
  final int studentId;
  final String? studentName;
  final int subjectId;
  final String subjectName;
  final int? teacherId;
  final String? teacherName;
  final double score;
  final double maxScore;
  final String? gradeType;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt;

  Grade({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.subjectId,
    required this.subjectName,
    this.teacherId,
    this.teacherName,
    required this.score,
    required this.maxScore,
    this.gradeType,
    required this.date,
    this.notes,
    this.createdAt,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => (value as num).toInt();

    final subjectIdValue = json['subjectId'] ?? json['takenClassId'];
    final subjectId = subjectIdValue is num ? subjectIdValue.toInt() : 0;
    final subjectName =
        json['subjectName'] as String? ??
        json['takenClassName'] as String? ??
        json['className'] as String? ??
        'Class #$subjectId';

    return Grade(
      id: asInt(json['id']),
      studentId: asInt(json['studentId']),
      studentName: json['studentName'] as String?,
      subjectId: subjectId,
      subjectName: subjectName,
      teacherId: (json['teacherId'] as num?)?.toInt(),
      teacherName: json['teacherName'] as String?,
      score: ((json['score'] ?? json['value']) as num).toDouble(),
      maxScore: ((json['maxScore'] ?? json['maxValue'] ?? 100) as num)
          .toDouble(),
      gradeType: json['gradeType'] as String?,
      date: DateTime.parse(json['date'] as String),
      notes: (json['notes'] ?? json['description']) as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'score': score,
      'value': score,
      'maxScore': maxScore,
      'maxValue': maxScore,
      'gradeType': gradeType,
      'date': date.toIso8601String(),
      'notes': notes,
      'description': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Calculate percentage
  double get percentage => (score / maxScore) * 100;

  /// Get letter grade (A, B, C, D, F)
  String get letterGrade {
    final percent = percentage;
    if (percent >= 90) return 'A';
    if (percent >= 80) return 'B';
    if (percent >= 70) return 'C';
    if (percent >= 60) return 'D';
    return 'F';
  }
}

/// Grade averages model
class GradeAverages {
  final double overallAverage;
  final Map<String, double> subjectAverages;

  GradeAverages({required this.overallAverage, required this.subjectAverages});

  factory GradeAverages.fromJson(Map<String, dynamic> json) {
    return GradeAverages(
      overallAverage: (json['overallAverage'] as num).toDouble(),
      subjectAverages: Map<String, double>.from(
        (json['subjectAverages'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallAverage': overallAverage,
      'subjectAverages': subjectAverages,
    };
  }
}
