import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Channel IDs
  static const String remindersChannelId = 'temple_reminders_channel';
  static const String bookingsChannelId = 'temple_bookings_channel';
  static const String geofenceChannelId = 'geofence_channel';

  /// Initialize local notifications plugin and configure notification channels
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Timezones for accurate scheduling
      tz.initializeTimeZones();

      // 2. Platform initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] Notification clicked: ${response.payload}');
        },
      );

      // 3. Setup Android Channels (Android 8.0+)
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImpl != null) {
          // Reminders Channel
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              remindersChannelId,
              'Temple & Festival Reminders',
              description: 'Notifications for upcoming festivals, poojas, and auspicious days',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Bookings & Passes Channel
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              bookingsChannelId,
              'Darshan & Shuttle Passes',
              description: 'Real-time pass confirmation, gate scan verification, and slot alerts',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Geofence Channel
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              geofenceChannelId,
              'Temple Geofence & Proximity',
              description: 'Arrival and departure notifications around temple hill premises',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Request Android 13+ runtime permissions
          await androidImpl.requestNotificationsPermission();
        }
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Notifications & Reminder service initialized successfully.');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error (degraded gracefully): $e');
    }
  }

  /// Request notification permissions (useful if prompted during festival toggle or booking)
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? true;
      } else if (Platform.isIOS) {
        final iosImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error requesting permissions: $e');
      return false;
    }
  }

  /// Display an instant notification to the user
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = remindersChannelId,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == bookingsChannelId
              ? 'Darshan & Shuttle Passes'
              : (channelId == geofenceChannelId ? 'Temple Geofence' : 'Temple Reminders'),
          channelDescription: 'Temple updates and alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFD97706),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[NotificationService] Error showing notification: $e');
    }
  }

  /// Schedule a future reminder notification at a specific [scheduledDate]
  Future<bool> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channelId = remindersChannelId,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    try {
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) {
        // If already passed today, display immediate confirmation
        await showNotification(
          id: id,
          title: title,
          body: body,
          channelId: channelId,
          payload: payload,
        );
        return true;
      }

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Temple & Festival Reminders',
          channelDescription: 'Upcoming festival notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFD97706),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint('[NotificationService] Reminder #$id successfully scheduled for $tzDateTime');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule zoned notification: $e. Falling back to instant confirmation.');
      // Graceful fallback
      await showNotification(
        id: id,
        title: title,
        body: body,
        channelId: channelId,
        payload: payload,
      );
      return false;
    }
  }

  /// Cancel a specific notification / reminder by ID
  Future<void> cancelReminder(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling reminder #$id: $e');
    }
  }

  // ── Festival Reminders ──────────────────────────────────────────────────────

  static const String _festivalPrefsKey = 'sannidhi_festival_reminders';

  /// Sets a persistent reminder for a festival
  Future<bool> setFestivalReminder({
    required String festivalId,
    required String festivalName,
    DateTime? festivalDate,
    String? dateStr,
    bool isTamil = false,
  }) async {
    try {
      await requestPermissions();

      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_festivalPrefsKey) ?? [];
      if (!list.contains(festivalId)) {
        list.add(festivalId);
        await prefs.setStringList(_festivalPrefsKey, list);
      }

      final notifId = festivalId.hashCode.abs() % 100000;

      // Parse festival date (e.g. 7:00 AM on the festival day)
      final festDate = festivalDate ?? (dateStr != null ? DateTime.tryParse(dateStr) : null);
      final effectiveDateStr = dateStr ??
          (festDate != null
              ? '${festDate.year}-${festDate.month.toString().padLeft(2, '0')}-${festDate.day.toString().padLeft(2, '0')}'
              : '');

      DateTime scheduledTime;
      if (festDate != null) {
        scheduledTime = DateTime(festDate.year, festDate.month, festDate.day, 7, 0);
      } else {
        scheduledTime = DateTime.now().add(const Duration(hours: 4));
      }

      // 1. Show immediate confirmation
      await showNotification(
        id: notifId,
        title: isTamil
            ? '🙏 திருவிழா நினைவூட்டல் பதிவு செய்யப்பட்டது'
            : '🙏 Festival Reminder Activated',
        body: isTamil
            ? '$festivalName திருவிழாவிற்கு நினைவூட்டல் அமைக்கப்பட்டது ($effectiveDateStr).'
            : 'Reminder set for $festivalName on $effectiveDateStr. Blessed darshan!',
        channelId: remindersChannelId,
        payload: 'festival:$festivalId',
      );

      // 2. Schedule the morning reminder for the actual festival day if in future
      if (scheduledTime.isAfter(DateTime.now())) {
        await scheduleReminder(
          id: notifId + 1,
          title: isTamil
              ? '✨ இன்று $festivalName திருவிழா!'
              : '✨ Today is $festivalName!',
          body: isTamil
              ? 'மருதமலை தேவஸ்தானத்தில் சிறப்பு பூஜைகள் மற்றும் தரிசனம் நடைபெறுகிறது.'
              : 'Special pooja and darshan are taking place at Maruthamalai Temple.',
          scheduledDate: scheduledTime,
          channelId: remindersChannelId,
          payload: 'festival:$festivalId',
        );
      }

      return true;
    } catch (e) {
      debugPrint('[NotificationService] Error setting festival reminder: $e');
      return false;
    }
  }

  /// Cancels a festival reminder and clears persistence
  Future<void> cancelFestivalReminder(String festivalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_festivalPrefsKey) ?? [];
      list.remove(festivalId);
      await prefs.setStringList(_festivalPrefsKey, list);

      final notifId = festivalId.hashCode.abs() % 100000;
      await cancelReminder(notifId);
      await cancelReminder(notifId + 1);
    } catch (e) {
      debugPrint('[NotificationService] Error removing festival reminder: $e');
    }
  }

  /// Checks if a festival reminder is currently active
  Future<bool> isFestivalReminderSet(String festivalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_festivalPrefsKey) ?? [];
      return list.contains(festivalId);
    } catch (_) {
      return false;
    }
  }

  // ── Booking & Pass Notifications ────────────────────────────────────────────

  /// Fires a notification when a new pass is confirmed
  Future<void> notifyBookingConfirmed({
    required String bookingId,
    required String title,
    required String slotTime,
    required String date,
    int? seatCount,
    bool isTamil = false,
  }) async {
    final id = ('bk_$bookingId').hashCode.abs() % 100000;
    final seatsText = seatCount != null && seatCount > 1 ? ' ($seatCount passes)' : '';
    final seatsTextTa = seatCount != null && seatCount > 1 ? ' ($seatCount நபர்கள்)' : '';
    await showNotification(
      id: id,
      title: isTamil ? '🎟️ பாஸ் முன்பதிவு உறுதியானது' : '🎟️ Pass Confirmed Successfully',
      body: isTamil
          ? '$title$seatsTextTa • நேரம்: $slotTime ($date). முன்பதிவு எண்: #$bookingId'
          : '$title$seatsText • Slot: $slotTime ($date). Booking Ref: #$bookingId',
      channelId: bookingsChannelId,
      payload: 'booking:$bookingId',
    );
  }

  /// Fires a notification when a pass is scanned live at the temple gate
  Future<void> notifyPassScanned({
    String? ticketId,
    String? passId,
    String? label,
    String? passTitle,
    String? verifiedBy,
    bool isTamil = false,
  }) async {
    final effectiveId = ticketId ?? passId ?? 'pass';
    final displayTitle = passTitle ?? label ?? 'Pass';
    final gateText = verifiedBy != null ? ' by $verifiedBy' : '';
    final id = ('scan_$effectiveId').hashCode.abs() % 100000;
    await showNotification(
      id: id,
      title: isTamil
          ? '🙏 வாயிலில் சரிபார்க்கப்பட்டது • நல்வரவு!'
          : '🙏 Gate Pass Verified • Welcome!',
      body: isTamil
          ? '$displayTitle வெற்றிகரமாக சரிபார்க்கப்பட்டு அனுமதிக்கப்பட்டது. இனிய தரிசனம்!'
          : '$displayTitle verified$gateText. Welcome and have a blessed darshan!',
      channelId: bookingsChannelId,
      payload: 'ticket:$ticketId',
    );
  }

  /// Fires a notification if a pass validity lapsed
  Future<void> notifyPassExpired({
    required String ticketId,
    required String slotTime,
    bool isTamil = false,
  }) async {
    final id = ('exp_$ticketId').hashCode.abs() % 100000;
    await showNotification(
      id: id,
      title: isTamil ? '⚠️ பாஸ் காலாவதியானது' : '⚠️ Gate Pass Expired',
      body: isTamil
          ? 'முன்பதிவு நேரம் ($slotTime) முடிந்தது. பாஸ் ஸ்கேன் செய்யப்படவில்லை.'
          : 'Your scheduled slot ($slotTime) has passed without gate verification.',
      channelId: bookingsChannelId,
      payload: 'expired:$ticketId',
    );
  }
}
