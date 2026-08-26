import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

// ── Exact Temple coordinates  ──────────────────────
const double _templeLat = 11.04611;
const double _templeLng = 76.85194;
const double _radiusMetres = 300.0;

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

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    await _initNotifications();
  }

  // ── Start / Stop ───────────────────────────────────────────────────────────

  /// Returns false if permission was denied.
  Future<bool> startMonitoring() async {
    final granted = await _requestPermission();
    if (!granted) return false;

    // Medium accuracy + 15 m filter = very low battery drain.
    // Works in background because we request `always` permission.
    _positionSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 15,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Sannidhi',
          notificationText: 'Monitoring temple proximity',
          enableWakeLock: false,
        ),
      ),
    ).listen(_onPosition);

    return true;
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
      _notify(
        'Welcome to Sannidhi Temple 🙏',
        'You have entered the temple premises. Have a blessed darshan.',
      );
    } else if (!inside && _insideGeofence) {
      _insideGeofence = false;
      onGeofenceEvent?.call(GeofenceEvent.exit);
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
