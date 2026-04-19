import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../layouts/admin_layout.dart';
import '../../layouts/parent_layout.dart';
import '../../pages/login_page.dart';
import '../../pages/admin/admin_dashboard_page.dart';
import '../../pages/admin/students_list_page.dart';
import '../../pages/admin/student_profile_page.dart';
import '../../pages/admin/groups_page.dart';
import '../../pages/admin/schedule_page.dart';
import '../../pages/admin/week_schedule_page.dart';
import '../../pages/admin/attendance_marking_page.dart';
import '../../pages/admin/reports_page.dart';
import '../../pages/admin/settings_page.dart';
import '../../pages/parent/parent_dashboard_page.dart';
import '../../pages/parent/parent_records_page.dart';
import '../../pages/parent/mobile_schedule_page.dart';
import '../../pages/parent/announcements_page.dart';
import '../../pages/parent/parent_settings_page.dart';
import '../../pages/not_found_page.dart';
import '../../pages/splash_page.dart';
import '../providers/providers.dart';
import '../security/role_access.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => const NotFoundPage(),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isSplashRoute = state.matchedLocation == '/splash';
      final isLoginRoute = state.matchedLocation == '/login';

      if (authState.isLoading) {
        return isSplashRoute ? null : '/splash';
      }

      final currentUser = authState.value;
      final isAuthenticated = currentUser != null;

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (!isAuthenticated && isSplashRoute) {
        return '/login';
      }

      if (isAuthenticated && (isLoginRoute || isSplashRoute)) {
        return RoleAccess.defaultRouteFor(currentUser.role);
      }

      if (isAuthenticated &&
          !RoleAccess.canAccessRoute(currentUser.role, state.matchedLocation)) {
        return RoleAccess.defaultRouteFor(currentUser.role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) =>
            AdminLayout(currentRoute: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => StudentsListPage(
              initialGroupId: int.tryParse(
                state.uri.queryParameters['groupId'] ?? '',
              ),
              initialGroupName: state.uri.queryParameters['groupName'],
            ),
          ),
          GoRoute(
            path: '/admin/students/:id',
            builder: (context, state) =>
                StudentProfilePage(studentId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: '/admin/groups',
            builder: (context, state) => const GroupsPage(),
          ),
          GoRoute(
            path: '/admin/schedule',
            builder: (context, state) => const SchedulePage(),
          ),
          GoRoute(
            path: '/admin/week-schedule',
            builder: (context, state) => const WeekSchedulePage(),
          ),
          GoRoute(
            path: '/admin/attendance',
            builder: (context, state) => const AttendanceMarkingPage(),
          ),
          GoRoute(
            path: '/admin/attendance/:groupId',
            builder: (context, state) =>
                AttendanceMarkingPage(groupId: state.pathParameters['groupId']),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/admin/announcements',
            builder: (context, state) => const AnnouncementsPage(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ParentLayout(currentRoute: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/parent',
            builder: (context, state) => const ParentDashboardPage(),
          ),
          GoRoute(
            path: '/parent/schedule',
            builder: (context, state) => const MobileSchedulePage(),
          ),
          GoRoute(
            path: '/parent/records',
            builder: (context, state) => const ParentRecordsPage(),
          ),
          GoRoute(
            path: '/parent/announcements',
            builder: (context, state) => const AnnouncementsPage(),
          ),
          GoRoute(
            path: '/parent/settings',
            builder: (context, state) => const ParentSettingsPage(),
          ),
        ],
      ),
    ],
  );

  ref.listen(authNotifierProvider, (previous, next) => router.refresh());
  ref.onDispose(router.dispose);

  return router;
});
