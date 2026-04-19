import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_spacing.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightCanvas,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.lightAccent,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightInk,
      error: AppColors.lightAccentStrong,
      onError: Colors.white,
      outline: AppColors.lightBorder,
    ),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkCanvas,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkBackground,
      secondary: AppColors.darkAccent,
      onSecondary: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkInk,
      error: AppColors.darkAccentStrong,
      onError: AppColors.darkBackground,
      outline: AppColors.darkBorder,
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required ColorScheme colorScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = GoogleFonts.sourceSans3TextTheme().copyWith(
      headlineLarge: AppTextStyles.heading1.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineMedium: AppTextStyles.heading2.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineSmall: AppTextStyles.heading3.copyWith(
        color: colorScheme.onSurface,
      ),
      titleLarge: AppTextStyles.heading4.copyWith(color: colorScheme.onSurface),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(
        color: colorScheme.onSurface,
      ),
      bodySmall: AppTextStyles.bodySmall.copyWith(
        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
      ),
      labelLarge: AppTextStyles.label.copyWith(color: colorScheme.onSurface),
      labelSmall: AppTextStyles.caption.copyWith(
        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
    );

    return base.copyWith(
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: colorScheme.primary.withValues(alpha: isDark ? 0.06 : 0.04),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.heading4.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shadowColor: _shadowOfColor(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: colorScheme.outline),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: colorScheme.outline),
        ),
        titleTextStyle: AppTextStyles.heading4.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceStrong
            : AppColors.lightSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkInk : AppColors.lightInk,
        ),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: _primarySoftOf(brightness),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: _primarySoftOf(brightness),
          disabledForegroundColor: _textMutedOf(brightness),
          elevation: 0,
          textStyle: AppTextStyles.button,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size(0, 50),
          textStyle: AppTextStyles.button.copyWith(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceStrongOf(brightness),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 15,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
        labelStyle: AppTextStyles.label.copyWith(color: colorScheme.onSurface),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 1.3),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: isDark
            ? AppColors.darkMuted
            : AppColors.lightMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          color: colorScheme.primary,
        ),
        unselectedLabelStyle: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: isDark
            ? AppColors.darkMuted
            : AppColors.lightMuted,
        dividerColor: colorScheme.outline,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.label.copyWith(color: colorScheme.primary),
        unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceStrong : AppColors.lightInk,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: AppTextStyles.caption.copyWith(color: Colors.white),
      ),
      textTheme: textTheme,
    );
  }
}

Color _shadowOfColor(Brightness brightness) {
  return brightness == Brightness.dark
      ? AppColors.darkShadow
      : AppColors.lightShadow;
}

Color _primarySoftOf(Brightness brightness) {
  return brightness == Brightness.dark
      ? AppColors.darkPrimarySoft
      : AppColors.lightPrimarySoft;
}

Color _surfaceStrongOf(Brightness brightness) {
  return brightness == Brightness.dark
      ? AppColors.darkSurfaceStrong
      : AppColors.lightSurfaceStrong;
}

Color _textMutedOf(Brightness brightness) {
  return brightness == Brightness.dark
      ? AppColors.darkMuted
      : AppColors.lightMuted;
}
