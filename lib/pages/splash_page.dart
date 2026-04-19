import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_spacing.dart';
import '../core/providers/providers.dart';
import '../core/security/role_access.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // If auth already resolved before this widget mounted, navigate immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isLoading) {
        _navigate(authState);
      }
    });
  }

  void _navigate(AsyncValue authState) {
    if (!mounted) return;
    final user = authState.value;
    if (user != null) {
      context.go(RoleAccess.defaultRouteFor(user.role));
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes and navigate when resolved
    ref.listen(authNotifierProvider, (previous, next) {
      if (!next.isLoading) {
        _navigate(next);
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text('Restoring session...', style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
