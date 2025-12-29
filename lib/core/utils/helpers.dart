// lib/core/utils/helpers.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  /// Show a simple snackbar message
  static void showSnack(BuildContext context, String message,
      {Color background = Colors.black87}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool> confirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = "Yes",
    String cancelText = "Cancel",
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmText)),
        ],
      ),
    );
    return result ?? false;
  }

  /// Format a number with commas (e.g., 12000 → 12,000)
  static String formatNumber(num number) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(number);
  }

  /// Format date into human-friendly text
  static String formatDate(DateTime date, {bool includeTime = false}) {
    final dateFormat = DateFormat("dd MMM yyyy");
    final timeFormat = DateFormat("hh:mm a");

    return includeTime
        ? "${dateFormat.format(date)} • ${timeFormat.format(date)}"
        : dateFormat.format(date);
  }

  /// Check if two values are equal (safe for nulls)
  static bool equals(dynamic a, dynamic b) => a == b;

  /// Capitalize first letter of a string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Convert "john doe" → "John Doe"
  static String titleCase(String text) {
    return text.split(" ").map((word) => capitalize(word)).join(" ");
  }

  /// Avoid null errors by returning fallback text
  static String safeText(String? value, [String fallback = ""]) {
    return value ?? fallback;
  }

  /// Generate random ID (useful for local-only objects)
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
