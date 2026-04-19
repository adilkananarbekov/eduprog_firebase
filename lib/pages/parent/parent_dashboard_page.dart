import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/schedule.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';

class ParentDashboardPage extends ConsumerStatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  ConsumerState<ParentDashboardPage> createState() =>
      _ParentDashboardPageState();
}

class _ParentDashboardPageState extends ConsumerState<ParentDashboardPage> {
  List<Schedule> _upcomingSchedule = [];
  int _announcementCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.role != UserRole.STUDENT) {
        setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        ref.read(scheduleServiceProvider).getWeeklySchedule(),
        ref.read(announcementServiceProvider).getMyAnnouncements(),
      ]);

      final schedules = results[0] as List<Schedule>;
      final announcements = results[1] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _upcomingSchedule = schedules.take(3).toList();
        _announcementCount = announcements.length;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load schedule: ${e.toString()}';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final studentName = currentUser?.firstName ?? 'Student';
    final hasUpcoming = _upcomingSchedule.isNotEmpty;
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final primary = AppColors.primaryOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradientOf(context),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.borderOf(context)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowOf(context).withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAMILY PORTAL',
                  style: AppTextStyles.eyebrow.copyWith(color: textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Everything important for $studentName, in one calm view.',
                  style: AppTextStyles.heading2.copyWith(color: textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage ??
                      'Check the next class, recent updates, and academic records without digging through menus.',
                  style: AppTextStyles.bodyMedium.copyWith(color: textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppBadge(
                      text: hasUpcoming
                          ? 'Classes scheduled'
                          : 'No class today',
                      customBg: AppColors.surfaceOf(context),
                      customText: primary,
                      customBorder: AppColors.borderOf(context),
                    ),
                    _SummaryChip(
                      label: 'Next',
                      value: hasUpcoming
                          ? _upcomingSchedule.first.subjectName
                          : 'Free',
                    ),
                    _SummaryChip(
                      label: 'Updates',
                      value: _announcementCount == 0
                          ? 'None'
                          : _announcementCount.toString(),
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push('/parent/schedule'),
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: const Text('Open schedule'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/parent/records'),
                      icon: const Icon(Icons.school_outlined, size: 16),
                      label: const Text('Open records'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/parent/announcements'),
                      icon: const Icon(Icons.campaign_outlined, size: 16),
                      label: const Text('Open updates'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1320
                  ? 4
                  : constraints.maxWidth >= 760
                  ? 2
                  : 1;
              final cards = [
                _FamilyActionCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Schedule',
                  description: 'View classes, rooms, and times quickly.',
                  color: primary,
                  onTap: () => context.push('/parent/schedule'),
                ),
                _FamilyActionCard(
                  icon: Icons.school_outlined,
                  label: 'Records',
                  description: 'See attendance, marks, and teacher updates.',
                  color: primary,
                  onTap: () => context.push('/parent/records'),
                ),
                _FamilyActionCard(
                  icon: Icons.campaign_outlined,
                  label: 'Updates',
                  description: 'Read family announcements and reminders.',
                  color: primary,
                  onTap: () => context.push('/parent/announcements'),
                ),
                _FamilyActionCard(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  description: 'Manage profile, language, and notifications.',
                  color: primary,
                  onTap: () => context.push('/parent/settings'),
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: cols == 1
                      ? 2.8
                      : cols == 2
                      ? 1.9
                      : 1.12,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) => cards[index],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next classes',
                  style: AppTextStyles.heading4.copyWith(color: textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'A simple preview of what comes next.',
                  style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                ),
              ],
            ),
            child: _upcomingSchedule.isEmpty && !_isLoading
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceStrongOf(context),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      'No upcoming classes right now.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: _upcomingSchedule
                        .map(
                          (schedule) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _UpcomingClassCard(schedule: schedule),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: highlight
                  ? AppColors.accentStrongOf(context)
                  : AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _FamilyActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, size: 18, color: textMuted),
        ],
      ),
    );
  }
}

class _UpcomingClassCard extends StatelessWidget {
  final Schedule schedule;

  const _UpcomingClassCard({required this.schedule});

  String get _formattedDay {
    final value = schedule.dayOfWeek.toLowerCase();
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final primary = AppColors.primaryOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrongOf(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(Icons.menu_book_outlined, color: primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.subjectName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${schedule.startTime} – ${schedule.endTime}',
                  style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                ),
              ],
            ),
          ),
          AppBadge(
            text: _formattedDay,
            customBg: Colors.white,
            customText: primary,
            customBorder: AppColors.borderOf(context),
          ),
        ],
      ),
    );
  }
}
