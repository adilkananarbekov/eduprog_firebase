import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_exception.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/models/schedule.dart';
import '../../core/providers/providers.dart';
import '../../core/security/role_access.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/page_header.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  static const _days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  bool _isWeekView = false;
  bool _isLoading = true;
  List<Schedule> _weeklySchedules = [];
  List<Schedule> _allSchedules = [];
  List<ClassGroup> _groups = [];
  ClassGroup? _selectedGroup;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null ||
        !RoleAccess.canAccessRoute(currentUser.role, '/admin/schedule')) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Your account does not have permission to view the schedule.';
      });
      return;
    }

    try {
      final scheduleService = ref.read(scheduleServiceProvider);
      final weeklySchedules = _sortSchedules(
        await scheduleService.getWeeklySchedule(),
      );
      final groups = _deriveGroupsFromSchedules(weeklySchedules);
      final selectedGroup = _resolveSelectedGroup(groups, _selectedGroup);
      final visibleSchedules = _filterSchedulesForGroup(
        weeklySchedules,
        selectedGroup,
      );

      debugPrint(
        '[SCHEDULE] loaded role=${currentUser.role.name} weekly=${weeklySchedules.length} groups=${groups.length}',
      );

      if (!mounted) return;
      setState(() {
        _weeklySchedules = weeklySchedules;
        _groups = groups;
        _selectedGroup = selectedGroup;
        _allSchedules = visibleSchedules;
        _isLoading = false;
        _errorMessage = null;
      });

      unawaited(_refreshGroups(weeklySchedules));
    } catch (e) {
      debugPrint('[SCHEDULE] load failed: $e');
      if (!mounted) return;
      setState(() {
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

  List<Schedule> _sortSchedules(List<Schedule> schedules) {
    final sorted = List<Schedule>.from(schedules);
    sorted.sort((a, b) {
      final dayCompare =
          _days.indexOf(a.dayOfWeek.toUpperCase()) -
          _days.indexOf(b.dayOfWeek.toUpperCase());
      if (dayCompare != 0) {
        return dayCompare;
      }
      return a.startTime.compareTo(b.startTime);
    });
    return sorted;
  }

  List<ClassGroup> _deriveGroupsFromSchedules(List<Schedule> schedules) {
    final groupsById = <int, ClassGroup>{};
    for (final schedule in schedules) {
      groupsById[schedule.classGroupId] = ClassGroup(
        id: schedule.classGroupId,
        name: schedule.classGroupName ?? 'Group #${schedule.classGroupId}',
      );
    }

    final groups = groupsById.values.toList();
    groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }

  List<ClassGroup> _mergeGroups(
    List<ClassGroup> primary,
    List<ClassGroup> fallback,
  ) {
    final groupsById = <int, ClassGroup>{};
    for (final group in [...primary, ...fallback]) {
      groupsById[group.id] = group;
    }

    final groups = groupsById.values.toList();
    groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }

  ClassGroup? _resolveSelectedGroup(
    List<ClassGroup> groups,
    ClassGroup? selectedGroup,
  ) {
    if (groups.isEmpty) {
      return null;
    }
    if (selectedGroup == null) {
      return groups.first;
    }
    for (final group in groups) {
      if (group.id == selectedGroup.id) {
        return group;
      }
    }
    return groups.first;
  }

  List<Schedule> _filterSchedulesForGroup(
    List<Schedule> schedules,
    ClassGroup? selectedGroup,
  ) {
    if (selectedGroup == null) {
      return schedules;
    }

    return schedules
        .where((schedule) => schedule.classGroupId == selectedGroup.id)
        .toList();
  }

  String _friendlyLoadError(Object error) {
    if (error is UnauthorizedException) {
      return 'Your session expired. Please sign in again.';
    }
    if (error is ForbiddenException) {
      return 'Your account does not have permission to view the schedule.';
    }
    if (error is NetworkException) {
      return 'Unable to reach the server. Check the backend connection.';
    }
    if (error is ApiTimeoutException) {
      return 'Schedule loading timed out. Please try again.';
    }
    if (error is ParseException) {
      return 'Schedule data was returned in an unexpected format.';
    }
    if (error is ServerException) {
      return 'The server returned an error while loading the schedule.';
    }
    return 'Failed to load schedule: ${error.toString()}';
  }

  Future<void> _refreshGroups(List<Schedule> weeklySchedules) async {
    final adminService = ref.read(adminServiceProvider);

    try {
      final groups = await adminService
          .getClassGroups()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => <ClassGroup>[],
          );
      final mergedGroups = _mergeGroups(
        groups,
        _deriveGroupsFromSchedules(weeklySchedules),
      );
      final selectedGroup = _resolveSelectedGroup(mergedGroups, _selectedGroup);

      if (!mounted) return;
      setState(() {
        _groups = mergedGroups;
        _selectedGroup = selectedGroup;
        _allSchedules = _filterSchedulesForGroup(
          _weeklySchedules,
          selectedGroup,
        );
      });
    } catch (e) {
      debugPrint('[SCHEDULE] group refresh skipped: $e');
    }
  }

  void _selectGroup(ClassGroup? group) {
    if (group == null) return;
    setState(() {
      _selectedGroup = group;
      _allSchedules = _filterSchedulesForGroup(_weeklySchedules, group);
    });
  }

  void _handleAddLesson() {
    context.push('/admin/week-schedule');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Use week schedule to add a lesson.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _selectedGroup == null
        ? 'Manage class schedules'
        : 'Showing ${_selectedGroup!.name} from this week\'s timetable';

    return Column(
      children: [
        PageHeader(
          title: 'Schedule',
          subtitle: subtitle,
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/admin/week-schedule'),
              icon: const Icon(Icons.calendar_view_week_outlined, size: 16),
              label: const Text('Week View'),
            ),
            ElevatedButton.icon(
              onPressed: _handleAddLesson,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Lesson'),
            ),
          ],
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
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
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 720;
                      final viewToggle = SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Day View'),
                            ),
                            ButtonSegment(value: true, label: Text('All Days')),
                          ],
                          selected: {_isWeekView},
                          onSelectionChanged: (s) =>
                              setState(() => _isWeekView = s.first),
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_groups.isNotEmpty) ...[
                              Text('Group', style: AppTextStyles.label),
                              const SizedBox(height: AppSpacing.xs),
                              DropdownButton<ClassGroup>(
                                value: _selectedGroup,
                                isExpanded: true,
                                items: _groups
                                    .map(
                                      (group) => DropdownMenuItem<ClassGroup>(
                                        value: group,
                                        child: Text(
                                          group.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _selectGroup,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            viewToggle,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          if (_groups.isNotEmpty) ...[
                            Text('Group:', style: AppTextStyles.label),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: DropdownButton<ClassGroup>(
                                  value: _selectedGroup,
                                  items: _groups
                                      .map(
                                        (group) =>
                                            DropdownMenuItem<ClassGroup>(
                                              value: group,
                                              child: Text(
                                                group.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: _selectGroup,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],
                          viewToggle,
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _isWeekView
                      ? _WeekView(
                          schedules: _allSchedules,
                          days: _days,
                          dayLabels: _dayLabels,
                        )
                      : _DayView(schedules: _allSchedules),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayView extends StatelessWidget {
  final List<Schedule> schedules;

  const _DayView({required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No schedule entries yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<Schedule>>{};
    for (final schedule in schedules) {
      grouped.putIfAbsent(schedule.dayOfWeek, () => []).add(schedule);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.sm,
                top: AppSpacing.md,
              ),
              child: Text(entry.key, style: AppTextStyles.heading4),
            ),
            ...entry.value.map(
              (schedule) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.subjectName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${schedule.classGroupName ?? 'Class'} · ${schedule.room ?? 'Room'}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${schedule.startTime} – ${schedule.endTime}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _WeekView extends StatelessWidget {
  final List<Schedule> schedules;
  final List<String> days;
  final List<String> dayLabels;

  const _WeekView({
    required this.schedules,
    required this.days,
    required this.dayLabels,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(days.length, (index) {
            final day = days[index];
            final dayLabel = dayLabels[index];
            final daySchedules = schedules
                .where((schedule) => schedule.dayOfWeek.toUpperCase() == day)
                .toList();

            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Center(
                      child: Text(dayLabel, style: AppTextStyles.label),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (daySchedules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text('No classes', style: AppTextStyles.caption),
                    )
                  else
                    ...daySchedules.map(
                      (schedule) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.subjectName,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              schedule.classGroupName ?? 'Class',
                              style: AppTextStyles.caption,
                            ),
                            Text(
                              '${schedule.startTime} – ${schedule.endTime}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
