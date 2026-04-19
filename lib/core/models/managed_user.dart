import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

class ManagedUser {
  final String uid;
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool isActive;
  final int? classGroupId;
  final String? classGroupName;
  final List<int> subjectIds;
  final List<String> subjects;
  final DateTime? createdAt;

  const ManagedUser({
    required this.uid,
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    this.classGroupId,
    this.classGroupName,
    this.subjectIds = const <int>[],
    this.subjects = const <String>[],
    this.createdAt,
  });

  factory ManagedUser.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final json = snapshot.data() ?? const <String, dynamic>{};

    int? asInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    DateTime? asDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    List<int> asIntList(dynamic value) {
      if (value is! List) {
        return const <int>[];
      }

      return value.map(asInt).whereType<int>().toList(growable: false);
    }

    List<String> asStringList(dynamic value) {
      if (value is! List) {
        return const <String>[];
      }

      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final roleValue = (json['role'] ?? 'STUDENT').toString();

    return ManagedUser(
      uid: snapshot.id,
      id: asInt(json['id']) ?? 0,
      email: (json['email'] as String?)?.trim() ?? '',
      firstName: (json['firstName'] as String?)?.trim() ?? '',
      lastName: (json['lastName'] as String?)?.trim() ?? '',
      role: UserRole.fromString(roleValue),
      isActive: json['isActive'] as bool? ?? true,
      classGroupId: asInt(json['classGroupId']),
      classGroupName: (json['classGroupName'] as String?)?.trim(),
      subjectIds: asIntList(json['subjectIds']),
      subjects: asStringList(json['subjects']),
      createdAt: asDateTime(json['createdAt']),
    );
  }

  String get fullName {
    final combined = '$firstName $lastName'.trim();
    return combined.isNotEmpty ? combined : email;
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'isActive': isActive,
      'classGroupId': classGroupId,
      'classGroupName': classGroupName,
      'subjectIds': subjectIds,
      'subjects': subjects,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
