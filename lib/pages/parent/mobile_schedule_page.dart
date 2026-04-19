import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/schedule.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';

class MobileSchedulePage extends ConsumerStatefulWidget {
  const MobileSchedulePage({super.key});

  @override
  ConsumerState<MobileSchedulePage> createState() => _MobileSchedulePageState();
}

class _MobileSchedulePageState extends ConsumerState<MobileSchedulePage> {
  int _selectedDayIdx = DateTime.now().weekday - 1; // Mon=0
  List<Schedule> _allSchedules = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const _days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.role == UserRole.STUDENT) {
        final scheduleService = ref.read(scheduleServiceProvider);
        final schedules = await scheduleService.getWeeklySchedule();
        setState(() {
          _allSchedules = schedules;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load schedule: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Schedule> get _selectedDaySchedules {
    final selectedDay = _days[_selectedDayIdx];
    return _allSchedules
        .where((s) => s.dayOfWeek.toUpperCase() == selectedDay)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final lessons = _selectedDaySchedules;

    return Column(
      children: [
        // Header
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
                        Text('Schedule', style: AppTextStyles.heading3),
                        Text(
                          "${currentUser?.firstName ?? 'Student'}'s weekly timetable",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Day selector
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dayLabels.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _selectedDayIdx = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedDayIdx == i
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXl,
                        ),
                        border: Border.all(
                          color: _selectedDayIdx == i
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _dayLabels[i],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _selectedDayIdx == i
                              ? Colors.white
                              : AppColors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : lessons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No classes on ${_dayLabels[_selectedDayIdx]}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: lessons.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final l = lessons[i];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final metaBlock = Column(
                            crossAxisAlignment: constraints.maxWidth < 420
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${l.startTime} – ${l.endTime}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (l.room != null)
                                Text(
                                  l.room!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.mutedForeground,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          );

                          final lessonInfo = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.subjectName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                l.teacherName ?? 'Teacher TBA',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.mutedForeground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );

                          if (constraints.maxWidth < 420) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      lessonInfo,
                                      const SizedBox(height: AppSpacing.sm),
                                      metaBlock,
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Container(
                                width: 4,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: lessonInfo),
                              const SizedBox(width: AppSpacing.md),
                              metaBlock,
                            ],
                          );
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
