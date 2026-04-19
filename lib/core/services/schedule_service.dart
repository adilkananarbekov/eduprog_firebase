import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_exception.dart';
import '../models/class_group.dart';
import '../models/managed_user.dart';
import '../models/schedule.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import '../models/user_role.dart';
import 'firebase_service_helpers.dart';

/// Service for schedule-related operations
class ScheduleService {
  final FirebaseAuth? _firebaseAuthOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _firebaseAuth => _firebaseAuthOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  ScheduleService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuthOverride = firebaseAuth,
      _firestoreOverride = firestore;

  CollectionReference<Map<String, dynamic>> get _schedules =>
      _firestore.collection('schedules');

  /// Get my weekly schedule
  Future<List<Schedule>> getWeeklySchedule() async {
    try {
      final currentUser = await _currentUser();
      Query<Map<String, dynamic>> query = _schedules;

      switch (currentUser.role) {
        case UserRole.ADMIN:
        case UserRole.ACCOUNTANT:
          break;
        case UserRole.TEACHER:
          query = query.where('teacherId', isEqualTo: currentUser.id);
          break;
        case UserRole.STUDENT:
          final classGroupId = currentUser.classGroupId;
          if (classGroupId == null) {
            return const <Schedule>[];
          }
          query = query.where('classGroupId', isEqualTo: classGroupId);
          break;
      }

      final snapshot = await query.get();
      return _sortSchedules(snapshot.docs.map(_scheduleFromDoc).toList());
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load the weekly schedule.');
    }
  }

  /// Get class schedule
  Future<List<Schedule>> getClassSchedule(int classGroupId) async {
    try {
      final currentUser = await _currentUser();
      final snapshot = await _schedules
          .where('classGroupId', isEqualTo: classGroupId)
          .get();

      var schedules = snapshot.docs.map(_scheduleFromDoc).toList();
      if (currentUser.role == UserRole.TEACHER) {
        schedules = schedules
            .where((schedule) => schedule.teacherId == currentUser.id)
            .toList(growable: false);
      }

      if (currentUser.role == UserRole.STUDENT &&
          currentUser.classGroupId != classGroupId) {
        throw ForbiddenException(
          'You do not have permission to view this class schedule.',
          statusCode: 403,
        );
      }

      return _sortSchedules(schedules);
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load the class schedule.');
    }
  }

  /// Get teacher schedule
  Future<List<Schedule>> getTeacherSchedule(int teacherId) async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role == UserRole.TEACHER && currentUser.id != teacherId) {
        throw ForbiddenException(
          'Teachers can only view their own schedule.',
          statusCode: 403,
        );
      }

      final snapshot = await _schedules
          .where('teacherId', isEqualTo: teacherId)
          .get();
      return _sortSchedules(snapshot.docs.map(_scheduleFromDoc).toList());
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load the teacher schedule.');
    }
  }

  /// Create schedule (admin)
  Future<Schedule> createSchedule({
    required int classGroupId,
    required int subjectId,
    required int teacherId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    try {
      await _requireAdmin();
      final classGroup = await _findClassGroup(classGroupId);
      final subject = await _findSubject(subjectId);
      final teacher = await _findTeacher(teacherId);
      if (classGroup == null || subject == null || teacher == null) {
        throw ValidationException(
          'Class group, subject, or teacher could not be found.',
          statusCode: 400,
        );
      }

      final id = DateTime.now().millisecondsSinceEpoch;
      final payload = <String, dynamic>{
        'id': id,
        'classGroupId': classGroup.id,
        'classGroupName': classGroup.name,
        'subjectId': subject.id,
        'subjectName': subject.name,
        'teacherId': teacher.id,
        'teacherName': teacher.fullName,
        'dayOfWeek': dayOfWeek.trim().toUpperCase(),
        'startTime': startTime.trim(),
        'endTime': endTime.trim(),
        'room': room?.trim(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await _schedules.doc('schedule-$id').set(payload);
      return _scheduleFromMap(payload);
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to create the schedule.');
    }
  }

  /// Generate schedule (admin)
  Future<List<Schedule>> generateSchedule() async {
    return getWeeklySchedule();
  }

  /// Delete schedule (admin)
  Future<void> deleteSchedule(int id) async {
    try {
      await _requireAdmin();
      final snapshot = await _schedules.where('id', isEqualTo: id).limit(1).get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      await snapshot.docs.first.reference.delete();
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to delete the schedule.');
    }
  }

  Future<ManagedUser> _currentUser() {
    return loadCurrentManagedUser(
      auth: _firebaseAuth,
      firestore: _firestore,
    );
  }

  Future<void> _requireAdmin() async {
    final currentUser = await _currentUser();
    if (currentUser.role != UserRole.ADMIN) {
      throw ForbiddenException(
        'Only administrators can manage schedules.',
        statusCode: 403,
      );
    }
  }

  Future<ClassGroup?> _findClassGroup(int id) async {
    final snapshot = await _firestore
        .collection('class_groups')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return ClassGroup.fromJson(snapshot.docs.first.data());
  }

  Future<Subject?> _findSubject(int id) async {
    final snapshot = await _firestore
        .collection('subjects')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return Subject.fromJson(snapshot.docs.first.data());
  }

  Future<Teacher?> _findTeacher(int id) async {
    final snapshot = await _firestore
        .collection('users')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }

    final user = ManagedUser.fromDocument(snapshot.docs.first);
    if (user.role != UserRole.TEACHER) {
      return null;
    }

    return Teacher(id: user.id, name: user.fullName, email: user.email);
  }

  Schedule _scheduleFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _scheduleFromMap(doc.data());
  }

  Schedule _scheduleFromMap(Map<String, dynamic> data) {
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

  String? _nullableString(dynamic value) {
    final normalized = firebaseStringValue(value);
    return normalized.isEmpty ? null : normalized;
  }

  List<Schedule> _sortSchedules(List<Schedule> schedules) {
    const orderedDays = <String>[
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];

    final sorted = List<Schedule>.from(schedules);
    sorted.sort((a, b) {
      final dayCompare =
          orderedDays.indexOf(a.dayOfWeek.toUpperCase()) -
          orderedDays.indexOf(b.dayOfWeek.toUpperCase());
      if (dayCompare != 0) {
        return dayCompare;
      }
      return a.startTime.compareTo(b.startTime);
    });
    return sorted;
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
