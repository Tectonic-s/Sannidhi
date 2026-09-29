import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_service.dart';

// ── Exact Temple coordinates  ──────────────────────
const double _templeLat = 11.04611;
const double _templeLng = 76.85194;
const double _radiusMetres = 500.0;

enum GeofenceEvent { enter, exit }

class GeofenceService {
  GeofenceService._();
  static final GeofenceService instance = GeofenceService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<Position>? _positionSub;
  bool _insideGeofence = false;
  bool _initialised = false;

  /// Fires once on enter, once on exit.
  void Function(GeofenceEvent)? onGeofenceEvent;

  bool get isInsideTemple => _insideGeofence;

  /// Allows manual simulation of geofence hardware trigger for testing
  Future<void> simulateHardwareTrigger(bool isEntering) async {
    _insideGeofence = isEntering;
    onGeofenceEvent?.call(isEntering ? GeofenceEvent.enter : GeofenceEvent.exit);
    await FirebaseService.instance.recordHardwareFootfall(
      isEntering: isEntering,
      latitude: _templeLat,
      longitude: _templeLng,
    );
  }

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

  // ── Start / Stop ───────────────────────────────────────────────────────────

  /// Returns false if permission was denied.
  Future<bool> startMonitoring() async {
    try {
      final granted = await _requestPermission();
      if (!granted) return false;

      // Medium accuracy + 15 m filter = very low battery drain.
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

  // ── Private ────────────────────────────────────────────────────────────────

  void _onPosition(Position pos) {
    final dist = _distanceMetres(pos.latitude, pos.longitude);
    final inside = dist <= _radiusMetres;

    if (inside && !_insideGeofence) {
      _insideGeofence = true;
      onGeofenceEvent?.call(GeofenceEvent.enter);
      FirebaseService.instance.recordHardwareFootfall(
        isEntering: true,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _notify(
        'Welcome to Sannidhi Temple 🙏',
        'You have entered the temple premises. Have a blessed darshan.',
      );
    } else if (!inside && _insideGeofence) {
      _insideGeofence = false;
      onGeofenceEvent?.call(GeofenceEvent.exit);
      FirebaseService.instance.recordHardwareFootfall(
        isEntering: false,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _notify(
        'Goodbye 🙏',
        'You have left the temple premises. Thank you for visiting.',
      );
    }
  }

  /// Haversine formula — accurate distance in metres between two lat/lng points.
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
    // Ask for `always` so it works when app is closed.
    if (perm == LocationPermission.whileInUse) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create notification channel for Android 8+
    const channel = AndroidNotificationChannel(
      'geofence_channel',
      'Temple Geofence',
      description: 'Alerts when entering or leaving the temple',
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
        channelDescription: 'Alerts when entering or leaving the temple',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notifications.show(0, title, body, details);
  }
}
