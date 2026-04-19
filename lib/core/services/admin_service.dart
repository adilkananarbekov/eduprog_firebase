import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../api/api_exception.dart';
import '../models/class_group.dart';
import '../models/managed_user.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import '../models/user_role.dart';
import 'firebase_service_helpers.dart';

class AccessibleStudentsResult {
  final List<Student> students;

  const AccessibleStudentsResult({required this.students});
}

class AdminService {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseFunctions? _functionsOverride;
  final FirebaseAuth? _firebaseAuthOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  FirebaseAuth get _firebaseAuth => _firebaseAuthOverride ?? FirebaseAuth.instance;

  AdminService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? firebaseAuth,
  })
    : _firestoreOverride = firestore,
      _functionsOverride = functions,
      _firebaseAuthOverride = firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _classGroups =>
      _firestore.collection('class_groups');

  CollectionReference<Map<String, dynamic>> get _subjects =>
      _firestore.collection('subjects');

  Future<List<dynamic>> getUsers() async {
    await _requireAdminUser();
    final users = await listManagedUsers();
    return users.map((user) => user.toJson()).toList(growable: false);
  }

  Future<List<Student>> getStudents() async {
    final currentUser = await _currentUser();
    if (currentUser.role == UserRole.TEACHER) {
      final result = await getAccessibleStudents();
      return result.students;
    }

    final users = await listManagedUsers(role: 'STUDENT');
    return _sortStudents(users.map(_studentFromManagedUser));
  }

  Future<AccessibleStudentsResult> getAccessibleStudents({
    int? classGroupId,
  }) async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role == UserRole.TEACHER) {
        final allowedGroupIds = await _teacherGroupIds(currentUser.id);
        if (allowedGroupIds.isEmpty) {
          return const AccessibleStudentsResult(students: <Student>[]);
        }

        if (classGroupId != null) {
          if (!allowedGroupIds.contains(classGroupId)) {
            throw ForbiddenException(
              'You can only view students from your teaching groups.',
              statusCode: 403,
            );
          }

          return AccessibleStudentsResult(
            students: _sortStudents(await getStudentsByClass(classGroupId)),
          );
        }

        final snapshot = await _users.where('role', isEqualTo: 'STUDENT').get();
        final students = snapshot.docs
            .map((doc) => _studentFromManagedUser(ManagedUser.fromDocument(doc)))
            .where(
              (student) =>
                  student.classGroupId != null &&
                  allowedGroupIds.contains(student.classGroupId),
            )
            .toList(growable: false);
        return AccessibleStudentsResult(students: _sortStudents(students));
      }

      if (classGroupId != null) {
        return AccessibleStudentsResult(
          students: _sortStudents(await getStudentsByClass(classGroupId)),
        );
      }

      return AccessibleStudentsResult(
        students: _sortStudents(await getStudents()),
      );
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load students.');
    }
  }

  Future<Student?> getAccessibleStudentById(int studentId) async {
    try {
      final currentUser = await _currentUser();
      final snapshot = await _findUserByNumericId(studentId);
      if (snapshot == null) {
        return null;
      }

      final user = ManagedUser.fromDocument(snapshot);
      if (user.role != UserRole.STUDENT) {
        return null;
      }

      if (currentUser.role == UserRole.TEACHER) {
        final allowedGroupIds = await _teacherGroupIds(currentUser.id);
        if (user.classGroupId == null ||
            !allowedGroupIds.contains(user.classGroupId)) {
          return null;
        }
      }
      return _studentFromManagedUser(user);
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load the student profile.');
    }
  }

  Future<List<Student>> getStudentsByClass(int classGroupId) async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role == UserRole.TEACHER) {
        final allowedGroupIds = await _teacherGroupIds(currentUser.id);
        if (!allowedGroupIds.contains(classGroupId)) {
          throw ForbiddenException(
            'You can only view students from your teaching groups.',
            statusCode: 403,
          );
        }
      }

      final snapshot = await _users.where('role', isEqualTo: 'STUDENT').get();

      return _sortStudents(
        snapshot.docs.map(
          (doc) => _studentFromManagedUser(ManagedUser.fromDocument(doc)),
        ).where((student) => student.classGroupId == classGroupId),
      );
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load class students.');
    }
  }

  Future<List<Student>> getUnassignedStudents() async {
    await _requireAdminUser();
    final students = await getStudents();
    return students
        .where((student) => student.classGroupId == null)
        .toList(growable: false);
  }

  Future<void> updateStudentClass(int studentId, int classGroupId) async {
    try {
      await _requireAdminUser();
      final studentDoc = await _findUserByNumericId(studentId);
      if (studentDoc == null) {
        throw NotFoundException(
          'Student $studentId was not found.',
          statusCode: 404,
        );
      }

      final group = await _findClassGroupById(classGroupId);
      if (group == null) {
        throw NotFoundException(
          'Class group $classGroupId was not found.',
          statusCode: 404,
        );
      }

      await studentDoc.reference.update({
        'classGroupId': group.id,
        'classGroupName': group.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw _mapError(
        error,
        fallback: 'Failed to update the class assignment.',
      );
    }
  }

  Future<void> bulkAssignStudents(
    List<int> studentIds,
    int classGroupId,
  ) async {
    try {
      await _requireAdminUser();
      final group = await _findClassGroupById(classGroupId);
      if (group == null) {
        throw NotFoundException(
          'Class group $classGroupId was not found.',
          statusCode: 404,
        );
      }

      final batch = _firestore.batch();
      for (final studentId in studentIds) {
        final studentDoc = await _findUserByNumericId(studentId);
        if (studentDoc == null) {
          continue;
        }

        batch.update(studentDoc.reference, {
          'classGroupId': group.id,
          'classGroupName': group.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (error) {
      throw _mapError(
        error,
        fallback: 'Failed to assign students to the class.',
      );
    }
  }

  Future<List<Teacher>> getTeachers() async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role == UserRole.TEACHER) {
        return <Teacher>[
          Teacher(
            id: currentUser.id,
            name: currentUser.fullName,
            email: currentUser.email,
            subjects: currentUser.subjects,
          ),
        ];
      }

      final users = await listManagedUsers(role: 'TEACHER');
      final teachers = users.map(_teacherFromManagedUser).toList();
      teachers.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return teachers;
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load teachers.');
    }
  }

  Future<void> updateTeacherSubjects(
    int teacherId,
    List<int> subjectIds,
  ) async {
    try {
      await _requireAdminUser();
      final teacherDoc = await _findUserByNumericId(teacherId);
      if (teacherDoc == null) {
        throw NotFoundException(
          'Teacher $teacherId was not found.',
          statusCode: 404,
        );
      }

      final subjectNames = await _subjectNamesForIds(subjectIds);
      await teacherDoc.reference.update({
        'subjectIds': subjectIds,
        'subjects': subjectNames,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to update teacher subjects.');
    }
  }

  Future<List<ClassGroup>> getClassGroups() async {
    try {
      final currentUser = await _currentUser();
      final groupsSnapshot = await _classGroups.get();
      final studentSnapshot = await _users
          .where('role', isEqualTo: 'STUDENT')
          .get();

      final studentCounts = <int, int>{};
      for (final doc in studentSnapshot.docs) {
        final data = doc.data();
        final groupId = data['classGroupId'];
        if (groupId is num) {
          final normalizedId = groupId.toInt();
          studentCounts[normalizedId] = (studentCounts[normalizedId] ?? 0) + 1;
        }
      }

      var groups = groupsSnapshot.docs.map((doc) {
        final data = doc.data();
        final id = (data['id'] as num?)?.toInt() ?? 0;
        return ClassGroup.fromJson({
          ...data,
          'studentCount': studentCounts[id] ?? 0,
        });
      }).toList();

      if (currentUser.role == UserRole.TEACHER) {
        final allowedGroupIds = await _teacherGroupIds(currentUser.id);
        groups = groups
            .where((group) => allowedGroupIds.contains(group.id))
            .toList(growable: false);
      }

      groups.sort((a, b) {
        final gradeCompare = (a.grade ?? 0).compareTo(b.grade ?? 0);
        if (gradeCompare != 0) {
          return gradeCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return groups;
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load class groups.');
    }
  }

  Future<ClassGroup> createClassGroup({
    required String name,
    int? grade,
    int? monthlyFee,
  }) async {
    try {
      await _requireAdminUser();
      final nextId = await _nextSequence('nextClassGroupId');
      final document = _classGroups.doc();
      final payload = <String, dynamic>{
        'id': nextId,
        'name': name.trim(),
        'grade': grade,
        'monthlyFee': monthlyFee,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await document.set(payload);
      return ClassGroup.fromJson({...payload, 'studentCount': 0});
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to create the class group.');
    }
  }

  Future<ClassGroup> updateClassGroup(
    int id, {
    required String name,
    int? grade,
    int? monthlyFee,
  }) async {
    try {
      await _requireAdminUser();
      final groupDoc = await _findClassGroupDocumentById(id);
      if (groupDoc == null) {
        throw NotFoundException(
          'Class group $id was not found.',
          statusCode: 404,
        );
      }

      await groupDoc.reference.update({
        'name': name.trim(),
        'grade': grade,
        'monthlyFee': monthlyFee,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ClassGroup.fromJson({
        ...groupDoc.data(),
        'id': id,
        'name': name.trim(),
        'grade': grade,
        'monthlyFee': monthlyFee,
      });
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to update the class group.');
    }
  }

  Future<void> createStudent({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    int? classGroupId,
  }) async {
    await _requireAdminUser();
    await _createManagedUser(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: 'STUDENT',
      classGroupId: classGroupId,
    );
  }

  Future<void> createTeacher({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await _requireAdminUser();
    await _createManagedUser(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: 'TEACHER',
    );
  }

  Future<void> deleteClassGroup(int id) async {
    try {
      await _requireAdminUser();
      final groupDoc = await _findClassGroupDocumentById(id);
      if (groupDoc == null) {
        return;
      }

      final students = await _users.where('role', isEqualTo: 'STUDENT').get();

      final batch = _firestore.batch();
      for (final student in students.docs) {
        final data = student.data();
        if ((data['classGroupId'] as num?)?.toInt() != id) {
          continue;
        }
        batch.update(student.reference, {
          'classGroupId': null,
          'classGroupName': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      batch.delete(groupDoc.reference);
      await batch.commit();
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to delete the class group.');
    }
  }

  Future<List<Subject>> getSubjects() async {
    try {
      final currentUser = await _currentUser();
      final snapshot = await _subjects.get();
      var subjects = snapshot.docs
          .map((doc) => Subject.fromJson(doc.data()))
          .toList();

      if (currentUser.role == UserRole.TEACHER) {
        final allowedSubjectIds = await _teacherSubjectIds(currentUser);
        subjects = subjects
            .where((subject) => allowedSubjectIds.contains(subject.id))
            .toList(growable: false);
      }

      subjects.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return subjects;
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load subjects.');
    }
  }

  Future<List<ManagedUser>> listManagedUsers({String? role}) async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role != UserRole.ADMIN) {
        throw ForbiddenException(
          'Only administrators can manage user accounts.',
          statusCode: 403,
        );
      }

      Query<Map<String, dynamic>> query = _users;
      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }

      final snapshot = await query.get();
      final users = snapshot.docs.map(ManagedUser.fromDocument).toList();
      users.sort((a, b) {
        final roleCompare = a.role.displayName.compareTo(b.role.displayName);
        if (roleCompare != 0) {
          return roleCompare;
        }
        return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      });
      return users;
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load user accounts.');
    }
  }

  Future<void> updateManagedUser({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
    int? classGroupId,
    required bool isActive,
  }) async {
    try {
      await _requireAdminUser();
      await _functions.httpsCallable('updateManagedUser').call({
        'uid': uid,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'role': role.trim().toUpperCase(),
        'classGroupId': classGroupId,
        'isActive': isActive,
      });
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to update the user.');
    }
  }

  Future<void> deleteManagedUser(String uid) async {
    try {
      await _requireAdminUser();
      await _functions.httpsCallable('deleteManagedUser').call({'uid': uid});
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to delete the user.');
    }
  }

  Future<void> _createManagedUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    int? classGroupId,
  }) async {
    try {
      await _requireAdminUser();
      await _functions.httpsCallable('createManagedUser').call({
        'email': email.trim(),
        'password': password,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'role': role.trim().toUpperCase(),
        'classGroupId': classGroupId,
      });
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to create the user.');
    }
  }

  Future<ManagedUser> _currentUser() {
    return loadCurrentManagedUser(
      auth: _firebaseAuth,
      firestore: _firestore,
    );
  }

  Future<void> _requireAdminUser() async {
    final currentUser = await _currentUser();
    if (currentUser.role != UserRole.ADMIN) {
      throw ForbiddenException(
        'Only administrators can perform this action.',
        statusCode: 403,
      );
    }
  }

  Future<Set<int>> _teacherGroupIds(int teacherId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    return snapshot.docs
        .map((doc) => firebaseIntValue(doc.data()['classGroupId']))
        .whereType<int>()
        .toSet();
  }

  Future<Set<int>> _teacherSubjectIds(ManagedUser teacher) async {
    final subjectIds = <int>{...teacher.subjectIds};
    final snapshot = await _firestore
        .collection('schedules')
        .where('teacherId', isEqualTo: teacher.id)
        .get();
    for (final doc in snapshot.docs) {
      final subjectId = firebaseIntValue(doc.data()['subjectId']);
      if (subjectId != null) {
        subjectIds.add(subjectId);
      }
    }
    return subjectIds;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findUserByNumericId(
    int id,
  ) async {
    final snapshot = await _users.where('id', isEqualTo: id).limit(1).get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return snapshot.docs.first;
  }

  Future<ClassGroup?> _findClassGroupById(int id) async {
    final snapshot = await _findClassGroupDocumentById(id);
    if (snapshot == null) {
      return null;
    }
    return ClassGroup.fromJson(snapshot.data());
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _findClassGroupDocumentById(int id) async {
    final snapshot = await _classGroups
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return snapshot.docs.first;
  }

  Future<List<String>> _subjectNamesForIds(List<int> subjectIds) async {
    if (subjectIds.isEmpty) {
      return const <String>[];
    }

    final snapshot = await _subjects.get();
    final namesById = <int, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rawId = data['id'];
      if (rawId is num && data['name'] is String) {
        namesById[rawId.toInt()] = (data['name'] as String).trim();
      }
    }

    return subjectIds
        .map((id) => namesById[id])
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  Future<int> _nextSequence(String fieldName) async {
    final metadataRef = _firestore.collection('metadata').doc('counters');
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(metadataRef);
      final currentData = snapshot.data() ?? const <String, dynamic>{};
      final currentValue = (currentData[fieldName] as num?)?.toInt() ?? 0;
      final nextValue = currentValue + 1;
      transaction.set(metadataRef, {
        fieldName: nextValue,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return nextValue;
    });
  }

  Student _studentFromManagedUser(ManagedUser user) {
    return Student(
      id: user.id,
      userId: user.id,
      name: user.fullName,
      email: user.email,
      classGroupId: user.classGroupId,
      classGroupName: user.classGroupName,
      studentNumber: 'STU-${user.id.toString().padLeft(5, '0')}',
      accountNumber: 'ACC-${user.id.toString().padLeft(5, '0')}',
    );
  }

  Teacher _teacherFromManagedUser(ManagedUser user) {
    return Teacher(
      id: user.id,
      name: user.fullName,
      email: user.email,
      subjects: user.subjects,
    );
  }

  List<Student> _sortStudents(Iterable<Student> students) {
    final sorted = students.toList();
    sorted.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return sorted;
  }

  ApiException _mapError(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error;
    }

    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'permission-denied':
          return ForbiddenException(error.message ?? fallback, statusCode: 403);
        case 'unauthenticated':
          return UnauthorizedException(
            error.message ?? fallback,
            statusCode: 401,
          );
        case 'not-found':
          return NotFoundException(error.message ?? fallback, statusCode: 404);
        case 'invalid-argument':
        case 'already-exists':
          return ValidationException(
            error.message ?? fallback,
            statusCode: 400,
          );
        default:
          return ServerException(
            error.message ?? fallback,
            originalError: error,
          );
      }
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
