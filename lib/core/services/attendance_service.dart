import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_exception.dart';
import '../models/attendance.dart';
import '../models/managed_user.dart';
import '../models/schedule.dart';
import '../models/user_role.dart';
import 'firebase_service_helpers.dart';

class AttendanceMarkingRecord {
  final int studentId;
  final AttendanceStatus status;
  final String? notes;

  const AttendanceMarkingRecord({
    required this.studentId,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {'studentId': studentId, 'status': status.name, 'notes': notes};
  }
}

/// Service for attendance-related operations
class AttendanceService {
  final FirebaseAuth? _firebaseAuthOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _firebaseAuth => _firebaseAuthOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  AttendanceService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuthOverride = firebaseAuth,
      _firestoreOverride = firestore;

  CollectionReference<Map<String, dynamic>> get _attendance =>
      _firestore.collection('attendance');

  /// Get my attendance records
  Future<List<Attendance>> getMyAttendance() async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role != UserRole.STUDENT) {
        return const <Attendance>[];
      }

      final snapshot = await _attendance
          .where('studentId', isEqualTo: currentUser.id)
          .get();
      return _sortAttendance(snapshot.docs.map(_attendanceFromDoc).toList());
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load attendance records.');
    }
  }

  /// Get attendance by date range
  Future<List<Attendance>> getAttendanceByRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final records = await getMyAttendance();
    final start = firebaseDateOnly(startDate);
    final end = firebaseDateOnly(endDate);
    return records.where((record) {
      final date = firebaseDateOnly(record.date);
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList(growable: false);
  }

  /// Get my attendance statistics
  Future<AttendanceStats> getAttendanceStats() async {
    final records = await getMyAttendance();
    final present = records
        .where((record) => record.status == AttendanceStatus.PRESENT)
        .length;
    final absent = records
        .where((record) => record.status == AttendanceStatus.ABSENT)
        .length;
    final late = records
        .where((record) => record.status == AttendanceStatus.LATE)
        .length;
    final excused = records
        .where((record) => record.status == AttendanceStatus.EXCUSED)
        .length;
    final total = records.length;

    return AttendanceStats(
      totalDays: total,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      excusedDays: excused,
      attendanceRate: total == 0 ? 0 : (present / total) * 100,
    );
  }

  /// Get student attendance (teacher/admin)
  Future<List<Attendance>> getStudentAttendance(int studentId) async {
    try {
      final currentUser = await _currentUser();
      final snapshot = await _attendance
          .where('studentId', isEqualTo: studentId)
          .get();
      var records = snapshot.docs.map(_attendanceFromDoc).toList();

      if (currentUser.role == UserRole.TEACHER) {
        final scheduleIds = await _teacherScheduleIds(currentUser.id);
        records = records
            .where((record) => scheduleIds.contains(record.scheduleId))
            .toList(growable: false);
      }

      return _sortAttendance(records);
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load student attendance.');
    }
  }

  /// Mark attendance (teacher/admin)
  Future<List<Attendance>> markAttendance({
    required int scheduleId,
    required DateTime date,
    required List<AttendanceMarkingRecord> records,
  }) async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role != UserRole.ADMIN &&
          currentUser.role != UserRole.TEACHER) {
        throw ForbiddenException(
          'Only staff can mark attendance.',
          statusCode: 403,
        );
      }

      final schedule = await _findSchedule(scheduleId);
      if (schedule == null) {
        throw NotFoundException('Schedule $scheduleId was not found.', statusCode: 404);
      }

      if (currentUser.role == UserRole.TEACHER &&
          schedule.teacherId != currentUser.id) {
        throw ForbiddenException(
          'You can only mark attendance for your own lessons.',
          statusCode: 403,
        );
      }

      final normalizedDate = firebaseDateOnly(date);
      final existingRecords = await getScheduleAttendance(
        scheduleId: scheduleId,
        date: normalizedDate,
      );
      final existingByStudent = <int, Attendance>{
        for (final record in existingRecords) record.studentId: record,
      };
      final studentNames = await _studentNamesFor(
        records.map((record) => record.studentId).toSet(),
      );

      final batch = _firestore.batch();
      final markedAt = DateTime.now();
      final saved = <Attendance>[];
      final baseId = markedAt.millisecondsSinceEpoch * 100;

      for (var index = 0; index < records.length; index++) {
        final record = records[index];
        final existing = existingByStudent[record.studentId];
        final id = existing?.id ?? (baseId + index);
        final documentId = existing == null ? 'attendance-$id' : null;
        final payload = <String, dynamic>{
          'id': id,
          'studentId': record.studentId,
          'studentName': studentNames[record.studentId],
          'scheduleId': schedule.id,
          'subjectName': schedule.subjectName,
          'date': Timestamp.fromDate(normalizedDate),
          'status': record.status.name,
          'notes': record.notes?.trim(),
          'markedById': currentUser.id,
          'markedByName': currentUser.fullName,
          'markedAt': Timestamp.fromDate(markedAt),
        };

        if (existing == null) {
          batch.set(_attendance.doc(documentId), payload);
        } else {
          final snapshot = await _attendance
              .where('id', isEqualTo: existing.id)
              .limit(1)
              .get();
          if (snapshot.docs.isNotEmpty) {
            batch.set(snapshot.docs.first.reference, payload);
          } else {
            batch.set(_attendance.doc('attendance-$id'), payload);
          }
        }

        saved.add(_attendanceFromMap(payload));
      }

      await batch.commit();
      return _sortAttendance(saved);
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to save attendance.');
    }
  }

  /// Get attendance for a schedule on a specific date
  Future<List<Attendance>> getScheduleAttendance({
    required int scheduleId,
    required DateTime date,
  }) async {
    try {
      final currentUser = await _currentUser();
      final schedule = await _findSchedule(scheduleId);
      if (schedule == null) {
        throw NotFoundException('Schedule $scheduleId was not found.', statusCode: 404);
      }

      if (currentUser.role == UserRole.TEACHER &&
          schedule.teacherId != currentUser.id) {
        throw ForbiddenException(
          'You can only view attendance for your own lessons.',
          statusCode: 403,
        );
      }

      if (currentUser.role == UserRole.STUDENT &&
          currentUser.classGroupId != schedule.classGroupId) {
        throw ForbiddenException(
          'You do not have permission to view this attendance set.',
          statusCode: 403,
        );
      }

      final normalizedDate = firebaseDateOnly(date);
      final snapshot = await _attendance
          .where('scheduleId', isEqualTo: scheduleId)
          .get();

      final records = snapshot.docs
          .map(_attendanceFromDoc)
          .where((record) => firebaseIsSameDate(record.date, normalizedDate))
          .toList(growable: false);
      return _sortAttendance(records);
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load lesson attendance.');
    }
  }

  Future<ManagedUser> _currentUser() {
    return loadCurrentManagedUser(
      auth: _firebaseAuth,
      firestore: _firestore,
    );
  }

  Future<Set<int>> _teacherScheduleIds(int teacherId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    return snapshot.docs
        .map((doc) => firebaseIntValue(doc.data()['id']))
        .whereType<int>()
        .toSet();
  }

  Future<Map<int, String>> _studentNamesFor(Set<int> studentIds) async {
    final names = <int, String>{};
    for (final studentId in studentIds) {
      final snapshot = await _firestore
          .collection('users')
          .where('id', isEqualTo: studentId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        continue;
      }

      final user = ManagedUser.fromDocument(snapshot.docs.first);
      names[studentId] = user.fullName;
    }
    return names;
  }

  Future<Schedule?> _findSchedule(int scheduleId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('id', isEqualTo: scheduleId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }

    final data = snapshot.docs.first.data();
    return Schedule(
      id: firebaseIntValue(data['id']) ?? 0,
      classGroupId: firebaseIntValue(data['classGroupId']) ?? 0,
      classGroupName: _nullableString(data['classGroupName']),
      subjectId: firebaseIntValue(data['subjectId']) ?? 0,
      subjectName: firebaseStringValue(data['subjectName'], fallback: 'Subject'),
      teacherId: firebaseIntValue(data['teacherId']) ?? 0,
      teacherName: _nullableString(data['teacherName']),
      dayOfWeek: firebaseStringValue(data['dayOfWeek'], fallback: 'MONDAY'),
      startTime: firebaseStringValue(data['startTime'], fallback: '00:00'),
      endTime: firebaseStringValue(data['endTime'], fallback: '00:00'),
      room: _nullableString(data['room']),
    );
  }

  Attendance _attendanceFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _attendanceFromMap(doc.data());
  }

  Attendance _attendanceFromMap(Map<String, dynamic> data) {
    final date = firebaseDateTimeValue(data['date']) ?? DateTime.now();
    return Attendance(
      id: firebaseIntValue(data['id']) ?? 0,
      studentId: firebaseIntValue(data['studentId']) ?? 0,
      studentName: _nullableString(data['studentName']),
      scheduleId: firebaseIntValue(data['scheduleId']) ?? 0,
      subjectName: _nullableString(data['subjectName']),
      date: DateTime(date.year, date.month, date.day),
      status: AttendanceStatus.fromString(
        firebaseStringValue(data['status'], fallback: 'PRESENT'),
      ),
      notes: _nullableString(data['notes']),
      markedByName: _nullableString(data['markedByName']),
      markedAt: firebaseDateTimeValue(data['markedAt']),
    );
  }

  List<Attendance> _sortAttendance(List<Attendance> records) {
    final sorted = List<Attendance>.from(records);
    sorted.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return (a.studentName ?? '').toLowerCase().compareTo(
        (b.studentName ?? '').toLowerCase(),
      );
    });
    return sorted;
  }

  String? _nullableString(dynamic value) {
    final normalized = firebaseStringValue(value);
    return normalized.isEmpty ? null : normalized;
  }

  ApiException _mapError(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error;
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return ForbiddenException(fallback, statusCode: 403);
        case 'unauthenticated':
          return UnauthorizedException(fallback, statusCode: 401);
        case 'not-found':
          return NotFoundException(fallback, statusCode: 404);
        case 'unavailable':
          return NetworkException(fallback, originalError: error);
        default:
          return ServerException(
            error.message ?? fallback,
            originalError: error,
          );
      }
    }

    return UnknownException(fallback, originalError: error);
  }
}

