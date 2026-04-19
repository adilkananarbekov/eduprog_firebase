import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_spacing.dart';
import '../core/providers/providers.dart';
import '../core/router/app_back_navigation.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class ParentLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const ParentLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  static const _navItems = [
    _ParentNavItem('Home', '/parent', Icons.home_outlined, Icons.home),
    _ParentNavItem(
      'Schedule',
      '/parent/schedule',
      Icons.calendar_today_outlined,
      Icons.calendar_today,
    ),
    _ParentNavItem(
      'Records',
      '/parent/records',
      Icons.school_outlined,
      Icons.school,
    ),
    _ParentNavItem(
      'Updates',
      '/parent/announcements',
      Icons.message_outlined,
      Icons.message,
    ),
  ];

  int get _currentIndex {
    for (int i = 0; i < _navItems.length; i++) {
      if (currentRoute == _navItems[i].route ||
          (_navItems[i].route != '/parent' &&
              currentRoute.startsWith(_navItems[i].route))) {
        return i;
      }
    }
    return 0;
  }

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
    final canGoBack = AppBackNavigation.canGoBack(context, currentRoute);
    final fallbackRoute = AppBackNavigation.fallbackFor(currentRoute);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showBottomLabels = screenWidth >= 390;
    final surface = AppColors.surfaceOf(context);
    final canvas = AppColors.canvasOf(context);
    final border = AppColors.borderOf(context);
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && fallbackRoute != null) {
          context.go(fallbackRoute);
        }
      },
      child: Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          automaticallyImplyLeading: false,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EduOps',
                      style: AppTextStyles.heading4.copyWith(
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Family portal',
                      style: AppTextStyles.caption.copyWith(color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.campaign_outlined, color: textMuted),
              onPressed: currentRoute == '/parent/announcements'
                  ? null
                  : () => context.push('/parent/announcements'),
            ),
            IconButton(
              icon: Icon(Icons.person_outline, color: textMuted),
              onPressed: currentRoute == '/parent/settings'
                  ? null
                  : () => context.push('/parent/settings'),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: textMuted),
              onPressed: () => _handleLogout(context, ref),
              tooltip: 'Logout',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: border),
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
        bottomNavigationBar: SafeArea(
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
                  color: AppColors.shadowOf(context).withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              showSelectedLabels: showBottomLabels,
              showUnselectedLabels: showBottomLabels,
              onTap: (index) => context.go(_navItems[index].route),
              items: _navItems
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
      ),
    );
  }
}

class _ParentNavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;

  const _ParentNavItem(this.label, this.route, this.icon, this.activeIcon);
}
