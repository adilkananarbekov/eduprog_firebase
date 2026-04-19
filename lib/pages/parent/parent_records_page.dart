import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/attendance.dart';
import '../../core/models/grade.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';

class ParentRecordsPage extends ConsumerStatefulWidget {
  const ParentRecordsPage({super.key});

  @override
  ConsumerState<ParentRecordsPage> createState() => _ParentRecordsPageState();
}

class _ParentRecordsPageState extends ConsumerState<ParentRecordsPage> {
  List<Attendance> _attendance = [];
  List<Grade> _grades = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.role != UserRole.STUDENT) {
        setState(() {
          _attendance = [];
          _grades = [];
          _isLoading = false;
          _errorMessage =
              'Academic records are only available for student accounts.';
        });
        return;
      }

      final results = await Future.wait([
        ref.read(attendanceServiceProvider).getMyAttendance(),
        ref.read(gradeServiceProvider).getMyGrades(),
      ]);

      final attendance = results[0] as List<Attendance>;
      final grades = results[1] as List<Grade>;
      attendance.sort((a, b) => b.date.compareTo(a.date));
      grades.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _attendance = attendance;
        _grades = grades;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load academic records: ${e.toString()}';
      });
    }
  }

  String get _attendanceRate {
    if (_attendance.isEmpty) {
      return '—';
    }
    final presentCount = _attendance
        .where((record) => record.status == AttendanceStatus.PRESENT)
        .length;
    return '${((presentCount / _attendance.length) * 100).round()}%';
  }

  String get _latestGradeValue {
    if (_grades.isEmpty) {
      return '—';
    }
    final latest = _grades.first;
    return '${latest.score.toStringAsFixed(0)}/${latest.maxScore.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final studentName = currentUser?.firstName ?? 'Student';

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Records', style: AppTextStyles.heading3),
                          Text(
                            "$studentName's attendance and marks",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _loadRecords,
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _RecordStatCard(
                        label: 'Attendance rate',
                        value: _isLoading ? '...' : _attendanceRate,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _RecordStatCard(
                        label: 'Latest mark',
                        value: _isLoading ? '...' : _latestGradeValue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const TabBar(
                  tabs: [
                    Tab(text: 'Attendance'),
                    Tab(text: 'Marks'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : TabBarView(
                    children: [
                      _AttendanceRecordsTab(attendance: _attendance),
                      _GradeRecordsTab(grades: _grades),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecordStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _RecordStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRecordsTab extends StatelessWidget {
  final List<Attendance> attendance;

  const _AttendanceRecordsTab({required this.attendance});

  BadgeVariant _variantFor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.PRESENT:
        return BadgeVariant.present;
      case AttendanceStatus.ABSENT:
        return BadgeVariant.absent;
      case AttendanceStatus.LATE:
      case AttendanceStatus.EXCUSED:
        return BadgeVariant.custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (attendance.isEmpty) {
      return const _RecordsEmptyState(
        icon: Icons.fact_check_outlined,
        message: 'No attendance records yet',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: attendance.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final record = attendance[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.subjectName ?? 'Attendance',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppBadge(
                    text: record.status.displayName,
                    variant: _variantFor(record.status),
                    customBg: AppColors.surfaceStrongOf(context),
                    customText: AppColors.textPrimaryOf(context),
                    customBorder: AppColors.borderOf(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DateFormat('MMM d, yyyy').format(record.date),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMutedOf(context),
                ),
              ),
              if (record.markedByName != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Marked by ${record.markedByName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
              if (record.markedAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Saved ${DateFormat('MMM d, HH:mm').format(record.markedAt!.toLocal())}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
              if (record.notes != null && record.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  record.notes!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GradeRecordsTab extends StatelessWidget {
  final List<Grade> grades;

  const _GradeRecordsTab({required this.grades});

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return const _RecordsEmptyState(
        icon: Icons.school_outlined,
        message: 'No marks yet',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: grades.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final grade = grades[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      grade.subjectName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppBadge(
                    text: grade.letterGrade,
                    customBg: AppColors.primarySoftOf(context),
                    customText: AppColors.primaryOf(context),
                    customBorder: AppColors.borderOf(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${grade.score.toStringAsFixed(0)}/${grade.maxScore.toStringAsFixed(0)}${grade.gradeType != null ? ' · ${grade.gradeType}' : ''}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DateFormat('MMM d, yyyy').format(grade.date),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMutedOf(context),
                ),
              ),
              if (grade.teacherName != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Teacher: ${grade.teacherName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
              if (grade.notes != null && grade.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  grade.notes!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecordsEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _RecordsEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.mutedForeground),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
