// lib/presentation/theme/app_text.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized typography system for ZetaFit.
/// Automatically adapts to light/dark theme using [AppColors].
class AppText {
  // ------------------------------------------------------------
  // HEADINGS
  // ------------------------------------------------------------

  static TextStyle heading1(BuildContext context) => GoogleFonts.michroma(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppColors.text(context),
      );

  static TextStyle heading2(BuildContext context) => GoogleFonts.michroma(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.text(context),
      );

  static TextStyle heading3(BuildContext context) => GoogleFonts.michroma(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.text(context),
      );

  // ------------------------------------------------------------
  // SUBTITLES
  // ------------------------------------------------------------

  static TextStyle subtitle1(BuildContext context) => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text(context),
      );

  static TextStyle subtitle2(BuildContext context) => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.subtext(context),
      );

  // ------------------------------------------------------------
  // BODY TEXT
  // ------------------------------------------------------------

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.text(context),
      );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.text(context),
      );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.subtext(context),
      );

  // ------------------------------------------------------------
  // LABELS / BUTTON TEXT
  // ------------------------------------------------------------

  static TextStyle labelBold(BuildContext context) => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.text(context),
      );

  static TextStyle labelMedium(BuildContext context) => GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.text(context),
      );

  static TextStyle labelSmall(BuildContext context) => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.subtext(context),
      );

  // ------------------------------------------------------------
  // SPECIAL TYPOGRAPHY
  // ------------------------------------------------------------

  /// Neon / Highlight text (for stats + numbers)
  static TextStyle statNumber(BuildContext context) => GoogleFonts.michroma(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  /// Used for "Workout of the day", "Today's Goal", etc.
  static TextStyle sectionTitle(BuildContext context) =>
      GoogleFonts.montserrat(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.subtext(context),
      );

  /// For captions or micro text
  static TextStyle caption(BuildContext context) => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.subtext(context),
      );
}
