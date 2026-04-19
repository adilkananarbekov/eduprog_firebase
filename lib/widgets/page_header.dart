import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_spacing.dart';

/// Reusable page header with title, subtitle, and optional action buttons.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderOf(context);
    final primary = AppColors.primaryOf(context);
    final accent = AppColors.accentOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasActions = actions != null && actions!.isNotEmpty;
        final isCompact =
            constraints.maxWidth < 760 ||
            (hasActions && constraints.maxWidth < 1040);
        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campus hub',
              style: AppTextStyles.eyebrow.copyWith(color: textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(color: textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(color: textMuted),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.headerGradientOf(context),
            border: Border(bottom: BorderSide(color: border)),
          ),
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                top: -56,
                right: isCompact ? -28 : 48,
                child: IgnorePointer(
                  child: _GlowOrb(
                    size: isCompact ? 150 : 210,
                    color: primary.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: isCompact ? -36 : 180,
                child: IgnorePointer(
                  child: _GlowOrb(
                    size: isCompact ? 130 : 180,
                    color: accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? AppSpacing.md : AppSpacing.xl,
                  vertical: isCompact ? AppSpacing.md : AppSpacing.xl,
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(height: AppSpacing.md),
                          ],
                          textBlock,
                          if (hasActions) ...[
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: actions!,
                            ),
                          ],
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: AppSpacing.md),
                          ],
                          Expanded(child: textBlock),
                          if (hasActions) ...[
                            const SizedBox(width: AppSpacing.md),
                            Flexible(
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  alignment: WrapAlignment.end,
                                  children: actions!,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
