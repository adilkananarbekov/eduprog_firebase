import '../models/user_role.dart';

/// Client-side route access helper.
///
/// The backend remains the real security boundary, but mobile should avoid
/// presenting or navigating users into screens that are clearly outside their
/// role.
class RoleAccess {
  static String defaultRouteFor(UserRole role) {
    switch (role) {
      case UserRole.STUDENT:
        return '/parent';
      case UserRole.TEACHER:
      case UserRole.ADMIN:
      case UserRole.ACCOUNTANT:
        return '/admin';
    }
  }

  static bool canAccessRoute(UserRole role, String route) {
    if (route == '/login' || route == '/splash') {
      return true;
    }

    if (route.startsWith('/parent')) {
      return role == UserRole.STUDENT;
    }

    if (!route.startsWith('/admin')) {
      return true;
    }

    if (role == UserRole.STUDENT) {
      return false;
    }

    // Staff access evolves server-side. Avoid stale client restrictions and
    // let the backend decide which admin endpoints are actually allowed.
    return true;
  }
}
