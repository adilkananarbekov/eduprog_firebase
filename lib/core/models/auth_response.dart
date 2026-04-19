import 'dart:convert';

import 'user_role.dart';

/// Authentication response from login endpoint
class AuthResponse {
  final String token;
  final String type;
  final String? refreshToken;
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final int? profileId;
  final int? classGroupId;

  AuthResponse({
    required this.token,
    required this.type,
    this.refreshToken,
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profileId,
    this.classGroupId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final token = _stringValue(json, const ['token', 'access_token']) ?? '';
    final payload = _decodeJwtPayload(token);
    final Map<String, dynamic> userJson =
        _nestedMapValue(json, const ['user']) ?? <String, dynamic>{};

    final fullName =
        _stringValue(userJson, const ['fullName', 'full_name', 'name']) ??
        _stringValue(payload, const ['fullName', 'full_name', 'name']);
    final splitName = _splitFullName(fullName);
    final firstName =
        _stringValue(userJson, const ['firstName', 'first_name']) ??
        _stringValue(payload, const ['firstName', 'first_name']) ??
        splitName.$1;
    final lastName =
        _stringValue(userJson, const ['lastName', 'last_name']) ??
        _stringValue(payload, const ['lastName', 'last_name']) ??
        splitName.$2;
    final email =
        _stringValue(userJson, const ['email']) ??
        _stringValue(payload, const ['email', 'username']) ??
        _emailFromSubject(_stringValue(payload, const ['sub'])) ??
        _stringValue(json, const ['email']) ??
        '';
    final roleValue =
        _stringValue(userJson, const ['role']) ??
        _stringValue(payload, const ['role']) ??
        _firstAuthority(payload) ??
        _stringValue(json, const ['role']) ??
        'ROLE_STUDENT';

    return AuthResponse(
      token: token,
      type: _stringValue(json, const ['type', 'token_type']) ?? 'Bearer',
      refreshToken: _stringValue(json, const ['refreshToken', 'refresh_token']),
      userId:
          _intValue(userJson, const ['userId', 'user_id', 'id']) ??
          _intValue(payload, const ['userId', 'user_id', 'id', 'uid']) ??
          _intFromSubject(_stringValue(payload, const ['sub'])) ??
          0,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: UserRole.fromString(roleValue),
      profileId:
          _intValue(userJson, const ['profileId', 'profile_id']) ??
          _intValue(payload, const ['profileId', 'profile_id']),
      classGroupId:
          _intValue(userJson, const ['classGroupId', 'class_group_id']) ??
          _intValue(payload, const ['classGroupId', 'class_group_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'type': type,
      'refresh_token': refreshToken,
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'profileId': profileId,
      'classGroupId': classGroupId,
    };
  }

  String get fullName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : email;
  }

  AuthResponse copyWith({
    String? token,
    String? type,
    String? refreshToken,
    int? userId,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    int? profileId,
    int? classGroupId,
  }) {
    return AuthResponse(
      token: token ?? this.token,
      type: type ?? this.type,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      profileId: profileId ?? this.profileId,
      classGroupId: classGroupId ?? this.classGroupId,
    );
  }

  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return const {};
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is Map) {
        return payload.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}

    return const {};
  }

  static String? _stringValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static int? _intValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) {
        return value.toInt();
      }
      if (value is String && value.trim().isNotEmpty) {
        return int.tryParse(value.trim());
      }
    }
    return null;
  }

  static Map<String, dynamic>? _nestedMapValue(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return null;
  }

  static (String, String) _splitFullName(String? fullName) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isEmpty) {
      return ('', '');
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (parts.first, '');
    }

    return (parts.first, parts.skip(1).join(' '));
  }

  static String? _firstAuthority(Map<String, dynamic> payload) {
    final roles = payload['authorities'] ?? payload['roles'];
    if (roles is List) {
      for (final role in roles) {
        final value = role?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  static int? _intFromSubject(String? subject) {
    if (subject == null || subject.isEmpty) {
      return null;
    }
    return int.tryParse(subject);
  }

  static String? _emailFromSubject(String? subject) {
    if (subject == null || !subject.contains('@')) {
      return null;
    }
    return subject;
  }
}
