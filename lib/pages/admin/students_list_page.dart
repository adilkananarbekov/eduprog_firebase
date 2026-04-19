import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/models/student.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../widgets/page_header.dart';

class StudentsListPage extends ConsumerStatefulWidget {
  final int? initialGroupId;
  final String? initialGroupName;

  const StudentsListPage({
    super.key,
    this.initialGroupId,
    this.initialGroupName,
  });

  @override
  ConsumerState<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends ConsumerState<StudentsListPage> {
  final _searchController = TextEditingController();
  List<Student> _students = [];
  List<ClassGroup> _groups = [];
  int? _selectedGroupId;
  bool _limitedToTeachingGroups = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
    _loadStudents();
  }

  @override
  void didUpdateWidget(covariant StudentsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialGroupId != oldWidget.initialGroupId ||
        widget.initialGroupName != oldWidget.initialGroupName) {
      _selectedGroupId = widget.initialGroupId;
      _loadStudents();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final adminService = ref.read(adminServiceProvider);
    final currentUser = ref.read(currentUserProvider);

    try {
      if (currentUser?.role == UserRole.TEACHER) {
        final teacherResult = await _loadTeacherScopedStudents();
        if (!mounted) return;
        setState(() {
          _students = teacherResult.students;
          _groups = teacherResult.groups;
          _selectedGroupId = teacherResult.selectedGroupId;
          _limitedToTeachingGroups = true;
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      List<ClassGroup> groups = _groups;
      try {
        groups = await adminService.getClassGroups();
      } catch (e) {
        debugPrint('[STUDENTS] getClassGroups error: $e');
      }

      debugPrint(
        '[STUDENTS] load start role=${currentUser?.role.name} group=$_selectedGroupId',
      );
      final result = await adminService.getAccessibleStudents(
        classGroupId: _selectedGroupId,
      );

      if (!mounted) return;
      setState(() {
        _students = result.students;
        _groups = groups;
        _limitedToTeachingGroups = false;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint(
        '[STUDENTS] load failed role=${currentUser?.role.name} group=$_selectedGroupId error=$e',
      );
      final message = _friendlyLoadError(e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<_TeacherScopedStudentsResult> _loadTeacherScopedStudents() async {
    final adminService = ref.read(adminServiceProvider);
    final scheduleService = ref.read(scheduleServiceProvider);
    final schedules = await scheduleService.getWeeklySchedule();

    final groupsById = <int, ClassGroup>{};
    for (final schedule in schedules) {
      groupsById[schedule.classGroupId] = ClassGroup(
        id: schedule.classGroupId,
        name: schedule.classGroupName ?? 'Group #${schedule.classGroupId}',
      );
    }

    final groups = groupsById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (groups.isEmpty) {
      return const _TeacherScopedStudentsResult(
        groups: <ClassGroup>[],
        students: <Student>[],
      );
    }

    int? selectedGroupId = _selectedGroupId;
    if (selectedGroupId != null && !groupsById.containsKey(selectedGroupId)) {
      selectedGroupId = null;
    }

    if (selectedGroupId != null) {
      final students = await adminService.getStudentsByClass(selectedGroupId);
      return _TeacherScopedStudentsResult(
        groups: groups,
        students: students,
        selectedGroupId: selectedGroupId,
      );
    }

    final groupStudents = await Future.wait(
      groups.map(
        (group) => adminService
            .getStudentsByClass(group.id)
            .catchError((_) => <Student>[]),
      ),
    );

    final studentsById = <int, Student>{};
    for (final students in groupStudents) {
      for (final student in students) {
        studentsById[student.id] = student;
      }
    }

    final students = studentsById.values.toList()
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

    return _TeacherScopedStudentsResult(groups: groups, students: students);
  }

  String _friendlyLoadError(Object error) {
    if (error is UnauthorizedException) {
      return 'Your session expired. Please sign in again.';
    }
    if (error is ForbiddenException) {
      return error.message;
    }
    if (error is NetworkException) {
      return 'Unable to reach the server. Check the backend connection.';
    }
    if (error is ApiTimeoutException) {
      return 'Student loading timed out. Please try again.';
    }
    if (error is ParseException) {
      return 'Students were returned in an unexpected format.';
    }
    if (error is ServerException) {
      return 'The server returned an error while loading students.';
    }
    return 'Failed to load students: ${error.toString()}';
  }

  void _handleGroupFilterChanged(int? groupId) {
    if (_selectedGroupId == groupId) return;
    setState(() => _selectedGroupId = groupId);
    _loadStudents();
  }

  void _handleStudentTap(Student student) {
    context.push('/admin/students/${student.id}');
  }

  List<Student> get _filtered {
    var list = _students;
    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.fullName.toLowerCase().contains(q) ||
                (s.classGroupName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return list;
  }

  String? get _selectedGroupName {
    for (final group in _groups) {
      if (group.id == _selectedGroupId) {
        return group.name;
      }
    }
    if (_selectedGroupId == widget.initialGroupId) {
      return widget.initialGroupName;
    }
    return null;
  }

  String get _subtitle {
    final selectedGroupName = _selectedGroupName;
    if (selectedGroupName != null) {
      return '${_students.length} students in $selectedGroupName';
    }
    if (_limitedToTeachingGroups) {
      return '${_students.length} students across your teaching groups';
    }
    return '${_students.length} total students';
  }

  String get _emptyStateMessage {
    if (_searchController.text.isNotEmpty) {
      return 'No students match your search';
    }
    final selectedGroupName = _selectedGroupName;
    if (selectedGroupName != null) {
      return 'No students found in $selectedGroupName';
    }
    if (_limitedToTeachingGroups) {
      return 'No students found in your teaching groups';
    }
    return 'No students found';
  }

  List<DropdownMenuItem<int?>> get _groupFilterItems {
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('All groups')),
    ];

    final knownGroupIds = <int>{};
    for (final group in _groups) {
      knownGroupIds.add(group.id);
      items.add(
        DropdownMenuItem<int?>(value: group.id, child: Text(group.name)),
      );
    }

    if (_selectedGroupId != null && !knownGroupIds.contains(_selectedGroupId)) {
      items.add(
        DropdownMenuItem<int?>(
          value: _selectedGroupId,
          child: Text(_selectedGroupName ?? 'Group #$_selectedGroupId'),
        ),
      );
    }

    return items;
  }

  void _handleAddStudent() {
    _showAddStudentDialog();
  }

  Future<void> _showAddStudentDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    int? selectedClassGroupId;

    final adminService = ref.read(adminServiceProvider);
    List<ClassGroup> groups = [];
    try {
      groups = await adminService.getClassGroups();
    } catch (_) {
      // Allow creating student without group if groups fail to load.
    }

    if (!mounted) return;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int?>(
                  initialValue: selectedClassGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Class Group (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...groups.map(
                      (group) => DropdownMenuItem<int?>(
                        value: group.id,
                        child: Text(group.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedClassGroupId = value),
                ),
              ],
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

    if (shouldCreate != true) return;

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All required fields must be filled')),
        );
      }
      return;
    }

    try {
      await adminService.createStudent(
        email: emailController.text.trim(),
        password: passwordController.text,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        classGroupId: selectedClassGroupId,
      );
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create student: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canManageStudents = currentUser?.role == UserRole.ADMIN;
    final actions = <Widget>[
      if (_selectedGroupId != null)
        OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _handleGroupFilterChanged(null),
          icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
          label: const Text('All Students'),
        ),
      if (canManageStudents)
        ElevatedButton.icon(
          onPressed: _handleAddStudent,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Student'),
        ),
    ];

    return Column(
      children: [
        PageHeader(
          title: 'Students',
          subtitle: _subtitle,
          actions: actions.isEmpty ? null : actions,
        ),
        // Search + Filter
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final searchField = TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search students…',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  isDense: true,
                ),
              );

              final groupFilter = DropdownButtonFormField<int?>(
                key: ValueKey<int?>(_selectedGroupId),
                initialValue: _selectedGroupId,
                decoration: const InputDecoration(
                  labelText: 'Group',
                  isDense: true,
                ),
                items: _groupFilterItems,
                onChanged: _isLoading ? null : _handleGroupFilterChanged,
              );

              final loader = _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox.shrink();

              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: AppSpacing.sm),
                    groupFilter,
                    if (_limitedToTeachingGroups) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const _StudentsScopeNotice(
                        message:
                            'This teacher account is limited to groups from the current teaching schedule.',
                      ),
                    ],
                    if (_isLoading) ...[
                      const SizedBox(height: AppSpacing.sm),
                      loader,
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(width: 220, child: groupFilter),
                      if (_isLoading) ...[
                        const SizedBox(width: AppSpacing.sm),
                        loader,
                      ],
                    ],
                  ),
                  if (_limitedToTeachingGroups) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const _StudentsScopeNotice(
                      message:
                          'This teacher account only shows students from groups on the current teaching schedule.',
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? Center(
                  child: Text(
                    _emptyStateMessage,
                    style: AppTextStyles.bodyMedium,
                  ),
                )
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    if (constraints.maxWidth > 700) {
                      return _DesktopStudentTable(
                        students: _filtered,
                        onViewStudent: _handleStudentTap,
                      );
                    }
                    return _MobileStudentList(
                      students: _filtered,
                      onViewStudent: _handleStudentTap,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DesktopStudentTable extends StatelessWidget {
  final List<Student> students;
  final ValueChanged<Student> onViewStudent;

  const _DesktopStudentTable({
    required this.students,
    required this.onViewStudent,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLg),
                    topRight: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('Name', style: AppTextStyles.label),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Group', style: AppTextStyles.label),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Phone', style: AppTextStyles.label),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              ...students.asMap().entries.map((e) {
                final s = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.muted,
                                  child: Text(
                                    s.firstName[0].toUpperCase(),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    s.fullName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              s.classGroupName ?? 'No Group',
                              style: AppTextStyles.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              s.phoneNumber ?? 'N/A',
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextButton(
                              onPressed: () => onViewStudent(s),
                              child: const Text('View'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (e.key < students.length - 1)
                      const Divider(height: 1, color: AppColors.border),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileStudentList extends StatelessWidget {
  final List<Student> students;
  final ValueChanged<Student> onViewStudent;

  const _MobileStudentList({
    required this.students,
    required this.onViewStudent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: students.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final s = students[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.muted,
                child: Text(
                  s.firstName[0].toUpperCase(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.classGroupName ?? 'No Group',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onViewStudent(s),
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentsScopeNotice extends StatelessWidget {
  final String message;

  const _StudentsScopeNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherScopedStudentsResult {
  final List<ClassGroup> groups;
  final List<Student> students;
  final int? selectedGroupId;

  const _TeacherScopedStudentsResult({
    required this.groups,
    required this.students,
    this.selectedGroupId,
  });
}
