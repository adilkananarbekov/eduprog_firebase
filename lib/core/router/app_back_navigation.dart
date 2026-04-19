import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Centralized fallback rules for Android/iOS back navigation.
class AppBackNavigation {
  static String? fallbackFor(String route) {
    final normalizedRoute = Uri.parse(route).path;

    if (normalizedRoute.startsWith('/admin/students/')) {
      return '/admin/students';
    }

    if (normalizedRoute == '/admin/week-schedule') {
      return '/admin/schedule';
    }

    if (normalizedRoute.startsWith('/admin/') && normalizedRoute != '/admin') {
      return '/admin';
    }

    if (normalizedRoute.startsWith('/parent/') &&
        normalizedRoute != '/parent') {
      return '/parent';
    }

    return null;
  }

  static bool canGoBack(BuildContext context, String route) {
    return context.canPop() || fallbackFor(route) != null;
  }

  static void handleBack(BuildContext context, String route) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final fallbackRoute = fallbackFor(route);
    if (fallbackRoute != null) {
      context.go(fallbackRoute);
    }
  }
}
