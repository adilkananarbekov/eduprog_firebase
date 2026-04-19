import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/class_group.dart';
import '../../core/models/schedule.dart';
import '../../core/models/subject.dart';
import '../../core/models/teacher.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/page_header.dart';

enum _WeekFilterMode { all, group, teacher, subject }

class WeekSchedulePage extends ConsumerStatefulWidget {
  const WeekSchedulePage({super.key});

  @override
  ConsumerState<WeekSchedulePage> createState() => _WeekSchedulePageState();
}

class _WeekSchedulePageState extends ConsumerState<WeekSchedulePage> {
  static const _orderedDays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  static const _dayLabels = {
    'MONDAY': 'Mon',
    'TUESDAY': 'Tue',
    'WEDNESDAY': 'Wed',
    'THURSDAY': 'Thu',
    'FRIDAY': 'Fri',
    'SATURDAY': 'Sat',
    'SUNDAY': 'Sun',
  };

  bool _isLoading = true;
  String? _errorMessage;
  List<Schedule> _weeklySchedules = [];
  List<Schedule> _displaySchedules = [];
  List<ClassGroup> _groups = [];
  List<Teacher> _teachers = [];
  List<Subject> _subjects = [];
  _WeekFilterMode _filterMode = _WeekFilterMode.all;
  ClassGroup? _selectedGroup;
  Teacher? _selectedTeacher;
  Subject? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final scheduleService = ref.read(scheduleServiceProvider);

      final results = await Future.wait<dynamic>([
        scheduleService.getWeeklySchedule(),
        adminService.getClassGroups().catchError((_) => <ClassGroup>[]),
        adminService.getTeachers().catchError((_) => <Teacher>[]),
        adminService.getSubjects().catchError((_) => <Subject>[]),
      ]);

      final weeklySchedules = _sortSchedules(results[0] as List<Schedule>);
      final groups = _mergeGroups(
        results[1] as List<ClassGroup>,
        _deriveGroups(weeklySchedules),
      );
      final teachers = _mergeTeachers(
        results[2] as List<Teacher>,
        _deriveTeachers(weeklySchedules),
      );
      final subjects = _mergeSubjects(
        results[3] as List<Subject>,
        _deriveSubjects(weeklySchedules),
      );
      final selectedGroup = _resolveSelectedGroup(groups, _selectedGroup);
      final selectedTeacher = _resolveSelectedTeacher(
        teachers,
        _selectedTeacher,
      );
      final selectedSubject = _resolveSelectedSubject(
        subjects,
        _selectedSubject,
      );

      if (!mounted) return;
      setState(() {
        _weeklySchedules = weeklySchedules;
        _displaySchedules = _filterSchedules(
          weeklySchedules,
          _filterMode,
          selectedGroup,
          selectedTeacher,
          selectedSubject,
        );
        _groups = groups;
        _teachers = teachers;
        _subjects = subjects;
        _selectedGroup = selectedGroup;
        _selectedTeacher = selectedTeacher;
        _selectedSubject = selectedSubject;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load week schedule: ${e.toString()}';
      });
    }
  }

  void _applyFilterMode(_WeekFilterMode mode) {
    if (_filterMode == mode) return;

    setState(() {
      _filterMode = mode;
      if (_filterMode == _WeekFilterMode.group) {
        _selectedGroup ??= _firstOrNull(_groups);
      } else if (_filterMode == _WeekFilterMode.teacher) {
        _selectedTeacher ??= _firstOrNull(_teachers);
      } else if (_filterMode == _WeekFilterMode.subject) {
        _selectedSubject ??= _firstOrNull(_subjects);
      }
      _displaySchedules = _filterSchedules(
        _weeklySchedules,
        _filterMode,
        _selectedGroup,
        _selectedTeacher,
        _selectedSubject,
      );
      _errorMessage = null;
    });
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/admin/schedule');
  }

  T? _firstOrNull<T>(List<T> values) => values.isEmpty ? null : values.first;

  ClassGroup? _resolveSelectedGroup(
    List<ClassGroup> groups,
    ClassGroup? selectedGroup,
  ) {
    if (selectedGroup == null) {
      return _firstOrNull(groups);
    }
    for (final group in groups) {
      if (group.id == selectedGroup.id) {
        return group;
      }
    }
    return _firstOrNull(groups);
  }

  Teacher? _resolveSelectedTeacher(
    List<Teacher> teachers,
    Teacher? selectedTeacher,
  ) {
    if (selectedTeacher == null) {
      return _firstOrNull(teachers);
    }
    for (final teacher in teachers) {
      if (teacher.id == selectedTeacher.id) {
        return teacher;
      }
    }
    return _firstOrNull(teachers);
  }

  Subject? _resolveSelectedSubject(
    List<Subject> subjects,
    Subject? selectedSubject,
  ) {
    if (selectedSubject == null) {
      return _firstOrNull(subjects);
    }
    for (final subject in subjects) {
      if (subject.id == selectedSubject.id) {
        return subject;
      }
    }
    return _firstOrNull(subjects);
  }

  List<Schedule> _filterSchedules(
    List<Schedule> schedules,
    _WeekFilterMode mode,
    ClassGroup? selectedGroup,
    Teacher? selectedTeacher,
    Subject? selectedSubject,
  ) {
    switch (mode) {
      case _WeekFilterMode.all:
        return _sortSchedules(schedules);
      case _WeekFilterMode.group:
        if (selectedGroup == null) {
          return _sortSchedules(schedules);
        }
        return _sortSchedules(
          schedules
              .where((schedule) => schedule.classGroupId == selectedGroup.id)
              .toList(),
        );
      case _WeekFilterMode.teacher:
        if (selectedTeacher == null) {
          return _sortSchedules(schedules);
        }
        return _sortSchedules(
          schedules
              .where((schedule) => schedule.teacherId == selectedTeacher.id)
              .toList(),
        );
      case _WeekFilterMode.subject:
        if (selectedSubject == null) {
          return _sortSchedules(schedules);
        }
        return _sortSchedules(
          schedules
              .where((schedule) => schedule.subjectId == selectedSubject.id)
              .toList(),
        );
    }
  }

  List<Schedule> _sortSchedules(List<Schedule> schedules) {
    final sorted = List<Schedule>.from(schedules);
    sorted.sort((a, b) {
      final dayCompare =
          _orderedDays.indexOf(a.dayOfWeek.toUpperCase()) -
          _orderedDays.indexOf(b.dayOfWeek.toUpperCase());
      if (dayCompare != 0) {
        return dayCompare;
      }
      return a.startTime.compareTo(b.startTime);
    });
    return sorted;
  }

  List<ClassGroup> _deriveGroups(List<Schedule> schedules) {
    final groupsById = <int, ClassGroup>{};
    for (final schedule in schedules) {
      groupsById[schedule.classGroupId] = ClassGroup(
        id: schedule.classGroupId,
        name: schedule.classGroupName ?? 'Group #${schedule.classGroupId}',
      );
    }
    return groupsById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<Teacher> _deriveTeachers(List<Schedule> schedules) {
    final teachersById = <int, Teacher>{};
    for (final schedule in schedules) {
      teachersById[schedule.teacherId] = Teacher(
        id: schedule.teacherId,
        name: schedule.teacherName ?? 'Teacher #${schedule.teacherId}',
        email: '',
      );
    }
    return teachersById.values.toList()..sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
  }

  List<Subject> _deriveSubjects(List<Schedule> schedules) {
    final subjectsById = <int, Subject>{};
    for (final schedule in schedules) {
      subjectsById[schedule.subjectId] = Subject(
        id: schedule.subjectId,
        name: schedule.subjectName,
      );
    }
    return subjectsById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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

  List<Teacher> _mergeTeachers(List<Teacher> primary, List<Teacher> fallback) {
    final teachersById = <int, Teacher>{};
    for (final teacher in [...primary, ...fallback]) {
      teachersById[teacher.id] = teacher;
    }
    final teachers = teachersById.values.toList();
    teachers.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return teachers;
  }

  List<Subject> _mergeSubjects(List<Subject> primary, List<Subject> fallback) {
    final subjectsById = <int, Subject>{};
    for (final subject in [...primary, ...fallback]) {
      subjectsById[subject.id] = subject;
    }
    final subjects = subjectsById.values.toList();
    subjects.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return subjects;
  }

  String get _subtitle {
    switch (_filterMode) {
      case _WeekFilterMode.all:
        return 'Full weekly timetable view';
      case _WeekFilterMode.group:
        return _selectedGroup == null
            ? 'Choose a group to view its schedule'
            : 'Weekly timetable for ${_selectedGroup!.name}';
      case _WeekFilterMode.teacher:
        return _selectedTeacher == null
            ? 'Choose a teacher to view their schedule'
            : 'Weekly timetable for ${_selectedTeacher!.fullName}';
      case _WeekFilterMode.subject:
        return _selectedSubject == null
            ? 'Choose a subject to filter the schedule'
            : 'Weekly timetable filtered by ${_selectedSubject!.name}';
    }
  }

  Widget _buildActiveSelector() {
    switch (_filterMode) {
      case _WeekFilterMode.all:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            '${_displaySchedules.length} lessons this week',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        );
      case _WeekFilterMode.group:
        return DropdownButtonFormField<ClassGroup>(
          initialValue: _selectedGroup,
          decoration: const InputDecoration(labelText: 'Group', isDense: true),
          items: _groups
              .map(
                (group) => DropdownMenuItem<ClassGroup>(
                  value: group,
                  child: Text(group.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _groups.isEmpty
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedGroup = value;
                    _displaySchedules = _filterSchedules(
                      _weeklySchedules,
                      _filterMode,
                      _selectedGroup,
                      _selectedTeacher,
                      _selectedSubject,
                    );
                    _errorMessage = null;
                  });
                },
        );
      case _WeekFilterMode.teacher:
        return DropdownButtonFormField<Teacher>(
          initialValue: _selectedTeacher,
          decoration: const InputDecoration(
            labelText: 'Teacher',
            isDense: true,
          ),
          items: _teachers
              .map(
                (teacher) => DropdownMenuItem<Teacher>(
                  value: teacher,
                  child: Text(
                    teacher.fullName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _teachers.isEmpty
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedTeacher = value;
                    _displaySchedules = _filterSchedules(
                      _weeklySchedules,
                      _filterMode,
                      _selectedGroup,
                      _selectedTeacher,
                      _selectedSubject,
                    );
                    _errorMessage = null;
                  });
                },
        );
      case _WeekFilterMode.subject:
        return DropdownButtonFormField<Subject>(
          initialValue: _selectedSubject,
          decoration: const InputDecoration(
            labelText: 'Subject',
            isDense: true,
          ),
          items: _subjects
              .map(
                (subject) => DropdownMenuItem<Subject>(
                  value: subject,
                  child: Text(subject.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _subjects.isEmpty
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedSubject = value;
                    _displaySchedules = _filterSchedules(
                      _weeklySchedules,
                      _filterMode,
                      _selectedGroup,
                      _selectedTeacher,
                      _selectedSubject,
                    );
                    _errorMessage = null;
                  });
                },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showInlineBack =
        MediaQuery.sizeOf(context).width >= 1024 || !context.canPop();

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Column(
        children: [
          PageHeader(
            title: 'Week Schedule',
            subtitle: _subtitle,
            leading: showInlineBack
                ? IconButton(
                    onPressed: _handleBackNavigation,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    tooltip: 'Back',
                  )
                : null,
            actions: [
              IconButton(
                onPressed: _loadWeekData,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final modeSelector = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<_WeekFilterMode>(
                    segments: const [
                      ButtonSegment<_WeekFilterMode>(
                        value: _WeekFilterMode.all,
                        label: Text('All'),
                      ),
                      ButtonSegment<_WeekFilterMode>(
                        value: _WeekFilterMode.group,
                        label: Text('Groups'),
                      ),
                      ButtonSegment<_WeekFilterMode>(
                        value: _WeekFilterMode.teacher,
                        label: Text('Teachers'),
                      ),
                      ButtonSegment<_WeekFilterMode>(
                        value: _WeekFilterMode.subject,
                        label: Text('Subjects'),
                      ),
                    ],
                    selected: {_filterMode},
                    onSelectionChanged: (selection) {
                      _applyFilterMode(selection.first);
                    },
                  ),
                );

                final activeSelector = _buildActiveSelector();
                final isCompact = constraints.maxWidth < 760;

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Browse by', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      modeSelector,
                      const SizedBox(height: AppSpacing.md),
                      activeSelector,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 3, child: modeSelector),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: activeSelector),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _displaySchedules.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
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
                            onPressed: _loadWeekData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _WeekScheduleBoard(
                    schedules: _displaySchedules,
                    orderedDays: _orderedDays,
                    dayLabels: _dayLabels,
                    emptyMessage: switch (_filterMode) {
                      _WeekFilterMode.all => 'No lessons scheduled this week',
                      _WeekFilterMode.group =>
                        'No lessons found for this group',
                      _WeekFilterMode.teacher =>
                        'No lessons found for this teacher',
                      _WeekFilterMode.subject =>
                        'No lessons found for this subject',
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeekScheduleBoard extends StatelessWidget {
  final List<Schedule> schedules;
  final List<String> orderedDays;
  final Map<String, String> dayLabels;
  final String emptyMessage;

  const _WeekScheduleBoard({
    required this.schedules,
    required this.orderedDays,
    required this.dayLabels,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_view_week_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              emptyMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    final visibleDays = orderedDays
        .where(
          (day) =>
              schedules.any(
                (schedule) => schedule.dayOfWeek.toUpperCase() == day,
              ) ||
              day == 'MONDAY' ||
              day == 'TUESDAY' ||
              day == 'WEDNESDAY' ||
              day == 'THURSDAY' ||
              day == 'FRIDAY',
        )
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: visibleDays.map((day) {
            final daySchedules =
                schedules
                    .where(
                      (schedule) => schedule.dayOfWeek.toUpperCase() == day,
                    )
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

            return Container(
              width: 240,
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
                      child: Text(
                        dayLabels[day] ?? day,
                        style: AppTextStyles.label,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (daySchedules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text(
                        'No classes',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    )
                  else
                    ...daySchedules.map(
                      (schedule) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
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
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${schedule.startTime} - ${schedule.endTime}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              schedule.classGroupName ??
                                  'Group #${schedule.classGroupId}',
                              style: AppTextStyles.caption,
                            ),
                            if (schedule.teacherName != null)
                              Text(
                                schedule.teacherName!,
                                style: AppTextStyles.caption,
                              ),
                            if (schedule.room != null)
                              Text(
                                schedule.room!,
                                style: AppTextStyles.caption,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
