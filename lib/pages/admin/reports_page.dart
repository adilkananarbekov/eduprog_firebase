import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/attendance.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/async_batch.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<_GroupStat> _groups = [];
  double _overallAttendance = 0;
  int _perfectAttendanceStudents = 0;
  int _atRiskStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final attendanceService = ref.read(attendanceServiceProvider);

      final classGroups = await adminService.getClassGroups();
      final groupSummaries = await runInBatches(
        classGroups,
        batchSize: 4,
        operation: (group) async {
          final students = await adminService.getStudentsByClass(group.id);
          final attendanceByStudent = await runInBatches(
            students,
            batchSize: 8,
            operation: (student) async {
              try {
                return await attendanceService.getStudentAttendance(student.id);
              } catch (_) {
                return <Attendance>[];
              }
            },
          );

          var groupPresent = 0;
          var groupTotal = 0;
          var perfect = 0;
          var atRisk = 0;

          for (final attendance in attendanceByStudent) {
            if (attendance.isNotEmpty) {
              final studentPresent = attendance
                  .where((record) => record.status == AttendanceStatus.PRESENT)
                  .length;
              final studentRate = (studentPresent / attendance.length) * 100;
              if (studentRate >= 99.5) {
                perfect++;
              }
              if (studentRate < 70) {
                atRisk++;
              }
            }

            groupPresent += attendance
                .where((record) => record.status == AttendanceStatus.PRESENT)
                .length;
            groupTotal += attendance.length;
          }

          final attendanceRate = groupTotal == 0
              ? 0
              : ((groupPresent / groupTotal) * 100).round();

          return _GroupReportSummary(
            stat: _GroupStat(group.name, attendanceRate, students.length),
            present: groupPresent,
            total: groupTotal,
            perfect: perfect,
            atRisk: atRisk,
          );
        },
      );

      final groupStats = <_GroupStat>[];
      var globalPresent = 0;
      var globalTotal = 0;
      var perfect = 0;
      var atRisk = 0;

      for (final summary in groupSummaries) {
        groupStats.add(summary.stat);
        globalPresent += summary.present;
        globalTotal += summary.total;
        perfect += summary.perfect;
        atRisk += summary.atRisk;
      }

      if (!mounted) return;
      setState(() {
        _groups = groupStats;
        _overallAttendance = globalTotal == 0
            ? 0
            : (globalPresent / globalTotal) * 100;
        _perfectAttendanceStudents = perfect;
        _atRiskStudents = atRisk;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load reports: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportReport() async {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data available to export')),
      );
      return;
    }

    final buffer = StringBuffer('Group,Attendance %,Students\n');
    for (final group in _groups) {
      buffer.writeln('${group.name},${group.attendance},${group.students}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report CSV copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Reports',
          subtitle: 'Attendance and performance analytics',
          actions: [
            OutlinedButton.icon(
              onPressed: _exportReport,
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Export'),
            ),
          ],
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final cols = constraints.maxWidth > 600 ? 3 : 1;
                          return GridView.count(
                            crossAxisCount: cols,
                            shrinkWrap: true,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 2.2,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              MetricCard(
                                title: 'Overall Attendance',
                                value: '${_overallAttendance.round()}%',
                                icon: Icons.trending_up_outlined,
                                trend: 'Calculated from records',
                              ),
                              MetricCard(
                                title: 'Perfect Attendance',
                                value: _perfectAttendanceStudents.toString(),
                                icon: Icons.star_outline,
                                trend: 'Students tracked',
                              ),
                              MetricCard(
                                title: 'At-Risk Students',
                                value: _atRiskStudents.toString(),
                                icon: Icons.warning_outlined,
                                trend: 'Below 70%',
                                trendUp: false,
                                highlight: true,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Attendance by Group',
                        style: AppTextStyles.heading4,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_groups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Text(
                              'No group data available yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: Column(
                            children: _groups.asMap().entries.map((entry) {
                              final group = entry.value;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    child: _GroupAttendanceRow(group: group),
                                  ),
                                  if (entry.key < _groups.length - 1)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _GroupStat {
  final String name;
  final int attendance;
  final int students;

  const _GroupStat(this.name, this.attendance, this.students);
}

class _GroupReportSummary {
  final _GroupStat stat;
  final int present;
  final int total;
  final int perfect;
  final int atRisk;

  const _GroupReportSummary({
    required this.stat,
    required this.present,
    required this.total,
    required this.perfect,
    required this.atRisk,
  });
}

class _GroupAttendanceRow extends StatelessWidget {
  final _GroupStat group;

  const _GroupAttendanceRow({required this.group});

  @override
  Widget build(BuildContext context) {
    final accentColor = group.attendance >= 80
        ? AppColors.greenText
        : AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${group.attendance}%',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: group.attendance / 100,
                  backgroundColor: AppColors.muted,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('${group.students} students', style: AppTextStyles.caption),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                group.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: group.attendance / 100,
                  backgroundColor: AppColors.muted,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 48,
              child: Text(
                '${group.attendance}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 90,
              child: Text(
                '${group.students} students',
                style: AppTextStyles.caption,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        );
      },
    );
  }
}
