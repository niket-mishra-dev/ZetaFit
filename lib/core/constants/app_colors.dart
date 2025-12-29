// lib/presentation/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ------------------------------------------------------------
  // BRAND COLORS
  // ------------------------------------------------------------
  static const Color primary = Color(0xFF7F5AF0);
  static const Color secondary = Color(0xFF2CB67D);
  static const Color accent = Color(0xFFFF6B9A);

  // ------------------------------------------------------------
  // DARK THEME COLORS
  // ------------------------------------------------------------
  static const Color darkBg = Color(0xFF0D0D0F);
  static const Color darkSurface = Color(0xFF1A1A1C);
  static const Color darkCard = Color(0xFF111113);
  static const Color darkText = Colors.white;
  static const Color darkSubtext = Color(0xB3FFFFFF); // 70% opacity
  static const Color darkBorder = Color(0x3DFFFFFF);  // 24% opacity

  // ------------------------------------------------------------
  // LIGHT THEME COLORS
  // ------------------------------------------------------------
  static const Color lightBg = Color(0xFFF7F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F0F2);
  static const Color lightText = Color(0xFF222222);
  static const Color lightSubtext = Color(0xFF555555);
  static const Color lightBorder = Color(0xFFDDDDDD);

  // ------------------------------------------------------------
  // GRADIENTS
  // ------------------------------------------------------------
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D0D0F),
      Color(0xFF111113),
      Color(0xFF19191C),
    ],
  );

  static const LinearGradient cardPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9F7BFF),
      Color(0xFF8756FF),
    ],
  );

  static const LinearGradient workoutCTA = LinearGradient(
    colors: [
      Color(0xFFF857A6),
      Color(0xFFFF5858),
    ],
  );

  static const LinearGradient blueGoalGradient = LinearGradient(
    colors: [
      Color(0xFF4D9EFF),
      Color(0xFF3269FF),
    ],
  );

  // ------------------------------------------------------------
  // STATE COLORS
  // ------------------------------------------------------------
  static const Color success = Color(0xFF2CB67D);
  static const Color warning = Color(0xFFF4B860);
  static const Color danger = Color(0xFFFF6B6B);

  // ------------------------------------------------------------
  // SHADOW COLORS (no deprecated opacity)
  // ------------------------------------------------------------
  static Color shadowDark = Color.fromARGB(63, 0, 0, 0); // 0.25 opacity
  static Color shadowLight = Color.fromARGB(51, 0, 0, 0); // 0.20 opacity

  // ------------------------------------------------------------
  // OPACITY HELPERS (non-deprecated)
  // ------------------------------------------------------------
  static Color whiteOpacity(double opacity) =>
      Color.fromRGBO(255, 255, 255, opacity);

  static Color blackOpacity(double opacity) =>
      Color.fromRGBO(0, 0, 0, opacity);

  // ------------------------------------------------------------
  // THEME-AWARE COLORS
  // ------------------------------------------------------------
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBg
          : lightBg;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkText
          : lightText;

  static Color subtext(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSubtext
          : lightSubtext;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkCard
          : lightCard;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorder
          : lightBorder;
}
