import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_constants.dart';
import '../../core/api/api_exception.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/models/managed_user.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/page_header.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isLoadingUsers = false;
  String? _userManagementError;
  List<ManagedUser> _managedUsers = [];
  List<ClassGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserManagement());
  }

  Future<void> _loadUserManagement() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.role != UserRole.ADMIN) {
      return;
    }

    setState(() {
      _isLoadingUsers = true;
      _userManagementError = null;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final results = await Future.wait([
        adminService.listManagedUsers(),
        adminService.getClassGroups(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _managedUsers = results[0] as List<ManagedUser>;
        _groups = results[1] as List<ClassGroup>;
        _isLoadingUsers = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingUsers = false;
        _userManagementError = _friendlyManagementError(error);
      });
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${error.toString()}')),
        );
      }
    }
  }

  String _friendlyManagementError(Object error) {
    if (error is UnauthorizedException) {
      return 'Your session expired. Sign in again.';
    }
    if (error is ForbiddenException) {
      return 'Only administrators can manage accounts.';
    }
    if (error is ValidationException) {
      return error.message;
    }
    if (error is NetworkException) {
      return 'Unable to reach Firebase right now.';
    }
    if (error is ApiException) {
      return error.message;
    }
    return 'User management is unavailable right now.';
  }

  Future<void> _showCreateUserDialog(UserRole initialRole) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    var role = initialRole;
    int? selectedGroupId;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create ${role.displayName}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<UserRole>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.TEACHER,
                        child: Text('Teacher'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.STUDENT,
                        child: Text('Student'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() {
                        role = value;
                        if (role != UserRole.STUDENT) {
                          selectedGroupId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Temporary Password',
                    ),
                  ),
                  if (role == UserRole.STUDENT) ...[
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedGroupId,
                      decoration: const InputDecoration(
                        labelText: 'Class Group',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        ..._groups.map(
                          (group) => DropdownMenuItem<int?>(
                            value: group.id,
                            child: Text(group.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedGroupId = value),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (shouldCreate != true || !mounted) {
      return;
    }

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'First name, last name, email, and a 6+ character password are required.',
          ),
        ),
      );
      return;
    }

    try {
      final adminService = ref.read(adminServiceProvider);
      if (role == UserRole.STUDENT) {
        await adminService.createStudent(
          email: emailController.text.trim(),
          password: passwordController.text,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          classGroupId: selectedGroupId,
        );
      } else {
        await adminService.createTeacher(
          email: emailController.text.trim(),
          password: passwordController.text,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
        );
      }

      await _loadUserManagement();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${role.displayName} account created.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyManagementError(error))),
        );
      }
    }
  }

  Future<void> _showEditUserDialog(ManagedUser user) async {
    final emailController = TextEditingController(text: user.email);
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    var role = user.role;
    var isActive = user.isActive;
    int? selectedGroupId = user.classGroupId;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<UserRole>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.TEACHER,
                        child: Text('Teacher'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.STUDENT,
                        child: Text('Student'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() {
                        role = value;
                        if (role != UserRole.STUDENT) {
                          selectedGroupId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  if (role == UserRole.STUDENT) ...[
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedGroupId,
                      decoration: const InputDecoration(
                        labelText: 'Class Group',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        ..._groups.map(
                          (group) => DropdownMenuItem<int?>(
                            value: group.id,
                            child: Text(group.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedGroupId = value),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                    title: const Text('Account Active'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true || !mounted) {
      return;
    }

    try {
      await ref
          .read(adminServiceProvider)
          .updateManagedUser(
            uid: user.uid,
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            email: emailController.text.trim(),
            role: role.name,
            classGroupId: role == UserRole.STUDENT ? selectedGroupId : null,
            isActive: isActive,
          );
      await _loadUserManagement();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User updated.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyManagementError(error))),
        );
      }
    }
  }

  Future<void> _deleteUser(ManagedUser user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Delete ${user.fullName} (${user.email})? This also removes their Firebase sign-in account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await ref.read(adminServiceProvider).deleteManagedUser(user.uid);
      await _loadUserManagement();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User deleted.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyManagementError(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final supportedModules = const [
      'Firebase Auth',
      'Users',
      'Groups',
      'Teachers',
      'Students',
      'Firestore',
      'Cloud Functions',
    ];

    final accountSection = AppCard(
      header: Text('Account', style: AppTextStyles.heading4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadOnlyRow(label: 'Name', value: currentUser?.fullName ?? '—'),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyRow(label: 'Email', value: currentUser?.email ?? '—'),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyRow(
            label: 'Role',
            value: currentUser?.role.displayName ?? '—',
          ),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyRow(
            label: 'User ID',
            value: currentUser == null ? '—' : currentUser.userId.toString(),
          ),
        ],
      ),
    );

    final backendSection = AppCard(
      header: Text('Connected Backend', style: AppTextStyles.heading4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadOnlyRow(label: 'Base API', value: ApiConstants.baseApiUrl),
          const SizedBox(height: AppSpacing.md),
          _ReadOnlyRow(
            label: 'Auth Provider',
            value: 'Firebase Authentication',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Live modules',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: supportedModules
                .map((module) => _SupportChip(label: module))
                .toList(growable: false),
          ),
        ],
      ),
    );

    final appearanceSection = AppCard(
      header: Text('Appearance', style: AppTextStyles.heading4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<ThemeMode>(
            initialValue: themeMode,
            items: const [
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('Use device'),
              ),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (mode) async {
              if (mode == null) {
                return;
              }
              await ref.read(themeModeProvider.notifier).setThemeMode(mode);
            },
            decoration: const InputDecoration(),
          ),
        ],
      ),
    );

    final sessionSection = AppCard(
      header: Text('Session', style: AppTextStyles.heading4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accounts are Firebase-backed and can only be created by an administrator through the managed user flow.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context, ref),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );

    final userManagementSection = currentUser?.role != UserRole.ADMIN
        ? null
        : AppCard(
            header: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Management', style: AppTextStyles.heading4),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Admins create and manage teacher and student accounts here.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showCreateUserDialog(UserRole.TEACHER),
                      icon: const Icon(Icons.school_outlined, size: 16),
                      label: const Text('Add Teacher'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateUserDialog(UserRole.STUDENT),
                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                      label: const Text('Add Student'),
                    ),
                  ],
                ),
              ],
            ),
            child: _UserManagementSection(
              isLoading: _isLoadingUsers,
              errorMessage: _userManagementError,
              users: _managedUsers,
              onRetry: _loadUserManagement,
              onEdit: _showEditUserDialog,
              onDelete: _deleteUser,
            ),
          );

    return Column(
      children: [
        const PageHeader(
          title: 'Settings',
          subtitle:
              'Account, appearance, backend connection, and managed users.',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1080;
                final leftColumn = Column(
                  children: [
                    accountSection,
                    const SizedBox(height: AppSpacing.lg),
                    backendSection,
                    if (userManagementSection != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      userManagementSection,
                    ],
                  ],
                );
                final rightColumn = Column(
                  children: [
                    appearanceSection,
                    const SizedBox(height: AppSpacing.lg),
                    sessionSection,
                  ],
                );

                if (!isWide) {
                  return Column(
                    children: [
                      leftColumn,
                      const SizedBox(height: AppSpacing.lg),
                      rightColumn,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftColumn),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: rightColumn),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _UserManagementSection extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<ManagedUser> users;
  final Future<void> Function() onRetry;
  final ValueChanged<ManagedUser> onEdit;
  final ValueChanged<ManagedUser> onDelete;

  const _UserManagementSection({
    required this.isLoading,
    required this.errorMessage,
    required this.users,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            errorMessage!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.dangerTextOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
    }

    if (users.isEmpty) {
      return Text(
        'No managed users found yet.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textMutedOf(context),
        ),
      );
    }

    return Column(
      children: users
          .map((user) {
            final canManage = user.role != UserRole.ADMIN;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceStrongOf(context),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      child: Text(user.fullName.substring(0, 1).toUpperCase()),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                user.fullName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryOf(context),
                                ),
                              ),
                              _StatusChip(
                                label: user.role.displayName,
                                color: AppColors.primaryOf(context),
                              ),
                              _StatusChip(
                                label: user.isActive ? 'Active' : 'Disabled',
                                color: user.isActive
                                    ? AppColors.primaryOf(context)
                                    : AppColors.dangerTextOf(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user.email,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMutedOf(context),
                            ),
                          ),
                          if (user.classGroupName != null &&
                              user.classGroupName!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Group: ${user.classGroupName}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMutedOf(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canManage)
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton(
                            onPressed: () => onEdit(user),
                            child: const Text('Edit'),
                          ),
                          OutlinedButton(
                            onPressed: () => onDelete(user),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

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

class _SupportChip extends StatelessWidget {
  final String label;

  const _SupportChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrongOf(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimaryOf(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
