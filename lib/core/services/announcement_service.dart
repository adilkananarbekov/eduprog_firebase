import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_exception.dart';
import '../models/announcement.dart';
import '../models/managed_user.dart';
import '../models/user_role.dart';
import 'firebase_service_helpers.dart';

/// Service for announcement-related operations
class AnnouncementService {
  final FirebaseAuth? _firebaseAuthOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _firebaseAuth => _firebaseAuthOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  AnnouncementService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuthOverride = firebaseAuth,
      _firestoreOverride = firestore;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('announcements');

  /// Get my announcements
  Future<List<Announcement>> getMyAnnouncements() async {
    try {
      final currentUser = await _currentUser();
      final teacherGroupIds = currentUser.role == UserRole.TEACHER
          ? await _teacherGroupIds(currentUser.id)
          : const <int>{};
      final snapshot = await _announcements.get();
      final announcements = snapshot.docs.map(_announcementFromDoc).where((item) {
        if (currentUser.role == UserRole.ADMIN) {
          return true;
        }
        if (item.isGlobal) {
          return true;
        }
        if (item.authorId == currentUser.id) {
          return true;
        }
        if (currentUser.role == UserRole.STUDENT) {
          return item.classGroupId != null &&
              item.classGroupId == currentUser.classGroupId;
        }
        if (currentUser.role == UserRole.TEACHER) {
          return item.classGroupId != null &&
              teacherGroupIds.contains(item.classGroupId);
        }
        return false;
      }).toList();

      announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return announcements;
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load announcements.');
    }
  }

  /// Get all announcements (admin)
  Future<List<Announcement>> getAllAnnouncements() async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role != UserRole.ADMIN) {
        return getMyAnnouncements();
      }

      final snapshot = await _announcements.get();
      final announcements = snapshot.docs.map(_announcementFromDoc).toList();
      announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return announcements;
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to load announcements.');
    }
  }

  /// Create announcement (teacher/admin)
  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    int? classGroupId,
    bool isGlobal = false,
  }) async {
    try {
      final currentUser = await _currentUser();
      if (currentUser.role != UserRole.ADMIN &&
          currentUser.role != UserRole.TEACHER) {
        throw ForbiddenException(
          'Only staff can publish announcements.',
          statusCode: 403,
        );
      }

      String? classGroupName;
      if (!isGlobal && classGroupId != null) {
        classGroupName = await _classGroupName(classGroupId);
        if (classGroupName == null) {
          throw ValidationException(
            'The selected class group was not found.',
            statusCode: 400,
          );
        }

        if (currentUser.role == UserRole.TEACHER) {
          final allowedGroupIds = await _teacherGroupIds(currentUser.id);
          if (!allowedGroupIds.contains(classGroupId)) {
            throw ForbiddenException(
              'You can only publish announcements for your teaching groups.',
              statusCode: 403,
            );
          }
        }
      }

      final createdAt = DateTime.now();
      final id = createdAt.millisecondsSinceEpoch;
      final payload = <String, dynamic>{
        'id': id,
        'title': title.trim(),
        'content': content.trim(),
        'createdAt': Timestamp.fromDate(createdAt),
        'authorId': currentUser.id,
        'authorName': currentUser.fullName,
        'classGroupId': isGlobal ? null : classGroupId,
        'classGroupName': isGlobal ? null : classGroupName,
        'isGlobal': isGlobal || classGroupId == null,
        'updatedAt': Timestamp.fromDate(createdAt),
      };

      await _announcements.doc('announcement-$id').set(payload);
      return _announcementFromMap(payload);
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to create the announcement.');
    }
  }

  /// Delete announcement (teacher/admin)
  Future<void> deleteAnnouncement(int id) async {
    try {
      final currentUser = await _currentUser();
      final snapshot = await _announcements
          .where('id', isEqualTo: id)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final announcement = _announcementFromDoc(snapshot.docs.first);
      if (currentUser.role != UserRole.ADMIN &&
          announcement.authorId != currentUser.id) {
        throw ForbiddenException(
          'You can only delete announcements that you created.',
          statusCode: 403,
        );
      }

      await snapshot.docs.first.reference.delete();
    } catch (error) {
      throw _mapError(error, fallback: 'Failed to delete the announcement.');
    }
  }

  Future<ManagedUser> _currentUser() {
    return loadCurrentManagedUser(
      auth: _firebaseAuth,
      firestore: _firestore,
    );
  }

  Future<String?> _classGroupName(int classGroupId) async {
    final snapshot = await _firestore
        .collection('class_groups')
        .where('id', isEqualTo: classGroupId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final name = firebaseStringValue(snapshot.docs.first.data()['name']);
    return name.isEmpty ? null : name;
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

  Announcement _announcementFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _announcementFromMap(doc.data());
  }

  Announcement _announcementFromMap(Map<String, dynamic> data) {
    return Announcement(
      id: firebaseIntValue(data['id']) ?? 0,
      title: firebaseStringValue(data['title'], fallback: 'Announcement'),
      content: firebaseStringValue(data['content']),
      createdAt: firebaseDateTimeValue(data['createdAt']) ?? DateTime.now(),
      authorId: firebaseIntValue(data['authorId']) ?? 0,
      authorName: _nullableString(data['authorName']),
      classGroupId: firebaseIntValue(data['classGroupId']),
      classGroupName: _nullableString(data['classGroupName']),
      isGlobal: data['isGlobal'] as bool? ?? data['classGroupId'] == null,
    );
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
