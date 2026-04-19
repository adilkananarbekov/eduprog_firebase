import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_spacing.dart';

/// Dashboard metric card used in AdminDashboard, Reports, and Billing.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? trend;
  final bool trendUp;
  final bool highlight;
  final Color? valueColor;
  final Color? iconColor;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.trend,
    this.trendUp = true,
    this.highlight = false,
    this.valueColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundGradient = highlight
        ? AppColors.panelAccentGradientOf(context)
        : AppColors.panelGradientOf(context);
    final borderColor = highlight
        ? AppColors.dangerBorderOf(context)
        : AppColors.borderOf(context);
    final hasTrend = trend?.isNotEmpty == true;
    final primary = AppColors.primaryOf(context);
    final accent = AppColors.accentOf(context);
    final ink = AppColors.textPrimaryOf(context);
    final muted = AppColors.textMutedOf(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOf(context).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -26,
            right: -10,
            child: IgnorePointer(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (highlight ? accent : primary).withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (highlight ? accent : primary).withValues(
                            alpha: 0.18,
                          ),
                          AppColors.surfaceOf(context).withValues(alpha: 0.94),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: (highlight ? accent : primary).withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: iconColor ?? (highlight ? accent : primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: AppTextStyles.metricValue.copyWith(
                        color: valueColor ?? (highlight ? accent : ink),
                      ),
                    ),
                  ),
                ),
              ),
              if (hasTrend) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  trend!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: trendUp ? muted : accent,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
