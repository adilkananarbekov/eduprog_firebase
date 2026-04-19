import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_exception.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../core/security/role_access.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/page_header.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  List<ClassGroup> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null ||
        !RoleAccess.canAccessRoute(currentUser.role, '/admin/groups')) {
      if (!mounted) return;
      setState(() {
        _groups = [];
        _isLoading = false;
        _errorMessage = 'Your account does not have permission to view groups.';
      });
      return;
    }

    try {
      final adminService = ref.read(adminServiceProvider);
      final groups = await adminService.getClassGroups();
      debugPrint(
        '[GROUPS] loaded role=${currentUser.role.name} count=${groups.length}',
      );

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _groups = [];
        _isLoading = false;
        _errorMessage = _friendlyLoadError(e);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _friendlyLoadError(Object error) {
    if (error is UnauthorizedException) {
      return 'Your session expired. Please sign in again.';
    }
    if (error is ForbiddenException) {
      return 'Your account does not have permission to view groups.';
    }
    if (error is NetworkException) {
      return 'Unable to reach the server. Check the backend connection.';
    }
    if (error is ApiTimeoutException) {
      return 'Group loading timed out. Please try again.';
    }
    if (error is ParseException) {
      return 'Groups were returned in an unexpected format.';
    }
    if (error is ServerException) {
      return 'The server returned an error while loading groups.';
    }
    return 'Failed to load groups: ${error.toString()}';
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final gradeController = TextEditingController();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Grade'),
            ),
          ],
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
    );

    if (shouldCreate != true || !mounted) return;
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group name is required')));
      return;
    }

    try {
      final adminService = ref.read(adminServiceProvider);
      await adminService.createClassGroup(
        name: nameController.text.trim(),
        grade: int.tryParse(gradeController.text.trim()),
      );
      await _loadGroups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canManageGroups = currentUser?.role == UserRole.ADMIN;

    return Column(
      children: [
        PageHeader(
          title: 'Groups',
          subtitle:
              '${_groups.length} total groups${_groups.isEmpty ? '' : ' · Tap a group to view students'}',
          actions: canManageGroups
              ? [
                  ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Group'),
                  ),
                ]
              : null,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.groups_2_outlined,
                          size: 48,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _errorMessage!,
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: _loadGroups,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _groups.isEmpty
              ? Center(
                  child: Text(
                    'No groups found',
                    style: AppTextStyles.bodyMedium,
                  ),
                )
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    final cols = constraints.maxWidth > 1380
                        ? 4
                        : constraints.maxWidth > 960
                        ? 3
                        : constraints.maxWidth > 640
                        ? 2
                        : 1;
                    final ratio = cols >= 4
                        ? 1.28
                        : cols == 3
                        ? 1.4
                        : cols == 2
                        ? 1.5
                        : 1.34;
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: ratio,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      itemCount: _groups.length,
                      itemBuilder: (_, i) => _GroupCard(
                        group: _groups[i],
                        onTap: () {
                          final route = Uri(
                            path: '/admin/students',
                            queryParameters: {
                              'groupId': _groups[i].id.toString(),
                              'groupName': _groups[i].name,
                            },
                          ).toString();
                          context.push(route);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final ClassGroup group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  String _buildMeta(ClassGroup group) {
    return 'Grade ${group.grade?.toString() ?? '-'}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeader = constraints.maxWidth < 250;
              final compactFooter = constraints.maxWidth < 280;

              final titleBlock = Text(
                group.name,
                style: AppTextStyles.heading4,
                maxLines: compactHeader ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              );

              final statusBadge = const AppBadge(
                text: 'Active',
                variant: BadgeVariant.active,
              );

              final footerMeta = Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 14,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${group.studentCount ?? 0} students',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );

              final actionLink = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'View students',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compactHeader)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleBlock,
                        const SizedBox(height: AppSpacing.sm),
                        statusBadge,
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: titleBlock),
                        const SizedBox(width: AppSpacing.xs),
                        statusBadge,
                      ],
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _buildMeta(group),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (compactFooter)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        footerMeta,
                        const SizedBox(height: AppSpacing.sm),
                        actionLink,
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: footerMeta),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(child: actionLink),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
