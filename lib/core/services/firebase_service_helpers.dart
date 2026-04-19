import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_exception.dart';
import '../models/managed_user.dart';

int? firebaseIntValue(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

double? firebaseDoubleValue(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

String firebaseStringValue(dynamic value, {String fallback = ''}) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return fallback;
  }
  return normalized;
}

DateTime? firebaseDateTimeValue(dynamic value) {
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

DateTime firebaseDateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool firebaseIsSameDate(DateTime first, DateTime second) {
  final a = firebaseDateOnly(first);
  final b = firebaseDateOnly(second);
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Future<ManagedUser> loadCurrentManagedUser({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
}) async {
  final firebaseUser = auth.currentUser;
  if (firebaseUser == null) {
    throw UnauthorizedException('No active Firebase session found.');
  }

  final snapshot = await firestore.collection('users').doc(firebaseUser.uid).get();
  if (!snapshot.exists) {
    throw ForbiddenException(
      'Your account is not provisioned yet. Ask an administrator to create your profile.',
      statusCode: 403,
    );
  }

  final user = ManagedUser.fromDocument(snapshot);
  if (!user.isActive) {
    throw ForbiddenException(
      'Your account is disabled. Contact an administrator.',
      statusCode: 403,
    );
  }

  return user;
}

