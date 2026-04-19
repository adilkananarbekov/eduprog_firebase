import 'package:flutter/material.dart';

/// Centralized design tokens for the EduOps visual system.
///
/// The palette aims to feel youthful and digital-first without slipping into
/// neon: bright learning-blue as the main action color, warm coral as the
/// accent, and clean high-contrast surfaces for readability.
class AppColors {
  AppColors._();

  // Light tokens
  static const Color lightBackground = Color(0xFFF4F7FF);
  static const Color lightCanvas = Color(0xFFEDF3FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceStrong = Color(0xFFF1F6FF);
  static const Color lightInk = Color(0xFF16213D);
  static const Color lightMuted = Color(0xFF61708F);
  static const Color lightPrimary = Color(0xFF2F6BFF);
  static const Color lightPrimaryStrong = Color(0xFF1248C7);
  static const Color lightPrimarySoft = Color(0xFFE7F0FF);
  static const Color lightAccent = Color(0xFFFF7A59);
  static const Color lightAccentStrong = Color(0xFFE55C35);
  static const Color lightAccentSoft = Color(0xFFFFF0EA);
  static const Color lightBorder = Color(0xFFD6E2FF);
  static const Color lightSidebar = Color(0xFFE8F0FF);
  static const Color lightSidebarForeground = lightInk;
  static const Color lightHeroStart = Color(0xFFF7FAFF);
  static const Color lightHeroMiddle = Color(0xFFE8F1FF);
  static const Color lightHeroEnd = Color(0xFFFFEFE8);
  static const Color lightShadow = Color(0x16264B96);

  // Dark tokens
  static const Color darkBackground = Color(0xFF0D1426);
  static const Color darkCanvas = Color(0xFF111A30);
  static const Color darkSurface = Color(0xFF17233D);
  static const Color darkSurfaceStrong = Color(0xFF203050);
  static const Color darkInk = Color(0xFFF3F7FF);
  static const Color darkMuted = Color(0xFFA9B8D9);
  static const Color darkPrimary = Color(0xFF78A5FF);
  static const Color darkPrimaryStrong = Color(0xFFA9C5FF);
  static const Color darkPrimarySoft = Color(0xFF253A63);
  static const Color darkAccent = Color(0xFFFF9A7A);
  static const Color darkAccentStrong = Color(0xFFFFB7A1);
  static const Color darkAccentSoft = Color(0xFF3A2A2A);
  static const Color darkBorder = Color(0xFF31456F);
  static const Color darkSidebar = Color(0xFF14203A);
  static const Color darkSidebarForeground = darkInk;
  static const Color darkHeroStart = Color(0xFF182542);
  static const Color darkHeroMiddle = Color(0xFF15233A);
  static const Color darkHeroEnd = Color(0xFF2B2337);
  static const Color darkShadow = Color(0x00000000);

  // Legacy aliases retained for existing screens.
  static const Color primary = lightPrimary;
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color foreground = lightInk;
  static const Color mutedForeground = lightMuted;
  static const Color accent = lightAccent;
  static const Color accentForeground = Color(0xFFFFFFFF);
  static const Color background = lightBackground;
  static const Color card = lightSurface;
  static const Color muted = lightCanvas;
  static const Color surfaceSubtle = lightCanvas;
  static const Color surfaceStrong = lightSurfaceStrong;
  static const Color warmSurface = Color(0xFFFFF4EE);
  static const Color border = lightBorder;
  static const Color shadow = lightShadow;
  static const Color primarySoft = lightPrimarySoft;
  static const Color accentSoft = lightAccentSoft;
  static const Color destructive = lightAccent;
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color greenBg = lightPrimarySoft;
  static const Color greenText = lightPrimaryStrong;
  static const Color greenBorder = lightBorder;
  static const Color yellowBg = lightAccentSoft;
  static const Color yellowText = lightAccentStrong;
  static const Color yellowBorder = Color(0xFFFFD3C7);
  static const Color redBg = lightAccentSoft;
  static const Color redText = lightAccentStrong;
  static const Color redBorder = Color(0xFFFFCDBF);
  static const Color sidebar = lightSidebar;
  static const Color sidebarForeground = lightSidebarForeground;
  static const Color sidebarBorder = Color(0xFFCCDAFF);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color resolve(
    BuildContext context, {
    required Color light,
    required Color dark,
  }) => isDark(context) ? dark : light;

  static Color canvasOf(BuildContext context) =>
      resolve(context, light: lightCanvas, dark: darkCanvas);

  static Color surfaceOf(BuildContext context) =>
      resolve(context, light: lightSurface, dark: darkSurface);

  static Color surfaceStrongOf(BuildContext context) =>
      resolve(context, light: lightSurfaceStrong, dark: darkSurfaceStrong);

  static Color textPrimaryOf(BuildContext context) =>
      resolve(context, light: lightInk, dark: darkInk);

  static Color textMutedOf(BuildContext context) =>
      resolve(context, light: lightMuted, dark: darkMuted);

  static Color primaryOf(BuildContext context) =>
      resolve(context, light: lightPrimary, dark: darkPrimary);

  static Color primaryStrongOf(BuildContext context) =>
      resolve(context, light: lightPrimaryStrong, dark: darkPrimaryStrong);

  static Color primarySoftOf(BuildContext context) =>
      resolve(context, light: lightPrimarySoft, dark: darkPrimarySoft);

  static Color accentOf(BuildContext context) =>
      resolve(context, light: lightAccent, dark: darkAccent);

  static Color accentStrongOf(BuildContext context) =>
      resolve(context, light: lightAccentStrong, dark: darkAccentStrong);

  static Color accentSoftOf(BuildContext context) =>
      resolve(context, light: lightAccentSoft, dark: darkAccentSoft);

  static Color borderOf(BuildContext context) =>
      resolve(context, light: lightBorder, dark: darkBorder);

  static Color railOf(BuildContext context) =>
      resolve(context, light: lightSidebar, dark: darkSidebar);

  static Color railForegroundOf(BuildContext context) => resolve(
    context,
    light: lightSidebarForeground,
    dark: darkSidebarForeground,
  );

  static Color shadowOf(BuildContext context) =>
      resolve(context, light: lightShadow, dark: darkShadow);

  static Color successBgOf(BuildContext context) => primarySoftOf(context);
  static Color successTextOf(BuildContext context) => primaryStrongOf(context);
  static Color successBorderOf(BuildContext context) => borderOf(context);
  static Color dangerBgOf(BuildContext context) => accentSoftOf(context);
  static Color dangerTextOf(BuildContext context) => accentStrongOf(context);
  static Color dangerBorderOf(BuildContext context) => resolve(
    context,
    light: const Color(0xFFE7C9B9),
    dark: const Color(0xFF5A4337),
  );

  static LinearGradient heroGradientOf(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      resolve(context, light: lightHeroStart, dark: darkHeroStart),
      resolve(context, light: lightHeroMiddle, dark: darkHeroMiddle),
      resolve(context, light: lightHeroEnd, dark: darkHeroEnd),
    ],
  );

  static LinearGradient headerGradientOf(BuildContext context) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surfaceOf(context),
          resolve(
            context,
            light: const Color(0xFFF1F6FF),
            dark: const Color(0xFF1B2A47),
          ),
          resolve(
            context,
            light: const Color(0xFFFFF1EB),
            dark: const Color(0xFF241F35),
          ),
        ],
      );

  static LinearGradient panelGradientOf(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surfaceOf(context),
      resolve(
        context,
        light: const Color(0xFFF4F8FF),
        dark: const Color(0xFF1A2946),
      ),
    ],
  );

  static LinearGradient panelAccentGradientOf(BuildContext context) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          resolve(
            context,
            light: const Color(0xFFFFF2EC),
            dark: const Color(0xFF31252A),
          ),
          surfaceOf(context),
        ],
      );

  static LinearGradient railGradientOf(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      resolve(
        context,
        light: const Color(0xFFEAF2FF),
        dark: const Color(0xFF182746),
      ),
      resolve(
        context,
        light: const Color(0xFFDDE9FF),
        dark: const Color(0xFF14203A),
      ),
    ],
  );

  static Color overlayTintOf(BuildContext context) => resolve(
    context,
    light: const Color(0xB8FFFFFF),
    dark: const Color(0x66314069),
  );
}
