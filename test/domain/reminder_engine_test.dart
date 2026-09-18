import 'package:flutter_test/flutter_test.dart';
import 'package:ojol_daily/domain/enums.dart';
import 'package:ojol_daily/domain/models.dart';
import 'package:ojol_daily/domain/reminder_calculator.dart';

void main() {
  final testDate = DateTime(2026, 9, 18, 20, 30); // Friday 20:30

  group('Reminder Engine Unit Tests (PRD Section 48 / AC-01 to AC-17)', () {
    // AC-05 & Section 4.1: Reminder NOT eligible on OFF days
    test('AC-05: First reminder NOT eligible on OFF days', () {
      const settings = ReminderSettings(enabled: true, firstReminderTime: '20:00');
      final isEligible = ReminderCalculator.isFirstReminderEligible(
        settings: settings,
        dayStatus: DayStatus.off,
        incomeTodayAmount: 0,
        reminderLog: null,
        currentTime: testDate,
      );
      expect(isEligible, false);
    });

    // AC-06 & Section 4.2: Reminder NOT eligible if income today > 0
    test('AC-06: Reminder NOT eligible if income today > 0', () {
      const settings = ReminderSettings(enabled: true, firstReminderTime: '20:00');
      final isEligible = ReminderCalculator.isFirstReminderEligible(
        settings: settings,
        dayStatus: DayStatus.working,
        incomeTodayAmount: 150000,
        reminderLog: null,
        currentTime: testDate,
      );
      expect(isEligible, false);
    });

    // Section 4.3: Disabled reminders
    test('AC-01: Reminder NOT eligible if master toggle is OFF', () {
      const settings = ReminderSettings(enabled: false, firstReminderTime: '20:00');
      final isEligible = ReminderCalculator.isFirstReminderEligible(
        settings: settings,
        dayStatus: DayStatus.working,
        incomeTodayAmount: 0,
        reminderLog: null,
        currentTime: testDate,
      );
      expect(isEligible, false);
    });

    // Section 11: First reminder eligible
    test('First reminder ELIGIBLE when time reached, working day, 0 income', () {
      const settings = ReminderSettings(enabled: true, firstReminderTime: '20:00');
      final isEligible = ReminderCalculator.isFirstReminderEligible(
        settings: settings,
        dayStatus: DayStatus.working,
        incomeTodayAmount: 0,
        reminderLog: null,
        currentTime: testDate, // 20:30 >= 20:00
      );
      expect(isEligible, true);
    });

    // Section 11: First reminder NOT eligible before scheduled time
    test('First reminder NOT eligible before scheduled time', () {
      const settings = ReminderSettings(enabled: true, firstReminderTime: '21:00');
      final isEligible = ReminderCalculator.isFirstReminderEligible(
        settings: settings,
        dayStatus: DayStatus.working,
        incomeTodayAmount: 0,
        reminderLog: null,
        currentTime: DateTime(2026, 9, 18, 20, 30), // 20:30 < 21:00
      );
      expect(isEligible, false);
    });

    // Section 11: Second reminder eligible only if first sent and 0 income
    test('Second reminder ELIGIBLE when first sent and time reached', () {
      const settings = ReminderSettings(
        enabled: true,
        firstReminderEnabled: true,
        firstReminderTime: '20:00',
        secondReminderEnabled: true,
        secondReminderTime: '22:00',
      );
      const reminderLog = ReminderLog(
        dateString: '2026-09-18',
        firstReminderSent: true,
        secondReminderSent: false,
      );
      final lateDate = DateTime(2026, 9, 18, 22, 15);

      final isEligible = ReminderCalculator.isSecondReminderEligible(
        settings: settings,
        dayStatus: DayStatus.working,
        incomeTodayAmount: 0,
        reminderLog: reminderLog,
        currentTime: lateDate,
      );
      expect(isEligible, true);
    });

    // AC-10: Auto-cancellation of second reminder when income is logged
    test('AC-10: Second reminder NOT eligible if income was logged after first reminder', () {
      const settings = ReminderSettings(
        enabled: true,
        firstReminderTime: '20:00',
        secondReminderTime: '22:00',
      );
      const reminderLog = ReminderLog(
        dateString: '2026-09-18',
        firstReminderSent: true,
        secondReminderSent: false,
      );
      final lateDate = DateTime(2026, 9, 18, 22, 15);

      final isEligible = ReminderCalculator.isSecondReminderEligible(
        settings: settings,
        dayStatus: DayStatus.working,
        incomeTodayAmount: 200000, // Income logged at 20:15!
        reminderLog: reminderLog,
        currentTime: lateDate,
      );
      expect(isEligible, false);
    });

    // AC-15 & AC-16: Dashboard Reminder Banner visibility
    test('AC-15 & AC-16: Dashboard Banner visible when income == 0 and day != OFF, hidden when income > 0', () {
      final showBanner1 = ReminderCalculator.shouldShowDashboardBanner(
        dayStatus: DayStatus.working,
        incomeTodayAmount: 0,
      );
      expect(showBanner1, true);

      final showBanner2 = ReminderCalculator.shouldShowDashboardBanner(
        dayStatus: DayStatus.off,
        incomeTodayAmount: 0,
      );
      expect(showBanner2, false);

      final showBanner3 = ReminderCalculator.shouldShowDashboardBanner(
        dayStatus: DayStatus.working,
        incomeTodayAmount: 100000,
      );
      expect(showBanner3, false);
    });

    // Workday filter check
    test('Workday filter prevents reminder on excluded day', () {
      // Exclude Friday (weekday 5)
      const settings = ReminderSettings(
        enabled: true,
        firstReminderTime: '20:00',
        workDays: [1, 2, 3, 4, 6, 7], // Friday (5) missing
      );
      final fridayDate = DateTime(2026, 9, 18, 20, 30); // Friday (5)

      final isEligible = ReminderCalculator.isFirstReminderEligible(
        settings: settings,
        dayStatus: DayStatus.working,
        incomeTodayAmount: 0,
        reminderLog: null,
        currentTime: fridayDate,
      );
      expect(isEligible, false);
    });
  });
}
