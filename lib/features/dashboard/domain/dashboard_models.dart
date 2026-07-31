import 'package:flutter/material.dart';

/// Representation of a resume audit activity entry for the dashboard table.
class ResumeActivityItem {
  final String id;
  final String documentName;
  final String targetRole;
  final int atsScore;
  final DateTime date;

  const ResumeActivityItem({
    required this.id,
    required this.documentName,
    required this.targetRole,
    required this.atsScore,
    required this.date,
  });

  /// Status color determined by ATS score threshold
  Color get scoreColor {
    if (atsScore >= 80) return const Color(0xFF006A61); // Secondary Teal
    if (atsScore >= 65) return const Color(0xFF684000); // Amber Tertiary
    return const Color(0xFFBA1A1A); // Error Red
  }

  Color get scoreBgColor {
    if (atsScore >= 80) return const Color(0xFF86F2E4);
    if (atsScore >= 65) return const Color(0xFFFFDDB8);
    return const Color(0xFFFFDAD6);
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${_monthAbbr(date.month)} ${date.day}';
  }

  static String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }
}

/// Representation of weekly score trend entry for the dashboard chart.
class WeeklyScoreTrend {
  final String label; // e.g. W1, W2...
  final int score;    // Percentage 0-100

  const WeeklyScoreTrend({
    required this.label,
    required this.score,
  });
}
