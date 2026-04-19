import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_spacing.dart';
import '../core/models/user_role.dart';
import '../core/providers/providers.dart';
import '../core/router/app_back_navigation.dart';
import '../core/security/role_access.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AdminLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  static const _navItems = [
    _NavItem('Home', '/admin', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem(
      'Students',
      '/admin/students',
      Icons.people_alt_outlined,
      Icons.people_alt,
    ),
    _NavItem('Groups', '/admin/groups', Icons.groups_outlined, Icons.groups),
    _NavItem(
      'Timetable',
      '/admin/schedule',
      Icons.calendar_today_outlined,
      Icons.calendar_today,
    ),
    _NavItem(
      'Attendance',
      '/admin/attendance',
      Icons.fact_check_outlined,
      Icons.fact_check,
    ),
    _NavItem(
      'Reports',
      '/admin/reports',
      Icons.bar_chart_outlined,
      Icons.bar_chart,
    ),
    _NavItem(
      'Settings',
      '/admin/settings',
      Icons.settings_outlined,
      Icons.settings,
    ),
  ];

  static const _mobileNavItems = [
    _NavItem('Home', '/admin', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem(
      'Students',
      '/admin/students',
      Icons.people_alt_outlined,
      Icons.people_alt,
    ),
    _NavItem('Groups', '/admin/groups', Icons.groups_outlined, Icons.groups),
    _NavItem(
      'Timetable',
      '/admin/schedule',
      Icons.calendar_today_outlined,
      Icons.calendar_today,
    ),
    _NavItem('Profile', '/admin/settings', Icons.person_outline, Icons.person),
  ];

  static const _mobileDrawerItems = [
    _NavItem(
      'Attendance',
      '/admin/attendance',
      Icons.fact_check_outlined,
      Icons.fact_check,
    ),
    _NavItem(
      'Reports',
      '/admin/reports',
      Icons.bar_chart_outlined,
      Icons.bar_chart,
    ),
    _NavItem(
      'Updates',
      '/admin/announcements',
      Icons.campaign_outlined,
      Icons.campaign,
    ),
  ];

  static bool isRouteActive(String currentRoute, String route) {
    return currentRoute == route ||
        (route != '/admin' && currentRoute.startsWith(route));
  }

  static List<_NavItem> _visibleNavItemsFor(
    UserRole? role,
    List<_NavItem> items,
  ) {
    if (role == null) {
      return items;
    }

    return items
        .where((item) => RoleAccess.canAccessRoute(role, item.route))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        if (isDesktop) {
          return _DesktopLayout(currentRoute: currentRoute, child: child);
        }
        return _MobileLayout(currentRoute: currentRoute, child: child);
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const _DesktopLayout({required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasOf(context),
      body: Row(
        children: [
          _Sidebar(currentRoute: currentRoute),
          Expanded(
            child: SafeArea(
              minimum: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.borderOf(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowOf(
                        context,
                      ).withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final String currentRoute;

  const _Sidebar({required this.currentRoute});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userInitial = _userInitial(
      currentUser?.firstName,
      currentUser?.email,
    );
    final visibleNavItems = AdminLayout._visibleNavItemsFor(
      currentUser?.role,
      AdminLayout._navItems,
    );
    final railForeground = AppColors.railForegroundOf(context);
    final border = AppColors.borderOf(context);
    final surface = AppColors.surfaceOf(context);
    final primary = AppColors.primaryOf(context);
    final primarySoft = AppColors.primarySoftOf(context);

    return Container(
      width: AppSpacing.sidebarWidth,
      color: AppColors.canvasOf(context),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        0,
        AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.railGradientOf(context),
            border: Border.all(color: border),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: surface.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primarySoft,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Icon(Icons.school_rounded, color: primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EduOps',
                              style: AppTextStyles.heading4.copyWith(
                                color: railForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'School operations workspace',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: railForeground.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Workspace',
                  style: AppTextStyles.eyebrow.copyWith(
                    color: railForeground.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: visibleNavItems
                        .map(
                          (item) => _SidebarNavItem(
                            item: item,
                            currentRoute: currentRoute,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: surface.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: primarySoft,
                        child: Text(
                          userInitial,
                          style: AppTextStyles.label.copyWith(color: primary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.fullName ?? 'User',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: railForeground,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentUser?.email ?? '',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: railForeground.withValues(alpha: 0.72),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _handleLogout(context, ref),
                        icon: const Icon(Icons.logout),
                        color: railForeground,
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final _NavItem item;
  final String currentRoute;

  const _SidebarNavItem({required this.item, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isActive = AdminLayout.isRouteActive(currentRoute, item.route);
    final railForeground = AppColors.railForegroundOf(context);
    final primary = AppColors.primaryOf(context);
    final primarySoft = AppColors.primarySoftOf(context);
    final border = AppColors.borderOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isActive ? primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: isActive ? border : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 20,
                color: isActive
                    ? primary
                    : railForeground.withValues(alpha: 0.76),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isActive
                        ? primary
                        : railForeground.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const _MobileLayout({required this.child, required this.currentRoute});

  int? get _currentBottomIndex {
    for (int i = 0; i < AdminLayout._mobileNavItems.length; i++) {
      if (AdminLayout.isRouteActive(
        currentRoute,
        AdminLayout._mobileNavItems[i].route,
      )) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final canGoBack = AppBackNavigation.canGoBack(context, currentRoute);
    final fallbackRoute = AppBackNavigation.fallbackFor(currentRoute);
    final userInitial = _userInitial(
      currentUser?.firstName,
      currentUser?.email,
    );
    final visibleDrawerItems = AdminLayout._visibleNavItemsFor(
      currentUser?.role,
      AdminLayout._mobileDrawerItems,
    );
    final visibleBottomNavItems = AdminLayout._visibleNavItemsFor(
      currentUser?.role,
      AdminLayout._mobileNavItems,
    );
    final currentBottomIndex = _currentBottomIndex;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showBottomLabels = screenWidth >= 390;
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final primary = AppColors.primaryOf(context);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && fallbackRoute != null) {
          context.go(fallbackRoute);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvasOf(context),
        appBar: AppBar(
          automaticallyImplyLeading: !canGoBack,
          leading: canGoBack
              ? IconButton(
                  onPressed: () =>
                      AppBackNavigation.handleBack(context, currentRoute),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  tooltip: 'Back',
                )
              : null,
          titleSpacing: AppSpacing.md,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoftOf(context),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.school_rounded, color: primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'EduOps',
                  style: AppTextStyles.heading4.copyWith(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.campaign_outlined, color: textMuted),
              onPressed: currentRoute == '/admin/announcements'
                  ? null
                  : () => context.push('/admin/announcements'),
              tooltip: 'Updates',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: border),
          ),
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.railGradientOf(context),
            ),
            child: SafeArea(
              minimum: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'More tools',
                    style: AppTextStyles.heading4.copyWith(
                      color: AppColors.railForegroundOf(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...visibleDrawerItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        tileColor:
                            AdminLayout.isRouteActive(currentRoute, item.route)
                            ? AppColors.primarySoftOf(context)
                            : AppColors.surfaceOf(
                                context,
                              ).withValues(alpha: 0.74),
                        leading: Icon(
                          AdminLayout.isRouteActive(currentRoute, item.route)
                              ? item.activeIcon
                              : item.icon,
                          color:
                              AdminLayout.isRouteActive(
                                currentRoute,
                                item.route,
                              )
                              ? primary
                              : AppColors.railForegroundOf(
                                  context,
                                ).withValues(alpha: 0.74),
                        ),
                        title: Text(
                          item.label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color:
                                AdminLayout.isRouteActive(
                                  currentRoute,
                                  item.route,
                                )
                                ? primary
                                : AppColors.railForegroundOf(
                                    context,
                                  ).withValues(alpha: 0.88),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(item.route);
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoftOf(context),
                      child: Text(
                        userInitial,
                        style: AppTextStyles.label.copyWith(color: primary),
                      ),
                    ),
                    title: Text(
                      currentUser?.fullName ?? 'User',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.railForegroundOf(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      currentUser?.email ?? '',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.railForegroundOf(
                          context,
                        ).withValues(alpha: 0.72),
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        try {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .logout();
                          if (context.mounted) context.go('/login');
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logout failed: ${e.toString()}'),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        Icons.logout,
                        color: AppColors.railForegroundOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: currentBottomIndex == null
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowOf(
                          context,
                        ).withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    currentIndex: currentBottomIndex,
                    showSelectedLabels: showBottomLabels,
                    showUnselectedLabels: showBottomLabels,
                    onTap: (index) =>
                        context.go(visibleBottomNavItems[index].route),
                    items: visibleBottomNavItems
                        .map(
                          (item) => BottomNavigationBarItem(
                            icon: Icon(item.icon),
                            activeIcon: Icon(item.activeIcon),
                            label: item.label,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
        body: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

String _userInitial(String? name, String? email) {
  final candidates = [name, email];
  for (final candidate in candidates) {
    final trimmed = candidate?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed.substring(0, 1).toUpperCase();
    }
  }
  return 'U';
}

class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.label, this.route, this.icon, this.activeIcon);
}
