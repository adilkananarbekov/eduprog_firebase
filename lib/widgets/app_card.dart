import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_spacing.dart';

/// Reusable card widget matching the EduOps design.
class AppCard extends StatelessWidget {
  final Widget? header;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    this.header,
    required this.child,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.borderWidth = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final outline = borderColor ?? AppColors.borderOf(context);
    final highlight = AppColors.overlayTintOf(context);
    final primary = AppColors.primaryOf(context);
    final accent = AppColors.accentOf(context);
    final baseColor = backgroundColor ?? surface;
    final gradientTarget = backgroundColor == null
        ? AppColors.primarySoftOf(context)
        : surface;
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            Color.lerp(
              baseColor,
              gradientTarget,
              backgroundColor == null ? 0.58 : 0.24,
            )!,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: outline, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOf(context).withValues(alpha: 0.09),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -42,
            right: -20,
            child: IgnorePointer(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.09),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -52,
            left: -18,
            child: IgnorePointer(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.82),
                      accent.withValues(alpha: 0.82),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              Container(height: 1, color: highlight),
              if (header != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: header!,
                ),
              Padding(
                padding: padding ?? const EdgeInsets.all(AppSpacing.md),
                child: child,
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: card,
        ),
      );
    }
    return card;
  }
}
