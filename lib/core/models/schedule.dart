/// Schedule model
class Schedule {
  final int id;
  final int classGroupId;
  final String? classGroupName;
  final int subjectId;
  final String subjectName;
  final int teacherId;
  final String? teacherName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;

  Schedule({
    required this.id,
    required this.classGroupId,
    this.classGroupName,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    // Helper to convert LocalTime object or string to HH:mm string
    String parseTime(dynamic timeValue) {
      if (timeValue == null) return '00:00';
      if (timeValue is String) return timeValue;
      if (timeValue is Map<String, dynamic>) {
        final hour = (timeValue['hour'] as int?) ?? 0;
        final minute = (timeValue['minute'] as int?) ?? 0;
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
      return '00:00';
    }

    return Schedule(
      id: asInt(json['id']),
      classGroupId: asInt(json['classGroupId'] ?? json['studentGroupId']),
      classGroupName:
          json['classGroupName'] as String? ??
          json['studentGroupName'] as String?,
      subjectId: asInt(json['subjectId'] ?? json['classId']),
      subjectName:
          json['subjectName'] as String? ??
          json['className'] as String? ??
          'Class #${asInt(json['subjectId'] ?? json['classId'])}',
      teacherId: asInt(json['teacherId']),
      teacherName: json['teacherName'] as String?,
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: parseTime(json['startTime']),
      endTime: parseTime(json['endTime']),
      room: json['room'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classGroupId': classGroupId,
      'classGroupName': classGroupName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
    };
  }
}
