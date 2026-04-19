import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/attendance.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../core/security/role_access.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  static const _days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  bool _isLoading = true;
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _activeGroups = 0;
  int _todayLessonCount = 0;
  int _announcementCount = 0;
  String _todayAttendance = '—';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<_TodayAttendanceSnapshot> _loadTodayAttendanceSnapshot() async {
    final scheduleService = ref.read(scheduleServiceProvider);
    final attendanceService = ref.read(attendanceServiceProvider);
    final today = DateTime.now();
    final dayName = _days[today.weekday - 1];

    final schedules = await scheduleService.getWeeklySchedule();
    final todaysSchedules = schedules
        .where((schedule) => schedule.dayOfWeek.toUpperCase() == dayName)
        .toList();
    if (todaysSchedules.isEmpty) {
      return const _TodayAttendanceSnapshot(
        records: <Attendance>[],
        lessonCount: 0,
      );
    }

    final attendances = await Future.wait(
      todaysSchedules
          .map(
            (schedule) => attendanceService
                .getScheduleAttendance(scheduleId: schedule.id, date: today)
                .catchError((_) => <Attendance>[]),
          )
          .toList(),
    );

    final uniqueById = <int, Attendance>{};
    for (final records in attendances) {
      for (final record in records) {
        uniqueById[record.id] = record;
      }
    }

    return _TodayAttendanceSnapshot(
      records: uniqueById.values.toList(),
      lessonCount: todaysSchedules.length,
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider);
      final adminService = ref.read(adminServiceProvider);
      final canViewStudents =
          currentUser != null &&
          RoleAccess.canAccessRoute(currentUser.role, '/admin/students');
      final canViewGroups =
          currentUser != null &&
          RoleAccess.canAccessRoute(currentUser.role, '/admin/groups');
      final canViewTeachers =
          currentUser != null && currentUser.role != UserRole.STUDENT;
      final canViewAttendance =
          currentUser != null &&
          RoleAccess.canAccessRoute(currentUser.role, '/admin/attendance');
      final canViewAnnouncements =
          currentUser != null &&
          RoleAccess.canAccessRoute(currentUser.role, '/admin/announcements');

      final results = await Future.wait([
        canViewStudents
            ? adminService
                  .getAccessibleStudents()
                  .then<dynamic>((v) => v.students)
                  .catchError((_) => <dynamic>[])
            : Future<dynamic>.value(<dynamic>[]),
        canViewGroups
            ? adminService
                  .getClassGroups()
                  .then<dynamic>((v) => v)
                  .catchError((_) => <dynamic>[])
            : Future<dynamic>.value(<dynamic>[]),
        canViewTeachers
            ? adminService
                  .getTeachers()
                  .then<dynamic>((v) => v)
                  .catchError((_) => <dynamic>[])
            : Future<dynamic>.value(<dynamic>[]),
        canViewAttendance
            ? _loadTodayAttendanceSnapshot()
                  .then<dynamic>((v) => v)
                  .catchError((_) => <dynamic>[])
            : Future<dynamic>.value(<dynamic>[]),
        canViewAnnouncements
            ? (currentUser.role == UserRole.ADMIN
                      ? ref
                            .read(announcementServiceProvider)
                            .getAllAnnouncements()
                      : ref
                            .read(announcementServiceProvider)
                            .getMyAnnouncements())
                  .then<dynamic>((v) => v)
                  .catchError((_) => <dynamic>[])
            : Future<dynamic>.value(<dynamic>[]),
      ]);

      final students = results[0] as List<dynamic>;
      final groups = results[1] as List<dynamic>;
      final teachers = results[2] as List<dynamic>;
      final attendanceSnapshot = results[3] is _TodayAttendanceSnapshot
          ? results[3] as _TodayAttendanceSnapshot
          : const _TodayAttendanceSnapshot(
              records: <Attendance>[],
              lessonCount: 0,
            );
      final todayAttendance = attendanceSnapshot.records;
      final announcements = results[4] as List<dynamic>;

      final presentCount = todayAttendance
          .where((record) => record.status == AttendanceStatus.PRESENT)
          .length;
      final attendanceRate = todayAttendance.isEmpty
          ? '—'
          : '${((presentCount / todayAttendance.length) * 100).round()}%';

      if (!mounted) return;
      setState(() {
        _totalStudents = students.length;
        _totalTeachers = teachers.length;
        _activeGroups = groups.length;
        _todayLessonCount = attendanceSnapshot.lessonCount;
        _announcementCount = announcements.length;
        _todayAttendance = attendanceRate;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canViewStudents =
        currentUser != null &&
        RoleAccess.canAccessRoute(currentUser.role, '/admin/students');
    final canViewGroups =
        currentUser != null &&
        RoleAccess.canAccessRoute(currentUser.role, '/admin/groups');
    final canViewTeachers =
        currentUser != null && currentUser.role != UserRole.STUDENT;
    final canViewSchedule =
        currentUser != null &&
        RoleAccess.canAccessRoute(currentUser.role, '/admin/schedule');
    final canViewAttendance =
        currentUser != null &&
        RoleAccess.canAccessRoute(currentUser.role, '/admin/attendance');
    final canViewReports =
        currentUser != null &&
        RoleAccess.canAccessRoute(currentUser.role, '/admin/reports');
    final canViewAnnouncements =
        currentUser != null &&
        RoleAccess.canAccessRoute(currentUser.role, '/admin/announcements');
    final textMuted = AppColors.textMutedOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final primary = AppColors.primaryOf(context);
    final accent = AppColors.accentOf(context);

    final metrics = [
      (
        title: 'Students in system',
        value: !canViewStudents
            ? 'Restricted'
            : _isLoading
            ? '...'
            : _totalStudents.toString(),
        icon: Icons.people_alt_outlined,
        trend: canViewStudents
            ? 'Records available right now'
            : 'Not available for this account',
        highlight: false,
      ),
      (
        title: 'Teachers in system',
        value: !canViewTeachers
            ? 'Restricted'
            : _isLoading
            ? '...'
            : _totalTeachers.toString(),
        icon: Icons.school_outlined,
        trend: canViewTeachers
            ? 'Teaching staff currently listed'
            : 'Not available for this account',
        highlight: false,
      ),
      (
        title: 'Active groups',
        value: !canViewGroups
            ? 'Restricted'
            : _isLoading
            ? '...'
            : _activeGroups.toString(),
        icon: Icons.groups_outlined,
        trend: canViewGroups
            ? 'Classes scheduled this week'
            : 'Not available for this account',
        highlight: false,
      ),
      (
        title: 'Announcements',
        value: !canViewAnnouncements
            ? 'Restricted'
            : _isLoading
            ? '...'
            : _announcementCount.toString(),
        icon: Icons.campaign_outlined,
        trend: canViewAnnouncements
            ? 'Published updates from the backend'
            : 'Not available for this account',
        highlight: false,
      ),
    ];

    final quickActions = [
      if (canViewAttendance)
        _ActionData(
          label: 'Mark attendance',
          description: 'Open the roster and close today’s lesson attendance.',
          icon: Icons.fact_check_outlined,
          color: primary,
          onTap: () => context.push('/admin/attendance'),
        ),
      if (canViewSchedule)
        _ActionData(
          label: 'Check timetable',
          description: 'Review classes, rooms, and the week board.',
          icon: Icons.calendar_today_outlined,
          color: primary,
          onTap: () => context.push('/admin/schedule'),
        ),
      if (canViewStudents)
        _ActionData(
          label: 'Open students',
          description: 'Search profiles, groups, and individual records.',
          icon: Icons.people_alt_outlined,
          color: primary,
          onTap: () => context.push('/admin/students'),
        ),
      if (canViewAnnouncements)
        _ActionData(
          label: 'Open updates',
          description: 'Review and publish announcement messages.',
          icon: Icons.campaign_outlined,
          color: accent,
          onTap: () => context.push('/admin/announcements'),
        ),
    ];

    return Column(
      children: [
        PageHeader(
          title: 'Home',
          subtitle:
              'Open the main school workflows quickly${currentUser == null ? '' : ' · signed in as ${currentUser.role.displayName}'}',
          actions: [
            if (canViewReports)
              OutlinedButton.icon(
                onPressed: () => context.push('/admin/reports'),
                icon: const Icon(Icons.bar_chart_outlined, size: 16),
                label: const Text('Reports'),
              ),
            IconButton(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroPanel(
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  totalStudents: _totalStudents,
                  totalTeachers: _totalTeachers,
                  activeGroups: _activeGroups,
                  todayLessonCount: _todayLessonCount,
                  announcementCount: _announcementCount,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Operational snapshot',
                  style: AppTextStyles.heading4.copyWith(color: textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'A fast read of what is stable and what still needs action.',
                  style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1480
                        ? 5
                        : constraints.maxWidth >= 1080
                        ? 4
                        : constraints.maxWidth >= 720
                        ? 2
                        : 1;
                    final ratio = cols == 1
                        ? 2.8
                        : cols == 2
                        ? 1.45
                        : cols >= 5
                        ? 1.08
                        : 1.15;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: metrics.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: ratio,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      itemBuilder: (context, index) {
                        final item = metrics[index];
                        return MetricCard(
                          title: item.title,
                          value: item.value,
                          icon: item.icon,
                          trend: item.trend,
                          trendUp: !item.highlight,
                          highlight: item.highlight,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 920;
                    final opsFeed = AppCard(
                      header: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current state',
                            style: AppTextStyles.heading4.copyWith(
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'A backend-backed snapshot of live school data.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _FeedRow(
                            title: 'Lessons today',
                            meta: _todayLessonCount == 0
                                ? 'No lessons are scheduled for today.'
                                : '$_todayLessonCount lessons scheduled today.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FeedRow(
                            title: 'Attendance coverage',
                            meta: _todayAttendance == '—'
                                ? 'Attendance will appear after today’s lessons are marked.'
                                : 'Current attendance rate is $_todayAttendance.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FeedRow(
                            title: 'Announcement stream',
                            meta: _announcementCount == 0
                                ? 'No announcements are published yet.'
                                : '$_announcementCount announcements are currently available.',
                          ),
                        ],
                      ),
                    );

                    final actionsPanel = AppCard(
                      header: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Navigation',
                            style: AppTextStyles.heading4.copyWith(
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Open the sections you use most often.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        children: quickActions
                            .map(
                              (action) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _ActionTile(action: action),
                              ),
                            )
                            .toList(),
                      ),
                    );

                    if (isCompact) {
                      return Column(
                        children: [
                          actionsPanel,
                          const SizedBox(height: AppSpacing.md),
                          opsFeed,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: actionsPanel),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 5, child: opsFeed),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final int totalStudents;
  final int totalTeachers;
  final int activeGroups;
  final int todayLessonCount;
  final int announcementCount;

  const _HeroPanel({
    required this.isLoading,
    required this.errorMessage,
    required this.totalStudents,
    required this.totalTeachers,
    required this.activeGroups,
    required this.todayLessonCount,
    required this.announcementCount,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final accent = AppColors.accentOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final border = AppColors.borderOf(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientOf(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOf(context).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPERATIONS',
                style: AppTextStyles.eyebrow.copyWith(color: textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Run the school day with fewer clicks and clearer priorities.',
                style: AppTextStyles.heading2.copyWith(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                errorMessage ??
                    'Students, teachers, groups, and announcements stay aligned in one operational workspace.',
                style: AppTextStyles.bodyMedium.copyWith(color: textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _HeroPill(
                    label: 'Students',
                    value: isLoading ? '...' : totalStudents.toString(),
                    color: primary,
                  ),
                  _HeroPill(
                    label: 'Teachers',
                    value: isLoading ? '...' : totalTeachers.toString(),
                    color: primary,
                  ),
                  _HeroPill(
                    label: 'Groups',
                    value: isLoading ? '...' : activeGroups.toString(),
                    color: primary,
                  ),
                  _HeroPill(
                    label: 'Updates',
                    value: isLoading ? '...' : announcementCount.toString(),
                    color: accent,
                  ),
                ],
              ),
            ],
          );

          final sideCard = Container(
            width: constraints.maxWidth >= 1320
                ? 360
                : (constraints.maxWidth * 0.34).clamp(260.0, 320.0),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backend status',
                  style: AppTextStyles.heading4.copyWith(color: textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Students online: ${isLoading ? '...' : totalStudents}\n'
                  'Teachers online: ${isLoading ? '...' : totalTeachers}\n'
                  'Groups online: ${isLoading ? '...' : activeGroups}\n'
                  'Lessons today: ${isLoading ? '...' : todayLessonCount}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textMuted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          );

          if (constraints.maxWidth < 920) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summary,
                const SizedBox(height: AppSpacing.lg),
                SizedBox(width: double.infinity, child: sideCard),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: summary),
              const SizedBox(width: AppSpacing.lg),
              sideCard,
            ],
          );
        },
      ),
    );
  }
}

class _TodayAttendanceSnapshot {
  final List<Attendance> records;
  final int lessonCount;

  const _TodayAttendanceSnapshot({
    required this.records,
    required this.lessonCount,
  });
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104, maxWidth: 152),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.heading4.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionData {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionData({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ActionTile extends StatelessWidget {
  final _ActionData action;

  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderOf(context);
    final surfaceStrong = AppColors.surfaceStrongOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: surfaceStrong,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.description,
                      style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, size: 18, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  final String title;
  final String meta;

  const _FeedRow({required this.title, required this.meta});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final border = AppColors.borderOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(meta, style: AppTextStyles.bodySmall.copyWith(color: textMuted)),
        ],
      ),
    );
  }
}
