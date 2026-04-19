// ignore_for_file: constant_identifier_names

/// Attendance status enumeration
enum AttendanceStatus {
  PRESENT,
  ABSENT,
  LATE,
  EXCUSED;

  static AttendanceStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.PRESENT;
      case 'ABSENT':
        return AttendanceStatus.ABSENT;
      case 'LATE':
        return AttendanceStatus.LATE;
      case 'EXCUSED':
        return AttendanceStatus.EXCUSED;
      default:
        throw ArgumentError('Invalid attendance status: $status');
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.PRESENT:
        return 'Present';
      case AttendanceStatus.ABSENT:
        return 'Absent';
      case AttendanceStatus.LATE:
        return 'Late';
      case AttendanceStatus.EXCUSED:
        return 'Excused';
    }
  }
}

/// Attendance record model
class Attendance {
  final int id;
  final int studentId;
  final String? studentName;
  final int scheduleId;
  final String? subjectName;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;
  final String? markedByName;
  final DateTime? markedAt;

  Attendance({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.scheduleId,
    this.subjectName,
    required this.date,
    required this.status,
    this.notes,
    this.markedByName,
    this.markedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => (value as num).toInt();

    return Attendance(
      id: asInt(json['id']),
      studentId: asInt(json['studentId']),
      studentName: json['studentName'] as String?,
      scheduleId: asInt(json['scheduleId']),
      subjectName: json['subjectName'] as String?,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
      markedByName: json['markedByName'] as String?,
      markedAt: json['markedAt'] != null
          ? DateTime.parse(json['markedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'scheduleId': scheduleId,
      'subjectName': subjectName,
      'date': date.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'markedByName': markedByName,
      'markedAt': markedAt?.toIso8601String(),
    };
  }
}

/// Attendance statistics model
class AttendanceStats {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int excusedDays;
  final double attendanceRate;

  AttendanceStats({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.excusedDays,
    required this.attendanceRate,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    final present = (json['presentDays'] ?? json['present'] ?? 0) as num;
    final absent = (json['absentDays'] ?? json['absent'] ?? 0) as num;
    final late = (json['lateDays'] ?? json['late'] ?? 0) as num;
    final excused = (json['excusedDays'] ?? json['excused'] ?? 0) as num;
    final total =
        (json['totalDays'] as num?) ?? (present + absent + late + excused);

    return AttendanceStats(
      totalDays: total.toInt(),
      presentDays: present.toInt(),
      absentDays: absent.toInt(),
      lateDays: late.toInt(),
      excusedDays: excused.toInt(),
      attendanceRate:
          (json['attendanceRate'] as num?)?.toDouble() ??
          (total == 0 ? 0 : (present / total) * 100),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'excusedDays': excusedDays,
      'attendanceRate': attendanceRate,
    };
  }
}
