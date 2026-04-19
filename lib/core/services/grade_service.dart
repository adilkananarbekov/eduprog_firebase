import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_exception.dart';
import '../models/grade.dart';
import '../models/managed_user.dart';
import '../models/user_role.dart';
import 'firebase_service_helpers.dart';

/// Service for grade-related operations
class GradeService {
  final FirebaseAuth? _firebaseAuthOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _firebaseAuth => _firebaseAuthOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  GradeService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuthOverride = firebaseAuth,
      _firestoreOverride = firestore;

  CollectionReference<Map<String, dynamic>> get _grades =>
      _firestore.collection('grades');

  /// Get my grades
  Future<List<Grade>> getMyGrades() async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role != UserRole.STUDENT) {
        return const <Grade>[];
      }

      final snapshot = await _grades
          .where('studentId', isEqualTo: currentUser.id)
          .get();
      return _sortGrades(snapshot.docs.map(_gradeFromDoc).toList());
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load grades.');
    }
  }

  /// Get my grades by subject
  Future<List<Grade>> getGradesBySubject(int subjectId) async {
    final grades = await getMyGrades();
    return grades
        .where((grade) => grade.subjectId == subjectId)
        .toList(growable: false);
  }

  /// Get my grade averages
  Future<GradeAverages> getGradeAverages() async {
    final grades = await getMyGrades();
    if (grades.isEmpty) {
      return GradeAverages(
        overallAverage: 0,
        subjectAverages: const <String, double>{},
      );
    }

    final totals = <String, double>{};
    final counts = <String, int>{};
    var overall = 0.0;

    for (final grade in grades) {
      final percent = grade.percentage;
      overall += percent;
      totals[grade.subjectName] = (totals[grade.subjectName] ?? 0) + percent;
      counts[grade.subjectName] = (counts[grade.subjectName] ?? 0) + 1;
    }

    final subjectAverages = <String, double>{};
    for (final entry in totals.entries) {
      subjectAverages[entry.key] = entry.value / (counts[entry.key] ?? 1);
    }

    return GradeAverages(
      overallAverage: overall / grades.length,
      subjectAverages: subjectAverages,
    );
  }

  /// Get student grades (teacher/admin)
  Future<List<Grade>> getStudentGrades(int studentId) async {
    try {
      final currentUser = await _currentUser();
      final snapshot = await _grades.where('studentId', isEqualTo: studentId).get();
      var grades = snapshot.docs.map(_gradeFromDoc).toList();

      if (currentUser.role == UserRole.TEACHER) {
        grades = grades
            .where((grade) => grade.teacherId == currentUser.id)
            .toList(growable: false);
      }

      return _sortGrades(grades);
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load student grades.');
    }
  }

  /// Create grade (teacher/admin)
  Future<Grade> createGrade({
    required int studentId,
    required int subjectId,
    required double score,
    required double maxScore,
    String? gradeType,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role != UserRole.ADMIN &&
          currentUser.role != UserRole.TEACHER) {
        throw ForbiddenException(
          'Only staff can create grades.',
          statusCode: 403,
        );
      }

      final student = await _findStudent(studentId);
      final subjectName = await _subjectName(subjectId);
      if (student == null || subjectName == null) {
        throw ValidationException(
          'Student or subject could not be found.',
          statusCode: 400,
        );
      }

      if (currentUser.role == UserRole.TEACHER &&
          !await _teacherCanAccessSubject(
            teacherId: currentUser.id,
            classGroupId: student.classGroupId,
            subjectId: subjectId,
          )) {
        throw ForbiddenException(
          'You can only grade students from your teaching schedule.',
          statusCode: 403,
        );
      }

      final normalizedDate = firebaseDateOnly(date);
      final createdAt = DateTime.now();
      final id = createdAt.millisecondsSinceEpoch;
      final payload = <String, dynamic>{
        'id': id,
        'studentId': student.id,
        'studentName': student.fullName,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'teacherId': currentUser.id,
        'teacherName': currentUser.fullName,
        'score': score,
        'maxScore': maxScore,
        'gradeType': gradeType?.trim(),
        'date': Timestamp.fromDate(normalizedDate),
        'notes': notes?.trim(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

      await _grades.doc('grade-$id').set(payload);
      return _gradeFromMap(payload);
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to create the grade.');
    }
  }

  /// Delete grade (teacher/admin)
  Future<void> deleteGrade(int id) async {
    try {
      final currentUser = await _currentUser();
      final snapshot = await _grades.where('id', isEqualTo: id).limit(1).get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final grade = _gradeFromDoc(snapshot.docs.first);
      if (currentUser.role != UserRole.ADMIN &&
          grade.teacherId != currentUser.id) {
        throw ForbiddenException(
          'You can only delete grades created under your profile.',
          statusCode: 403,
        );
      }

      await snapshot.docs.first.reference.delete();
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to delete the grade.');
    }
  }

  Future<ManagedUser> _currentUser() {
    return loadCurrentManagedUser(
      auth: _firebaseAuth,
      firestore: _firestore,
    );
  }

  Future<ManagedUser?> _findStudent(int studentId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('id', isEqualTo: studentId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }

    final user = ManagedUser.fromDocument(snapshot.docs.first);
    if (user.role != UserRole.STUDENT) {
      return null;
    }
    return user;
  }

  Future<String?> _subjectName(int subjectId) async {
    final snapshot = await _firestore
        .collection('subjects')
        .where('id', isEqualTo: subjectId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return firebaseStringValue(
      snapshot.docs.first.data()['name'],
      fallback: '',
    );
  }

  Future<bool> _teacherCanAccessSubject({
    required int teacherId,
    required int? classGroupId,
    required int subjectId,
  }) async {
    if (classGroupId == null) {
      return false;
    }

    final snapshot = await _firestore
        .collection('schedules')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    return snapshot.docs.any(
      (doc) =>
          firebaseIntValue(doc.data()['classGroupId']) == classGroupId &&
          firebaseIntValue(doc.data()['subjectId']) == subjectId,
    );
  }

  Grade _gradeFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _gradeFromMap(doc.data());
  }

  Grade _gradeFromMap(Map<String, dynamic> data) {
    final date = firebaseDateTimeValue(data['date']) ?? DateTime.now();
    return Grade(
      id: firebaseIntValue(data['id']) ?? 0,
      studentId: firebaseIntValue(data['studentId']) ?? 0,
      studentName: _nullableString(data['studentName']),
      subjectId: firebaseIntValue(data['subjectId']) ?? 0,
      subjectName: firebaseStringValue(data['subjectName'], fallback: 'Subject'),
      teacherId: firebaseIntValue(data['teacherId']),
      teacherName: _nullableString(data['teacherName']),
      score: firebaseDoubleValue(data['score']) ?? 0,
      maxScore: firebaseDoubleValue(data['maxScore']) ?? 100,
      gradeType: _nullableString(data['gradeType']),
      date: DateTime(date.year, date.month, date.day),
      notes: _nullableString(data['notes']),
      createdAt: firebaseDateTimeValue(data['createdAt']),
    );
  }

  List<Grade> _sortGrades(List<Grade> grades) {
    final sorted = List<Grade>.from(grades);
    sorted.sort((a, b) => b.date.compareTo(a.date));
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
