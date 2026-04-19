import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/api/api_exception.dart';
import '../core/constants/app_spacing.dart';
import '../core/providers/providers.dart';
import '../core/security/role_access.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _loadedSavedEmail = false;

  @override
  void initState() {
    super.initState();
    _restoreSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _restoreSavedCredentials() async {
    // On web, browser password managers can visually autofill fields before
    // Flutter's controllers see those values. Avoid racing that with our own
    // saved-email restore.
    if (kIsWeb) {
      return;
    }

    final authService = ref.read(authServiceProvider);
    final savedEmail = await authService.getSavedEmail();
    if (!mounted) return;

    if (_emailController.text.isEmpty && savedEmail != null) {
      _emailController.text = savedEmail;
    }

    setState(() => _loadedSavedEmail = true);
  }

  Future<void> _commitPendingAutofill() async {
    FocusManager.instance.primaryFocus?.unfocus();
    TextInput.finishAutofillContext(shouldSave: false);
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _handleLogin() async {
    await _commitPendingAutofill();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).login(email, password);

      if (mounted) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          context.go(RoleAccess.defaultRouteFor(user.role));
        }
      }
    } on ApiException catch (e) {
      if (mounted) _showErrorDialog(e.message);
    } catch (_) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final canvas = AppColors.canvasOf(context);
    final surface = AppColors.surfaceOf(context);
    final surfaceStrong = AppColors.surfaceStrongOf(context);
    final primary = AppColors.primaryOf(context);
    final primaryStrong = AppColors.primaryStrongOf(context);
    final accent = AppColors.accentOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;
                final sidePanel = _BrandPanel(
                  primary: primary,
                  primaryStrong: primaryStrong,
                  accent: accent,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  isDark: isDark,
                );

                final formPanel = Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      margin: const EdgeInsets.all(AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXl,
                        ),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowOf(
                              context,
                            ).withValues(alpha: 0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Sign in',
                                style: AppTextStyles.heading2.copyWith(
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Access today’s classes, attendance, records, and updates.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text('Email', style: AppTextStyles.label),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                enabled: !_isLoading,
                                validator: _validateEmail,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_passwordFocusNode);
                                },
                                decoration: InputDecoration(
                                  hintText: 'admin@eduops.kg',
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                    size: 18,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text('Password', style: AppTextStyles.label),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                enableSuggestions: false,
                                autocorrect: false,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                enabled: !_isLoading,
                                validator: _validatePassword,
                                onFieldSubmitted: (_) {
                                  if (!_isLoading) {
                                    _handleLogin();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: textMuted,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text('Enter Workspace'),
                              ),
                              if (_loadedSavedEmail &&
                                  _emailController.text.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'The last used email was autofilled for quicker sign-in.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: surfaceStrong,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user_outlined,
                                      color: primary,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        'Accounts are provisioned by an administrator. Teachers and students cannot self-register.',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );

                if (!isWide) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        formPanel,
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: sidePanel,
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: sidePanel,
                      ),
                    ),
                    Expanded(child: formPanel),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final Color primary;
  final Color primaryStrong;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  const _BrandPanel({
    required this.primary,
    required this.primaryStrong,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textOnPanel = AppColors.textPrimaryOf(context);
    final textMutedOnPanel = AppColors.textMutedOf(context);
    final panelBorder = AppColors.borderOf(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'EduOps',
            style: AppTextStyles.heading1.copyWith(color: textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'School operations, redesigned for clarity and speed.',
            style: AppTextStyles.heading3.copyWith(color: textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'A unified workspace for attendance, schedules, student records, and family communication.',
            style: AppTextStyles.bodyLarge.copyWith(color: textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradientOf(context),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: panelBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowOf(context).withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MiniChip(
                      label: 'Today',
                      background: AppColors.surfaceOf(context),
                      foreground: primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MiniChip(
                      label: 'Fast attendance',
                      background: AppColors.primarySoftOf(context),
                      foreground: primaryStrong,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Built for schools that need the day to stay under control.',
                  style: AppTextStyles.heading3.copyWith(color: textOnPanel),
                ),
                const SizedBox(height: AppSpacing.md),
                _PreviewRow(
                  icon: Icons.fact_check_outlined,
                  title: 'Attendance workflow',
                  meta: 'Close daily rosters from one place',
                  color: primaryStrong,
                ),
                const SizedBox(height: AppSpacing.sm),
                _PreviewRow(
                  icon: Icons.school_outlined,
                  title: 'Student records',
                  meta: 'Open marks, groups, and profiles quickly',
                  color: accent,
                ),
                const SizedBox(height: AppSpacing.sm),
                _PreviewRow(
                  icon: Icons.campaign_outlined,
                  title: 'Family updates',
                  meta: 'Share schedule changes and announcements',
                  color: primary,
                ),
              ],
            ),
          ),
          if (!isDark) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Bishkek-ready. Family portal included. Fast enough for the first lesson bell.',
              style: AppTextStyles.bodySmall.copyWith(color: textMutedOnPanel),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String meta;
  final Color color;

  const _PreviewRow({
    required this.icon,
    required this.title,
    required this.meta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MiniChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: foreground),
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context).withValues(alpha: 0.14);
    final accent = AppColors.accentOf(context).withValues(alpha: 0.12);

    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -60,
          child: _SoftBlob(size: 320, color: primary),
        ),
        Positioned(
          right: -80,
          top: -40,
          child: _SoftBlob(size: 280, color: accent),
        ),
        Positioned(
          left: 20,
          bottom: -140,
          child: _SoftBlob(size: 360, color: primary),
        ),
        Positioned(
          right: -110,
          bottom: -100,
          child: _SoftBlob(size: 340, color: accent),
        ),
      ],
    );
  }
}

class _SoftBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}
