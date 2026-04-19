import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_spacing.dart';

enum BadgeVariant {
  active,
  archived,
  paid,
  unpaid,
  partial,
  present,
  absent,
  important,
  custom,
}

/// Status badge widget matching the EduOps design.
class AppBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final Color? customBg;
  final Color? customText;
  final Color? customBorder;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.custom,
    this.customBg,
    this.customText,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$3),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.$2,
        ),
      ),
    );
  }

  (Color bg, Color text, Color border) _getColors(BuildContext context) {
    switch (variant) {
      case BadgeVariant.active:
        return (
          AppColors.successBgOf(context),
          AppColors.successTextOf(context),
          AppColors.successBorderOf(context),
        );
      case BadgeVariant.archived:
        return (
          AppColors.surfaceStrongOf(context),
          AppColors.textMutedOf(context),
          AppColors.borderOf(context),
        );
      case BadgeVariant.paid:
        return (
          AppColors.successBgOf(context),
          AppColors.successTextOf(context),
          AppColors.successBorderOf(context),
        );
      case BadgeVariant.unpaid:
        return (
          AppColors.dangerBgOf(context),
          AppColors.dangerTextOf(context),
          AppColors.dangerBorderOf(context),
        );
      case BadgeVariant.partial:
        return (
          AppColors.dangerBgOf(context),
          AppColors.dangerTextOf(context),
          AppColors.dangerBorderOf(context),
        );
      case BadgeVariant.present:
        return (
          AppColors.successBgOf(context),
          AppColors.successTextOf(context),
          AppColors.successBorderOf(context),
        );
      case BadgeVariant.absent:
        return (
          AppColors.dangerBgOf(context),
          AppColors.dangerTextOf(context),
          AppColors.dangerBorderOf(context),
        );
      case BadgeVariant.important:
        return (
          AppColors.dangerBgOf(context),
          AppColors.dangerTextOf(context),
          AppColors.dangerBorderOf(context),
        );
      case BadgeVariant.custom:
        return (
          customBg ?? AppColors.surfaceStrongOf(context),
          customText ?? AppColors.textPrimaryOf(context),
          customBorder ?? AppColors.borderOf(context),
        );
    }
  }
}
