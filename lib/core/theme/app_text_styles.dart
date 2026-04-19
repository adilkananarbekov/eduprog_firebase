import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Shared typography for the refreshed EduOps UI.
class AppTextStyles {
  AppTextStyles._();

  static final String _displayFont = GoogleFonts.plusJakartaSans().fontFamily!;
  static final String _bodyFont = GoogleFonts.sourceSans3().fontFamily!;

  static final TextStyle heading1 = TextStyle(
    fontFamily: _displayFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9,
    height: 1.12,
  );

  static final TextStyle heading2 = TextStyle(
    fontFamily: _displayFont,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.18,
  );

  static final TextStyle heading3 = TextStyle(
    fontFamily: _displayFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.35,
    height: 1.24,
  );

  static final TextStyle heading4 = TextStyle(
    fontFamily: _displayFont,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.28,
  );

  static final TextStyle bodyLarge = TextStyle(
    fontFamily: _bodyFont,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.55,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontFamily: _bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.52,
  );

  static final TextStyle bodySmall = TextStyle(
    fontFamily: _bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
    height: 1.5,
  );

  static final TextStyle caption = TextStyle(
    fontFamily: _bodyFont,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedForeground,
    height: 1.45,
  );

  static final TextStyle eyebrow = TextStyle(
    fontFamily: _displayFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.mutedForeground,
    height: 1.35,
    letterSpacing: 0.8,
  );

  static final TextStyle metricValue = TextStyle(
    fontFamily: _displayFont,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.1,
  );

  static final TextStyle label = TextStyle(
    fontFamily: _bodyFont,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static final TextStyle button = TextStyle(
    fontFamily: _bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0.05,
  );
}
