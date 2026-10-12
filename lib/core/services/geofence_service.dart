import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

// ── Exact Temple coordinates  ──────────────────────
const double _templeLat = 11.04611;
const double _templeLng = 76.85194;
const double _radiusMetres = 500.0;

enum GeofenceEvent { enter, exit }

/// Rich context conveying the 3-tier footfall calculation
class GeofenceArrivalContext {
  final GeofenceEvent event;
  final int tier; // 1 = Active Booking, 2 = Prompt / Saved Profile, 3 = Macro Multiplier
  final int devoteeCount;
  final String sourceDescription;

  const GeofenceArrivalContext({
    required this.event,
    required this.tier,
    required this.devoteeCount,
    required this.sourceDescription,
  });
}

class GeofenceService {
  GeofenceService._();
  static final GeofenceService instance = GeofenceService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<Position>? _positionSub;
  bool _insideGeofence = false;
  bool _initialised = false;

  /// Current session devotee group count (e.g., 4 if visiting with family)
  int _currentSessionDevoteeCount = 1;

  /// Notifier triggered when Tier 2 prompt is required (no active booking found)
  final ValueNotifier<bool> pendingFamilyPromptNotifier = ValueNotifier<bool>(false);

  /// Fires once on enter, once on exit.
  void Function(GeofenceEvent)? onGeofenceEvent;

  /// Detailed 3-tier arrival callback providing accurate devotee count
  void Function(GeofenceArrivalContext)? onArrivalContextResolved;

  bool get isInsideTemple => _insideGeofence;
  int get currentSessionDevoteeCount => _currentSessionDevoteeCount;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    try {
      await _initNotifications();
    } catch (e) {
      debugPrint('[GeofenceService] Notification init skipped: $e');
    }
  }

  // ── 3-Tier Resolution Helpers ──────────────────────────────────────────────

  /// Tier 1: Check if the user has an active Darshan or Shuttle booking for today.
  Future<int?> getTodayActiveBookingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // Check Darshan bookings
      final darshanRaw = prefs.getString('sannidhi_darshan_bookings');
      if (darshanRaw != null) {
        final list = jsonDecode(darshanRaw) as List<dynamic>;
        for (final b in list) {
          final m = b as Map<String, dynamic>;
          final bDate = (m['date'] ?? '').toString();
          final isCancelled = m['isCancelled'] == true;
          if (!isCancelled && (bDate.contains(todayStr) || todayStr.contains(bDate))) {
            final count = (m['ticketCount'] as num?)?.toInt() ?? 1;
            return count > 0 ? count : 1;
          }
        }
      }

      // Check Shuttle bookings
      final shuttleRaw = prefs.getString('sannidhi_shuttle_bookings');
      if (shuttleRaw != null) {
        final list = jsonDecode(shuttleRaw) as List<dynamic>;
        for (final b in list) {
          final m = b as Map<String, dynamic>;
          final bDate = (m['date'] ?? '').toString();
          final isCancelled = m['isCancelled'] == true;
          if (!isCancelled && (bDate.contains(todayStr) || todayStr.contains(bDate))) {
            final count = (m['seatCount'] as num?)?.toInt() ?? 1;
            return count > 0 ? count : 1;
          }
        }
      }
    } catch (e) {
      debugPrint('[GeofenceService] Error reading today bookings: $e');
    }
    return null;
  }

  /// Tier 2: Check saved default family size in devotee profile
  Future<int?> getSavedFamilySize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('sannidhi_default_family_size');
    } catch (_) {
      return null;
    }
  }

  /// Save default family size preference
  Future<void> saveDefaultFamilySize(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sannidhi_default_family_size', count);
    } catch (e) {
      debugPrint('[GeofenceService] Error saving default family size: $e');
    }
  }

  /// Update group size manually via in-app prompt or notification action tap
  Future<void> updateDevoteeGroupCount(
    int count, {
    bool saveAsDefault = false,
    bool isUserInitiated = true,
  }) async {
    final effectiveCount = count.clamp(1, 20);
    _currentSessionDevoteeCount = effectiveCount;
    pendingFamilyPromptNotifier.value = false;

    if (saveAsDefault) {
      await saveDefaultFamilySize(effectiveCount);
    }

    onArrivalContextResolved?.call(
      GeofenceArrivalContext(
        event: GeofenceEvent.enter,
        tier: 2,
        devoteeCount: effectiveCount,
        sourceDescription: 'Tier 2: Devotee Declared ($effectiveCount devotees)',
      ),
    );

    if (isUserInitiated) {
      _notify(
        'Family Group Updated 🙏',
        'Logged visit for $effectiveCount devotees. Live crowd queue times updated.',
      );
    }
  }

  /// Allows manual simulation of geofence hardware trigger for testing
  Future<void> simulateHardwareTrigger(bool isEntering) async {
    if (isEntering) {
      _insideGeofence = true;
      await _handleGeofenceEnter(latitude: _templeLat, longitude: _templeLng);
    } else {
      _insideGeofence = false;
      await _handleGeofenceExit(latitude: _templeLat, longitude: _templeLng);
    }
  }

  // ── Start / Stop Monitoring ────────────────────────────────────────────────

  Future<bool> startMonitoring() async {
    try {
      final granted = await _requestPermission();
      if (!granted) return false;

      final LocationSettings settings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.medium,
              distanceFilter: 15,
              foregroundNotificationConfig: const ForegroundNotificationConfig(
                notificationTitle: 'Sannidhi',
                notificationText: 'Monitoring temple proximity',
                enableWakeLock: false,
              ),
            )
          : AppleSettings(
              accuracy: LocationAccuracy.medium,
              distanceFilter: 15,
              activityType: ActivityType.other,
              pauseLocationUpdatesAutomatically: true,
            );

      _positionSub = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        _onPosition,
        onError: (err) {
          debugPrint('[GeofenceService] Position stream error: $err');
        },
      );

      return true;
    } catch (e) {
      debugPrint('[GeofenceService] Location monitoring skipped: $e');
      return false;
    }
  }

  void stopMonitoring() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  // ── Position & Event Handling ──────────────────────────────────────────────

  void _onPosition(Position pos) async {
    final dist = _distanceMetres(pos.latitude, pos.longitude);
    final inside = dist <= _radiusMetres;

    if (inside && !_insideGeofence) {
      _insideGeofence = true;
      await _handleGeofenceEnter(latitude: pos.latitude, longitude: pos.longitude);
    } else if (!inside && _insideGeofence) {
      _insideGeofence = false;
      await _handleGeofenceExit(latitude: pos.latitude, longitude: pos.longitude);
    }
  }

  Future<void> _handleGeofenceEnter({
    required double latitude,
    required double longitude,
  }) async {
    onGeofenceEvent?.call(GeofenceEvent.enter);
    await FirebaseService.instance.recordHardwareFootfall(
      isEntering: true,
      latitude: latitude,
      longitude: longitude,
    );

    // ── Tier 1: Check Active Darshan or Shuttle Bookings for today
    final bookingCount = await getTodayActiveBookingCount();
    if (bookingCount != null && bookingCount > 0) {
      _currentSessionDevoteeCount = bookingCount;
      pendingFamilyPromptNotifier.value = false;

      onArrivalContextResolved?.call(
        GeofenceArrivalContext(
          event: GeofenceEvent.enter,
          tier: 1,
          devoteeCount: bookingCount,
          sourceDescription: 'Tier 1: Active Booking ($bookingCount devotees)',
        ),
      );

      _notify(
        'Welcome to Sannidhi Temple 🙏',
        'Active booking verified for $bookingCount devotee(s). Your family is safely logged for queue times.',
      );
      return;
    }

    // ── Tier 2: Check Saved Family Size in Profile
    final savedSize = await getSavedFamilySize();
    if (savedSize != null && savedSize > 0) {
      _currentSessionDevoteeCount = savedSize;
      pendingFamilyPromptNotifier.value = false;

      onArrivalContextResolved?.call(
        GeofenceArrivalContext(
          event: GeofenceEvent.enter,
          tier: 2,
          devoteeCount: savedSize,
          sourceDescription: 'Tier 2: Saved Profile ($savedSize devotees)',
        ),
      );

      _notifyInteractive(
        'Welcome to Sannidhi Temple 🙏',
        'Logged visit for your saved family size of $savedSize. Tap to adjust if different today.',
      );
      return;
    }

    // ── Tier 2 Fallback: Interactive Lock-Screen & In-App Prompt
    _currentSessionDevoteeCount = 1;
    pendingFamilyPromptNotifier.value = true;

    onArrivalContextResolved?.call(
      const GeofenceArrivalContext(
        event: GeofenceEvent.enter,
        tier: 2,
        devoteeCount: 1,
        sourceDescription: 'Tier 2: Default 1 (Awaiting Devotee Prompt)',
      ),
    );

    _notifyInteractive(
      'Welcome to Sannidhi Temple 🙏',
      'Visiting with family or children? Tap your total group size below:',
    );
  }

  Future<void> _handleGeofenceExit({
    required double latitude,
    required double longitude,
  }) async {
    pendingFamilyPromptNotifier.value = false;
    onGeofenceEvent?.call(GeofenceEvent.exit);
    onArrivalContextResolved?.call(
      GeofenceArrivalContext(
        event: GeofenceEvent.exit,
        tier: 2,
        devoteeCount: _currentSessionDevoteeCount,
        sourceDescription: 'Exit (-$_currentSessionDevoteeCount devotees)',
      ),
    );

    await FirebaseService.instance.recordHardwareFootfall(
      isEntering: false,
      latitude: latitude,
      longitude: longitude,
    );

    _notify(
      'Goodbye 🙏',
      'You have left the temple premises. Thank you for visiting Marudamalai.',
    );
  }

  // ── Distance & Permissions ─────────────────────────────────────────────────

  double _distanceMetres(double lat, double lng) {
    const r = 6371000.0;
    final dLat = _rad(lat - _templeLat);
    final dLng = _rad(lng - _templeLng);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(_templeLat)) *
            cos(_rad(lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;

  Future<bool> _requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.whileInUse) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final actionId = response.actionId;
        if (actionId != null) {
          int count = 1;
          if (actionId == 'COUNT_1') count = 1;
          if (actionId == 'COUNT_2') count = 2;
          if (actionId == 'COUNT_4') count = 4;
          if (actionId == 'COUNT_5') count = 5;
          updateDevoteeGroupCount(count, isUserInitiated: true);
        } else {
          pendingFamilyPromptNotifier.value = true;
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'geofence_channel',
      'Temple Geofence',
      description: 'Alerts and interactive prompts when visiting temple',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _notify(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'geofence_channel',
        'Temple Geofence',
        channelDescription: 'Alerts and interactive prompts when visiting temple',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notifications.show(0, title, body, details);
  }

  Future<void> _notifyInteractive(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'geofence_channel',
        'Temple Geofence',
        channelDescription: 'Interactive family count lock-screen notification',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        actions: [
          AndroidNotificationAction('COUNT_1', 'Just Me (1)'),
          AndroidNotificationAction('COUNT_2', 'Family (2)'),
          AndroidNotificationAction('COUNT_4', 'Family (3-4)'),
          AndroidNotificationAction('COUNT_5', '5+ Devotees'),
        ],
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notifications.show(1, title, body, details);
  }
}
