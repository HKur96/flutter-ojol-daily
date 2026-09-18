/// Pure Dart Reminder Engine for PRD Section 48.11 eligibility rules
library;

import 'enums.dart';
import 'models.dart';

class ReminderCalculator {
  /// Evaluates whether the FIRST reminder is eligible to be sent (PRD Section 48.11)
  static bool isFirstReminderEligible({
    required ReminderSettings settings,
    required DayStatus dayStatus,
    required int incomeTodayAmount,
    required ReminderLog? reminderLog,
    required DateTime currentTime,
  }) {
    // 4.3 Reminder Enabled == FALSE
    if (!settings.enabled || !settings.firstReminderEnabled) return false;

    // 4.1 Day Status == OFF
    if (dayStatus == DayStatus.off) return false;

    // Workday filter check
    if (!settings.workDays.contains(currentTime.weekday)) return false;

    // 4.2 Income Today > 0
    if (incomeTodayAmount > 0) return false;

    // Already sent
    if (reminderLog?.firstReminderSent == true) return false;

    // Time check: currentTime >= firstReminderTime
    final reminderTime = _parseTime(settings.firstReminderTime, currentTime);
    return currentTime.isAfter(reminderTime) || currentTime.isAtSameMomentAs(reminderTime);
  }

  /// Evaluates whether the SECOND reminder is eligible to be sent (PRD Section 48.11)
  static bool isSecondReminderEligible({
    required ReminderSettings settings,
    required DayStatus dayStatus,
    required int incomeTodayAmount,
    required ReminderLog? reminderLog,
    required DateTime currentTime,
  }) {
    // 4.3 Reminder Enabled == FALSE
    if (!settings.enabled || !settings.secondReminderEnabled) return false;

    // 4.1 Day Status == OFF
    if (dayStatus == DayStatus.off) return false;

    // Workday filter check
    if (!settings.workDays.contains(currentTime.weekday)) return false;

    // 4.2 Income Today > 0
    if (incomeTodayAmount > 0) return false;

    // First reminder must have been sent
    if (reminderLog?.firstReminderSent != true) return false;

    // Second reminder not already sent
    if (reminderLog?.secondReminderSent == true) return false;

    // Time check: currentTime >= secondReminderTime
    final reminderTime = _parseTime(settings.secondReminderTime, currentTime);
    return currentTime.isAfter(reminderTime) || currentTime.isAtSameMomentAs(reminderTime);
  }

  /// Evaluates whether the Dashboard Reminder Banner should be shown (PRD Section 48.8)
  static bool shouldShowDashboardBanner({
    required DayStatus dayStatus,
    required int incomeTodayAmount,
  }) {
    if (dayStatus == DayStatus.off) return false;
    return incomeTodayAmount == 0;
  }

  static DateTime _parseTime(String timeStr, DateTime baseDate) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } catch (_) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day, 20, 0);
    }
  }
}
