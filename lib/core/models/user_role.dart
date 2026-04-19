// ignore_for_file: constant_identifier_names

/// User role enumeration matching backend roles
enum UserRole {
  STUDENT,
  TEACHER,
  ADMIN,
  ACCOUNTANT;

  /// Convert string to UserRole
  static UserRole fromString(String role) {
    final normalized = role.trim().toUpperCase().replaceFirst('ROLE_', '');

    switch (normalized) {
      case 'STUDENT':
      case 'PARENT':
        return UserRole.STUDENT;
      case 'TEACHER':
        return UserRole.TEACHER;
      case 'ADMIN':
      case 'ADMINISTRATOR':
      case 'SUPER_ADMIN':
      case 'UNIVERSITY_ADMIN':
        return UserRole.ADMIN;
      case 'ACCOUNTANT':
      case 'FINANCE':
        return UserRole.ACCOUNTANT;
      case 'GUEST':
        return UserRole.STUDENT;
      default:
        if (normalized.contains('ADMIN')) {
          return UserRole.ADMIN;
        }
        if (normalized.contains('ACCOUNT')) {
          return UserRole.ACCOUNTANT;
        }
        if (normalized.contains('TEACH')) {
          return UserRole.TEACHER;
        }
        if (normalized.contains('STUDENT') || normalized.contains('PARENT')) {
          return UserRole.STUDENT;
        }
        throw ArgumentError('Invalid role: $role');
    }
  }

  /// Get display name for role
  String get displayName {
    switch (this) {
      case UserRole.STUDENT:
        return 'Student';
      case UserRole.TEACHER:
        return 'Teacher';
      case UserRole.ADMIN:
        return 'Administrator';
      case UserRole.ACCOUNTANT:
        return 'Accountant';
    }
  }
}
