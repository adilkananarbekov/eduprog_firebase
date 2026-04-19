import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/student.dart';
import '../../core/models/attendance.dart';
import '../../core/models/grade.dart';
import '../../core/models/schedule.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../widgets/app_card.dart';

class StudentProfilePage extends ConsumerStatefulWidget {
  final String studentId;
  const StudentProfilePage({super.key, required this.studentId});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  bool _isLoading = true;
  bool _isTeacherScopedView = false;
  String? _errorMessage;

  Student? _student;
  List<Attendance> _attendance = [];
  List<Grade> _grades = [];
  List<Schedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/admin/students');
  }

  Future<void> _loadStudentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final studentIdInt = int.tryParse(widget.studentId);
    if (studentIdInt == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid student ID';
      });
      return;
    }

    try {
      final adminService = ref.read(adminServiceProvider);
      final currentUser = ref.read(currentUserProvider);
      final matchedStudent = await adminService.getAccessibleStudentById(
        studentIdInt,
      );
      if (matchedStudent == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Student not found';
        });
        return;
      }

      Set<int> accessibleScheduleIds = const <int>{};
      Set<int> accessibleSubjectIds = const <int>{};
      if (currentUser?.role == UserRole.TEACHER) {
        final teacherSchedules = await ref
            .read(scheduleServiceProvider)
            .getWeeklySchedule();
        final teacherSchedulesForStudent = teacherSchedules
            .where(
              (schedule) =>
                  schedule.classGroupId == matchedStudent.classGroupId,
            )
            .toList();
        if (matchedStudent.classGroupId == null ||
            teacherSchedulesForStudent.isEmpty) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage =
                'This teacher account does not have access to that student.';
          });
          return;
        }
        accessibleScheduleIds = teacherSchedulesForStudent
            .map((schedule) => schedule.id)
            .toSet();
        accessibleSubjectIds = teacherSchedulesForStudent
            .map((schedule) => schedule.subjectId)
            .toSet();
      }

      _student = matchedStudent;

      // Load related data in parallel, each can fail independently
      final results = await Future.wait([
        ref
            .read(attendanceServiceProvider)
            .getStudentAttendance(studentIdInt)
            .catchError((e) {
              debugPrint('[PROFILE] attendance error: $e');
              return <Attendance>[];
            }),
        ref
            .read(gradeServiceProvider)
            .getStudentGrades(studentIdInt)
            .catchError((e) {
              debugPrint('[PROFILE] grades error: $e');
              return <Grade>[];
            }),
        _student!.classGroupId != null
            ? ref
                  .read(scheduleServiceProvider)
                  .getClassSchedule(_student!.classGroupId!)
                  .catchError((e) {
                    debugPrint('[PROFILE] schedule error: $e');
                    return <Schedule>[];
                  })
            : Future.value(<Schedule>[]),
      ]);

      var attendance = results[0] as List<Attendance>;
      var grades = results[1] as List<Grade>;
      var schedules = results[2] as List<Schedule>;

      if (currentUser?.role == UserRole.TEACHER) {
        attendance = attendance
            .where(
              (record) => accessibleScheduleIds.contains(record.scheduleId),
            )
            .toList();
        grades = grades.where((grade) {
          if (!accessibleSubjectIds.contains(grade.subjectId)) {
            return false;
          }
          return grade.teacherId == null ||
              grade.teacherId == currentUser!.userId;
        }).toList();
        schedules = schedules
            .where((schedule) => accessibleScheduleIds.contains(schedule.id))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _attendance = attendance;
        _grades = grades;
        _schedules = schedules;
        _isTeacherScopedView = currentUser?.role == UserRole.TEACHER;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[PROFILE] Unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load student data';
      });
    }
  }

  String get _attendanceRate {
    if (_attendance.isEmpty) return '—';
    final present = _attendance
        .where((a) => a.status == AttendanceStatus.PRESENT)
        .length;
    return '${((present / _attendance.length) * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Back button + header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trailingAction = !_isLoading && _student != null
                    ? IconButton(
                        onPressed: _loadStudentData,
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh',
                      )
                    : null;

                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _handleBackNavigation,
                            icon: const Icon(Icons.arrow_back_ios, size: 18),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Student Profile',
                              style: AppTextStyles.heading3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (trailingAction != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: trailingAction,
                        ),
                    ],
                  );
                }

                return Row(
                  children: [
                    IconButton(
                      onPressed: _handleBackNavigation,
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Student Profile',
                        style: AppTextStyles.heading3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // ignore: use_null_aware_elements
                    if (trailingAction != null) trailingAction,
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(_errorMessage!, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: _loadStudentData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final student = _student!;
    final tabContentHeight = MediaQuery.sizeOf(context).height < 820
        ? 420.0
        : 520.0;
    final visibleSubjectCount = _schedules
        .map((schedule) => schedule.subjectId)
        .toSet()
        .length;
    final initials = student.name.isNotEmpty
        ? student.name
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          AppCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: AppTextStyles.heading3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${student.classGroupName ?? 'No Group'} · ID: #${student.id}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_isTeacherScopedView) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Showing only lessons and grades from your schedule.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _InfoItem(Icons.email_outlined, student.email),
                        if (student.phoneNumber != null)
                          _InfoItem(Icons.phone_outlined, student.phoneNumber!),
                        if (student.studentNumber != null)
                          _InfoItem(
                            Icons.badge_outlined,
                            student.studentNumber!,
                          ),
                        if (student.accountNumber != null)
                          _InfoItem(
                            Icons.account_balance_outlined,
                            'Acc: ${student.accountNumber}',
                          ),
                      ],
                    ),
                  ],
                );

                final avatar = CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.muted,
                  child: Text(
                    initials,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.foreground,
                    ),
                  ),
                );

                if (constraints.maxWidth < 720) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      const SizedBox(height: AppSpacing.md),
                      details,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: details),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 600 ? 3 : 1;
              final statCards = <Widget>[
                _StatCard(
                  'Attendance Rate',
                  _attendanceRate,
                  _attendanceRate == '—'
                      ? AppColors.mutedForeground
                      : AppColors.greenText,
                ),
                _StatCard(
                  _isTeacherScopedView ? 'Visible Subjects' : 'Subjects',
                  visibleSubjectCount.toString(),
                  AppColors.foreground,
                ),
                _StatCard(
                  _isTeacherScopedView ? 'Visible Lessons' : 'Weekly Lessons',
                  _schedules.length.toString(),
                  AppColors.accent,
                ),
              ];

              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 2.5,
                children: statCards,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: TabBar(
              isScrollable: true,
              tabs: const [
                Tab(text: 'Attendance'),
                Tab(text: 'Schedule'),
                Tab(text: 'Grades'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: tabContentHeight,
            child: TabBarView(
              children: [
                _AttendanceTab(attendance: _attendance),
                _ScheduleTab(schedules: _schedules),
                _GradesTab(grades: _grades),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ─────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.mutedForeground),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _StatCard(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Tab ───────────────────────────────────────────────────────────

class _ScheduleTab extends StatelessWidget {
  final List<Schedule> schedules;
  const _ScheduleTab({required this.schedules});

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
              'No schedule data yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    // Group by day
    final grouped = <String, List<Schedule>>{};
    for (final s in schedules) {
      grouped.putIfAbsent(s.dayOfWeek, () => []).add(s);
    }

    final orderedDays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => orderedDays.indexOf(a.key) - orderedDays.indexOf(b.key));

    return ListView(
      children: sortedEntries.map((entry) {
        final day = entry.key[0] + entry.key.substring(1).toLowerCase();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.xs,
                top: AppSpacing.sm,
              ),
              child: Text(
                day,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
            ...entry.value.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final timeChip = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Text(
                        '${s.startTime} – ${s.endTime}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );

                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.subjectName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (s.teacherName != null || s.room != null)
                          Text(
                            [
                              s.teacherName,
                              s.room,
                            ].whereType<String>().join(' · '),
                            style: AppTextStyles.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    );

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      child: constraints.maxWidth < 460
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                timeChip,
                                const SizedBox(height: AppSpacing.sm),
                                details,
                              ],
                            )
                          : Row(
                              children: [
                                timeChip,
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: details),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final List<Attendance> attendance;

  const _AttendanceTab({required this.attendance});

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.PRESENT:
        return AppColors.greenText;
      case AttendanceStatus.ABSENT:
        return AppColors.primary;
      case AttendanceStatus.LATE:
        return Colors.orange;
      case AttendanceStatus.EXCUSED:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (attendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No attendance records yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    final sorted = List<Attendance>.from(attendance)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final record = sorted[index];
        final statusColor = _statusColor(record.status);

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final statusPill = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  record.status.displayName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.subjectName ?? 'Attendance',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    DateFormat('MMM d, yyyy').format(record.date),
                    style: AppTextStyles.caption,
                  ),
                  if (record.notes != null && record.notes!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        record.notes!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              );

              if (constraints.maxWidth < 440) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statusPill,
                    const SizedBox(height: AppSpacing.sm),
                    details,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  statusPill,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: details),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Grades Tab ─────────────────────────────────────────────────────────────

class _GradesTab extends StatelessWidget {
  final List<Grade> grades;
  const _GradesTab({required this.grades});

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No grades yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    final sorted = List<Grade>.from(grades)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final g = sorted[i];
        final pct = g.percentage;
        final color = pct >= 80
            ? AppColors.greenText
            : pct >= 60
            ? Colors.orange
            : AppColors.primary;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gradeBadge = Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: Text(
                  g.letterGrade,
                  style: AppTextStyles.heading4.copyWith(color: color),
                ),
              );

              final gradeDetails = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.subjectName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${g.score.toStringAsFixed(0)}/${g.maxScore.toStringAsFixed(0)} · ${g.gradeType ?? 'Grade'}',
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (g.teacherName != null)
                    Text(
                      g.teacherName!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              );

              final dateLabel = Text(
                DateFormat('MMM d').format(g.date),
                style: AppTextStyles.caption,
              );

              if (constraints.maxWidth < 440) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        gradeBadge,
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: gradeDetails),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    dateLabel,
                  ],
                );
              }

              return Row(
                children: [
                  gradeBadge,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: gradeDetails),
                  const SizedBox(width: AppSpacing.sm),
                  dateLabel,
                ],
              );
            },
          ),
        );
      },
    );
  }
}
