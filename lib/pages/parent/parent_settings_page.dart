import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_card.dart';

class ParentSettingsPage extends ConsumerWidget {
  const ParentSettingsPage({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final initials = (currentUser?.fullName.isNotEmpty ?? false)
        ? currentUser!.fullName
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join()
        : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Account, appearance, and session controls.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primarySoftOf(context),
              child: Text(
                initials,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryOf(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            header: Text('Account', style: AppTextStyles.heading4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReadOnlyField(
                  label: 'Name',
                  value: currentUser?.fullName ?? '—',
                ),
                const SizedBox(height: AppSpacing.md),
                _ReadOnlyField(
                  label: 'Email',
                  value: currentUser?.email ?? '—',
                ),
                const SizedBox(height: AppSpacing.md),
                _ReadOnlyField(
                  label: 'Role',
                  value: currentUser?.role.displayName ?? '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            header: Text('Appearance', style: AppTextStyles.heading4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<ThemeMode>(
                  initialValue: themeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Use device'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (mode) async {
                    if (mode == null) {
                      return;
                    }
                    await ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(mode);
                  },
                  decoration: const InputDecoration(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            header: Text('Backend', style: AppTextStyles.heading4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReadOnlyField(
                  label: 'Base API',
                  value: ApiConstants.baseApiUrl,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Profile edits are controlled on the server. This app currently exposes read-only account data for student sessions.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleSignOut(context, ref),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            value,
            maxLines: 3,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
