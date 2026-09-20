/// Notification Service managing local push notifications & deep-link callbacks (PRD Section 48)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/models.dart';

typedef QuickInputCallback = void Function(String actionPayload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  QuickInputCallback? _onNotificationTap;

  bool _isInitialized = false;

  void setNotificationTapHandler(QuickInputCallback handler) {
    _onNotificationTap = handler;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && _onNotificationTap != null) {
            _onNotificationTap!(response.payload!);
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint("NotificationService init exception: $e");
    }
  }

  /// Request notification permission (PRD Section 48.13)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
      return false;
    }
  }

  /// Schedule daily reminder notifications (PRD Section 48.3, 48.14)
  Future<void> scheduleDailyReminders(ReminderSettings settings) async {
    if (!_isInitialized || !settings.enabled || settings.workDays.isEmpty) {
      await cancelAllReminders();
      return;
    }

    await cancelAllReminders();

    // Schedule First Reminder (Default 20:00) per weekday
    if (settings.firstReminderEnabled) {
      final firstTimeParts = settings.firstReminderTime.split(':');
      final firstHour = int.tryParse(firstTimeParts[0]) ?? 20;
      final firstMinute = int.tryParse(firstTimeParts[1]) ?? 0;

      for (final day in settings.workDays) {
        await _scheduleDailyNotification(
          id: 1000 + day,
          title: "Jangan lupa catat pendapatan",
          body:
              "Sudah selesai narik? Catat pendapatan hari ini supaya targetmu tetap akurat.",
          dayOfWeek: day,
          hour: firstHour,
          minute: firstMinute,
          payload: "QUICK_INPUT_INCOME",
        );
      }
    }

    // Schedule Second Reminder (Default 22:00) per weekday
    if (settings.secondReminderEnabled) {
      final secondTimeParts = settings.secondReminderTime.split(':');
      final secondHour = int.tryParse(secondTimeParts[0]) ?? 22;
      final secondMinute = int.tryParse(secondTimeParts[1]) ?? 0;

      for (final day in settings.workDays) {
        await _scheduleDailyNotification(
          id: 2000 + day,
          title: "Pendapatan hari ini sudah dicatat?",
          body: "Cukup masukkan total pendapatan hari ini. Tidak perlu lama.",
          dayOfWeek: day,
          hour: secondHour,
          minute: secondMinute,
          payload: "QUICK_INPUT_INCOME",
        );
      }
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    try {
      final scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, hour, minute);

      const androidDetails = AndroidNotificationDetails(
        'ojol_daily_reminders',
        'Pengingat Input Harian',
        channelDescription: 'Pengingat pencatatan pendapatan harian driver',
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }
  }

  /// Cancel all scheduled reminders (PRD Section 48.16, 48.18)
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancel(1001);
      await _notificationsPlugin.cancel(1002);
      for (int day = 1; day <= 7; day++) {
        await _notificationsPlugin.cancel(1000 + day);
        await _notificationsPlugin.cancel(2000 + day);
      }
    } catch (e) {
      debugPrint("Error cancelling notifications: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
