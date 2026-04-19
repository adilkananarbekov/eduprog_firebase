import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/attendance.dart';
import '../../core/models/class_group.dart';
import '../../core/models/schedule.dart';
import '../../core/models/student.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../core/services/attendance_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/page_header.dart';

class AttendanceMarkingPage extends ConsumerStatefulWidget {
  final String? groupId;

  const AttendanceMarkingPage({super.key, this.groupId});

  @override
  ConsumerState<AttendanceMarkingPage> createState() =>
      _AttendanceMarkingPageState();
}

class _AttendanceMarkingPageState extends ConsumerState<AttendanceMarkingPage> {
  List<ClassGroup> _groups = [];
  List<Student> _currentStudents = [];
  List<Schedule> _groupSchedules = [];
  List<Schedule> _teacherSchedules = [];
  ClassGroup? _selectedGroup;
  Schedule? _selectedSchedule;
  final Map<int, String> _attendance = {};
  Map<int, Attendance> _savedAttendanceByStudent = {};
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String? _savedMarkedByName;
  DateTime? _savedMarkedAt;
  bool _limitedToTeacherSchedule = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingSavedAttendance = false;
  String? _errorMessage;

  static const _statuses = ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'];
  static final _statusColors = {
    'PRESENT': AppColors.greenText,
    'ABSENT': AppColors.primary,
    'LATE': AppColors.yellowText,
    'EXCUSED': AppColors.accent,
  };

  bool get _hasSavedAttendance => _savedAttendanceByStudent.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.role == UserRole.TEACHER) {
        await _loadTeacherScopedData();
      } else {
        final adminService = ref.read(adminServiceProvider);
        final groups = await adminService.getClassGroups();
        if (!mounted) {
          return;
        }

        final requestedGroupId = int.tryParse(widget.groupId ?? '');
        ClassGroup? selectedGroup;
        if (requestedGroupId != null) {
          for (final group in groups) {
            if (group.id == requestedGroupId) {
              selectedGroup = group;
              break;
            }
          }
        }
        selectedGroup ??= groups.isNotEmpty ? groups.first : null;

        setState(() {
          _groups = groups;
          _teacherSchedules = [];
          _limitedToTeacherSchedule = false;
          _selectedGroup = selectedGroup;
          _errorMessage = null;
        });

        if (selectedGroup != null) {
          await _applyGroupSelection(selectedGroup);
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to load attendance setup: ${e.toString()}';
      });
      _showSnack(_errorMessage!, backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTeacherScopedData() async {
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
    final requestedGroupId = int.tryParse(widget.groupId ?? '');
    ClassGroup? selectedGroup;
    if (requestedGroupId != null) {
      for (final group in groups) {
        if (group.id == requestedGroupId) {
          selectedGroup = group;
          break;
        }
      }
    }
    selectedGroup ??= groups.isNotEmpty ? groups.first : null;

    if (!mounted) {
      return;
    }

    setState(() {
      _groups = groups;
      _teacherSchedules = schedules;
      _selectedGroup = selectedGroup;
      _limitedToTeacherSchedule = true;
      _errorMessage = null;
    });

    if (selectedGroup != null) {
      await _applyGroupSelection(selectedGroup);
    }
  }

  Future<void> _applyGroupSelection(ClassGroup group) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedGroup = group;
      _currentStudents = [];
      _groupSchedules = [];
      _selectedSchedule = null;
      _attendance.clear();
      _savedAttendanceByStudent = {};
      _savedMarkedByName = null;
      _savedMarkedAt = null;
    });

    if (_limitedToTeacherSchedule) {
      _setTeacherSchedulesForGroup(group.id);
    } else {
      await _loadSchedulesForGroup(group.id);
    }

    await _loadStudentsForGroup(group.id);
    await _loadExistingAttendance();
  }

  Future<void> _loadStudentsForGroup(int groupId) async {
    try {
      final adminService = ref.read(adminServiceProvider);
      final students = await adminService.getStudentsByClass(groupId);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentStudents = students;
        _attendance.clear();
      });
    } catch (e) {
      _showSnack(
        'Failed to load students: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _loadSchedulesForGroup(int groupId) async {
    try {
      final scheduleService = ref.read(scheduleServiceProvider);
      final schedules = await scheduleService.getClassSchedule(groupId);
      if (!mounted) {
        return;
      }
      setState(() {
        _groupSchedules = schedules;
        _selectedSchedule = schedules.isNotEmpty ? schedules.first : null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _groupSchedules = [];
        _selectedSchedule = null;
      });
      _showSnack(
        'Failed to load lessons: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  void _setTeacherSchedulesForGroup(int groupId) {
    final schedules =
        _teacherSchedules
            .where((schedule) => schedule.classGroupId == groupId)
            .toList()
          ..sort((a, b) {
            final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
            if (dayCompare != 0) {
              return dayCompare;
            }
            return a.startTime.compareTo(b.startTime);
          });

    setState(() {
      _groupSchedules = schedules;
      _selectedSchedule = schedules.isNotEmpty ? schedules.first : null;
    });
  }

  Future<void> _loadExistingAttendance() async {
    final selectedSchedule = _selectedSchedule;
    if (selectedSchedule == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _attendance.clear();
        _savedAttendanceByStudent = {};
        _savedMarkedByName = null;
        _savedMarkedAt = null;
        _isLoadingSavedAttendance = false;
      });
      return;
    }

    final requestedScheduleId = selectedSchedule.id;
    final requestedDate = _selectedDate;

    setState(() {
      _attendance.clear();
      _savedAttendanceByStudent = {};
      _savedMarkedByName = null;
      _savedMarkedAt = null;
      _isLoadingSavedAttendance = true;
    });

    try {
      final attendanceService = ref.read(attendanceServiceProvider);
      final records = await attendanceService.getScheduleAttendance(
        scheduleId: requestedScheduleId,
        date: requestedDate,
      );

      if (!mounted ||
          _selectedSchedule?.id != requestedScheduleId ||
          !DateUtils.isSameDay(_selectedDate, requestedDate)) {
        return;
      }

      _applyLoadedAttendance(records);
    } on NotFoundException {
      if (!mounted ||
          _selectedSchedule?.id != requestedScheduleId ||
          !DateUtils.isSameDay(_selectedDate, requestedDate)) {
        return;
      }
      setState(() {
        _attendance.clear();
        _savedAttendanceByStudent = {};
        _savedMarkedByName = null;
        _savedMarkedAt = null;
        _isLoadingSavedAttendance = false;
      });
    } catch (e) {
      if (!mounted ||
          _selectedSchedule?.id != requestedScheduleId ||
          !DateUtils.isSameDay(_selectedDate, requestedDate)) {
        return;
      }
      setState(() => _isLoadingSavedAttendance = false);
      _showSnack(
        'Failed to load saved attendance: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  void _applyLoadedAttendance(List<Attendance> records) {
    final savedByStudent = <int, Attendance>{};
    DateTime? latestMarkedAt;
    String? markedByName;

    _attendance.clear();
    for (final record in records) {
      savedByStudent[record.studentId] = record;
      _attendance[record.studentId] = record.status.name;
      if (record.markedAt != null &&
          (latestMarkedAt == null ||
              record.markedAt!.isAfter(latestMarkedAt))) {
        latestMarkedAt = record.markedAt;
      }
      markedByName ??= record.markedByName;
    }

    setState(() {
      _savedAttendanceByStudent = savedByStudent;
      _savedMarkedAt = latestMarkedAt;
      _savedMarkedByName = markedByName;
      _isLoadingSavedAttendance = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Review attendance for date',
    );
    if (picked == null) {
      return;
    }

    final normalized = DateUtils.dateOnly(picked);
    if (DateUtils.isSameDay(normalized, _selectedDate)) {
      return;
    }

    setState(() => _selectedDate = normalized);
    await _loadExistingAttendance();
  }

  Future<void> _jumpToToday() async {
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(today, _selectedDate)) {
      return;
    }

    setState(() => _selectedDate = today);
    await _loadExistingAttendance();
  }

  void _setAttendanceForAll(String status) {
    if (_currentStudents.isEmpty) {
      return;
    }

    setState(() {
      for (final student in _currentStudents) {
        _attendance[student.id] = status;
      }
    });
  }

  void _restoreSavedAttendance() {
    setState(() {
      _attendance.clear();
      for (final entry in _savedAttendanceByStudent.entries) {
        _attendance[entry.key] = entry.value.status.name;
      }
    });
  }

  void _clearDraft() {
    setState(() => _attendance.clear());
  }

  Future<void> _saveAttendance() async {
    if (_selectedGroup == null ||
        _attendance.isEmpty ||
        _selectedSchedule == null) {
      _showSnack(
        'Please select a lesson and mark at least one student.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final attendanceService = ref.read(attendanceServiceProvider);
      final records = await attendanceService.markAttendance(
        scheduleId: _selectedSchedule!.id,
        date: _selectedDate,
        records: _attendance.entries
            .map(
              (entry) => AttendanceMarkingRecord(
                studentId: entry.key,
                status: AttendanceStatus.values.firstWhere(
                  (value) => value.name == entry.value,
                  orElse: () => AttendanceStatus.PRESENT,
                ),
              ),
            )
            .toList(),
      );

      if (!mounted) {
        return;
      }

      _applyLoadedAttendance(records);
      setState(() => _isSaving = false);
      _showSnack(
        'Attendance saved for ${_selectedGroup!.name} on ${_formattedDate(_selectedDate)}.',
        backgroundColor: AppColors.greenText,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showSnack(
        'Failed to save attendance: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  void _showSnack(String message, {required Color backgroundColor}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String _formattedDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  String _formattedTimestamp(DateTime timestamp) {
    return DateFormat('d MMM, HH:mm').format(timestamp.toLocal());
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PRESENT':
        return 'Present';
      case 'ABSENT':
        return 'Absent';
      case 'LATE':
        return 'Late';
      case 'EXCUSED':
        return 'Excused';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    return _statusColors[status] ?? AppColors.primary;
  }

  int _countStatus(String status) {
    return _attendance.values.where((value) => value == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final markedCount = _attendance.length;
    final unmarkedCount = (_currentStudents.length - markedCount).clamp(
      0,
      9999,
    );

    return Column(
      children: [
        PageHeader(
          title: 'Mark Attendance',
          subtitle:
              'Select group, lesson, and date. Saved attendance loads automatically for review.',
          actions: [
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAttendance,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save'),
            ),
          ],
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Text(_errorMessage!, style: AppTextStyles.bodyMedium),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 720;
                      final selector = DropdownButton<ClassGroup>(
                        value: _selectedGroup,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        items: _groups
                            .map(
                              (group) => DropdownMenuItem(
                                value: group,
                                child: Text(
                                  group.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _applyGroupSelection(value);
                          }
                        },
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Group', style: AppTextStyles.label),
                            const SizedBox(height: AppSpacing.xs),
                            selector,
                            const SizedBox(height: AppSpacing.sm),
                            if (_limitedToTeacherSchedule)
                              Text(
                                'Teacher view is limited to your scheduled groups.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            if (_limitedToTeacherSchedule)
                              const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${_currentStudents.length} students',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Text('Group:', style: AppTextStyles.label),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: selector),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            '${_currentStudents.length} students',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 720;
                      final lessonSelector = DropdownButton<Schedule>(
                        value: _selectedSchedule,
                        isExpanded: true,
                        hint: const Text('Select lesson'),
                        items: _groupSchedules
                            .map(
                              (schedule) => DropdownMenuItem(
                                value: schedule,
                                child: Text(
                                  '${schedule.dayOfWeek} · ${schedule.startTime}-${schedule.endTime} · ${schedule.subjectName}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          setState(() => _selectedSchedule = value);
                          await _loadExistingAttendance();
                        },
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lesson', style: AppTextStyles.label),
                            const SizedBox(height: AppSpacing.xs),
                            lessonSelector,
                            if (_groupSchedules.isEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No lessons are available for this group.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.accentStrongOf(context),
                                ),
                              ),
                            ],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Text('Lesson:', style: AppTextStyles.label),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: lessonSelector),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 720;
                      final dateControls = Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(_formattedDate(_selectedDate)),
                          ),
                          TextButton(
                            onPressed:
                                DateUtils.isSameDay(
                                  _selectedDate,
                                  DateTime.now(),
                                )
                                ? null
                                : _jumpToToday,
                            child: const Text('Today'),
                          ),
                        ],
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date', style: AppTextStyles.label),
                            const SizedBox(height: AppSpacing.xs),
                            dateControls,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Text('Date:', style: AppTextStyles.label),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: dateControls),
                        ],
                      );
                    },
                  ),
                ),
                if (_isLoadingSavedAttendance)
                  const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _hasSavedAttendance
                          ? AppColors.primarySoftOf(context)
                          : AppColors.surfaceStrongOf(context),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasSavedAttendance
                              ? 'Saved attendance found'
                              : 'No saved attendance yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimaryOf(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _hasSavedAttendance
                              ? _savedMarkedAt != null
                                    ? 'Marked by ${_savedMarkedByName ?? 'a staff member'} on ${_formattedTimestamp(_savedMarkedAt!)}. Review the changed students only.'
                                    : 'Saved statuses were loaded for this lesson and date so you can review or edit them.'
                              : _selectedSchedule == null
                              ? 'Select a lesson to review or enter attendance.'
                              : 'Suggestion: use "All present" first, then change only absences, late arrivals, or excused students.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _AttendanceSummaryChip(
                              label: 'Marked',
                              value: '$markedCount',
                              color: AppColors.primaryOf(context),
                            ),
                            _AttendanceSummaryChip(
                              label: 'Unmarked',
                              value: '$unmarkedCount',
                              color: AppColors.accentOf(context),
                            ),
                            for (final status in _statuses)
                              if (_countStatus(status) > 0)
                                _AttendanceSummaryChip(
                                  label: _statusLabel(status),
                                  value: '${_countStatus(status)}',
                                  color: _statusColor(status),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _currentStudents.isEmpty
                            ? null
                            : () => _setAttendanceForAll('PRESENT'),
                        icon: const Icon(Icons.done_all_outlined, size: 16),
                        label: const Text('All present'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _attendance.isEmpty ? null : _clearDraft,
                        icon: const Icon(Icons.layers_clear_outlined, size: 16),
                        label: const Text('Clear draft'),
                      ),
                      if (_hasSavedAttendance)
                        OutlinedButton.icon(
                          onPressed: _restoreSavedAttendance,
                          icon: const Icon(Icons.history_outlined, size: 16),
                          label: const Text('Restore saved'),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: _statuses
                        .map(
                          (status) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _statusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                _statusLabel(status),
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: _currentStudents.isEmpty
                      ? Center(
                          child: Text(
                            'No students in this group',
                            style: AppTextStyles.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _currentStudents.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final student = _currentStudents[index];
                            final currentStatus = _attendance[student.id];
                            final savedRecord =
                                _savedAttendanceByStudent[student.id];
                            final draftChanged =
                                currentStatus != null &&
                                currentStatus != savedRecord?.status.name;

                            final secondaryLine = <String>[
                              if ((student.phoneNumber ?? '').trim().isNotEmpty)
                                student.phoneNumber!,
                              if (savedRecord != null)
                                'Saved: ${savedRecord.status.displayName}'
                              else
                                'No saved record for this date',
                            ].join(' • ');

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                color: AppColors.surfaceOf(context),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final chips = Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: _statuses.map((status) {
                                      final isSelected =
                                          currentStatus == status;
                                      final color = _statusColor(status);
                                      return ChoiceChip(
                                        label: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white
                                                : color,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (_) => setState(
                                          () =>
                                              _attendance[student.id] = status,
                                        ),
                                        selectedColor: color,
                                        backgroundColor: color.withValues(
                                          alpha: 0.08,
                                        ),
                                        side: BorderSide(
                                          color: color.withValues(alpha: 0.3),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                      );
                                    }).toList(),
                                  );

                                  final studentInfo = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: AppColors.muted,
                                            child: Text(
                                              student.firstName[0]
                                                  .toUpperCase(),
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student.fullName,
                                                  style: AppTextStyles
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(
                                                  height: AppSpacing.xs,
                                                ),
                                                Text(
                                                  secondaryLine,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color: AppColors
                                                            .mutedForeground,
                                                      ),
                                                ),
                                                if (draftChanged) ...[
                                                  const SizedBox(
                                                    height: AppSpacing.xs,
                                                  ),
                                                  Text(
                                                    'Draft change: ${_statusLabel(currentStatus)}',
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                          color: _statusColor(
                                                            currentStatus,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );

                                  if (constraints.maxWidth < 780) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        studentInfo,
                                        const SizedBox(height: AppSpacing.md),
                                        chips,
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: studentInfo),
                                      const SizedBox(width: AppSpacing.md),
                                      Flexible(child: chips),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AttendanceSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttendanceSummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimaryOf(context),
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
