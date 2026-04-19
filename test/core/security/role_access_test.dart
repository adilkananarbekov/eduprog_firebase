import 'package:eduprog_firebase/core/models/user_role.dart';
import 'package:eduprog_firebase/core/security/role_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoleAccess.defaultRouteFor', () {
    test('returns parent shell for students', () {
      expect(RoleAccess.defaultRouteFor(UserRole.STUDENT), '/parent');
    });

    test('returns admin shell for staff roles', () {
      expect(RoleAccess.defaultRouteFor(UserRole.TEACHER), '/admin');
      expect(RoleAccess.defaultRouteFor(UserRole.ADMIN), '/admin');
      expect(RoleAccess.defaultRouteFor(UserRole.ACCOUNTANT), '/admin');
    });
  });

  group('RoleAccess.canAccessRoute', () {
    test('blocks student access to admin routes', () {
      expect(RoleAccess.canAccessRoute(UserRole.STUDENT, '/parent'), isTrue);
      expect(RoleAccess.canAccessRoute(UserRole.STUDENT, '/admin'), isFalse);
      expect(
        RoleAccess.canAccessRoute(UserRole.STUDENT, '/admin/students/42'),
        isFalse,
      );
    });

    test('lets teachers open admin routes and rely on backend checks', () {
      expect(RoleAccess.canAccessRoute(UserRole.TEACHER, '/admin'), isTrue);
      expect(
        RoleAccess.canAccessRoute(UserRole.TEACHER, '/admin/students'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.TEACHER, '/admin/students/42'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.TEACHER, '/admin/attendance/12'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.TEACHER, '/admin/billing'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.TEACHER, '/admin/reports'),
        isTrue,
      );
    });

    test('keeps admin access broad', () {
      expect(
        RoleAccess.canAccessRoute(UserRole.ADMIN, '/admin/billing'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.ADMIN, '/admin/reports'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.ADMIN, '/admin/announcements'),
        isTrue,
      );
    });

    test('lets accountants open admin routes and rely on backend checks', () {
      expect(RoleAccess.canAccessRoute(UserRole.ACCOUNTANT, '/admin'), isTrue);
      expect(
        RoleAccess.canAccessRoute(UserRole.ACCOUNTANT, '/admin/billing'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.ACCOUNTANT, '/admin/settings'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.ACCOUNTANT, '/admin/announcements'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.ACCOUNTANT, '/admin/students'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.ACCOUNTANT, '/admin/groups'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.ACCOUNTANT, '/admin/attendance'),
        isTrue,
      );
      expect(
        RoleAccess.canAccessRoute(UserRole.ACCOUNTANT, '/admin/reports'),
        isTrue,
      );
    });
  });
}
