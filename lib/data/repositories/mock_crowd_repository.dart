import 'package:flutter/material.dart';
import '../../domain/repositories/crowd_repository.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/geofence_service.dart';
import '../models/crowd_telemetry_model.dart';

class MockCrowdRepository with ChangeNotifier implements CrowdRepository {
  CrowdTelemetryModel _crowdData = CrowdTelemetryModel(
    status: 'moderate',
    estimatedWaitMinutes: 25,
    timestamp: DateTime.now().toIso8601String(),
    currentVisitors: 1250,
  );

  MockCrowdRepository() {
    _listenToCloudTelemetry();
  }

  void _listenToCloudTelemetry() {
    FirebaseService.instance.streamCrowdTelemetry().listen((data) {
      if (data.isNotEmpty) {
        final inside = (data['currentInsideCount'] as num?)?.toInt() ?? _crowdData.currentVisitors;
        final wait = (data['estimatedWaitMinutes'] as num?)?.toInt() ?? _crowdData.estimatedWaitMinutes;
        final status = (data['status'] as String?) ?? _crowdData.status;

        _crowdData = _crowdData.copyWith(
          currentVisitors: inside,
          estimatedWaitMinutes: wait,
          status: status,
          timestamp: DateTime.now().toIso8601String(),
        );
        notifyListeners();
      }
    });
  }

  @override
  CrowdTelemetryModel getCrowdData() => _crowdData;

  @override
  void updateCrowdData(CrowdTelemetryModel data) {
    _crowdData = data;
    notifyListeners();
  }

  @override
  Future<void> refreshCrowdData() async {
    await Future.delayed(const Duration(seconds: 2));
    _crowdData = _crowdData.copyWith(
      timestamp: DateTime.now().toIso8601String(),
    );
    notifyListeners();
  }

  // ── Dual-Source Deduplication (GPS Geofence + Gate Ticket Scans) ─────────
  final Set<String> _insideGeofenceDevotees = {};
  final Set<String> _scannedTicketDevotees = {};
  int _overlapDeduplicatedCount = 0;

  int get overlapDeduplicatedCount => _overlapDeduplicatedCount;
  int get geofenceDevoteeCount => _insideGeofenceDevotees.length;
  int get scannedTicketCount => _scannedTicketDevotees.length;

  /// Records a gate ticket scan with dual-source deduplication.
  /// If the devotee is already inside the geofence, avoids counting them twice.
  void recordTicketVerification(String ticketOrUserId) {
    if (_scannedTicketDevotees.contains(ticketOrUserId)) return;
    _scannedTicketDevotees.add(ticketOrUserId);

    if (_insideGeofenceDevotees.contains(ticketOrUserId)) {
      // Devotee was already counted when entering the GPS geofence.
      // Do NOT increment visitor count again!
      _overlapDeduplicatedCount++;
    } else {
      // Walk-in / non-geofenced devotee. Increment crowd count once.
      _adjustVisitors(1);
    }
    notifyListeners();
  }

  /// Records geofence entry/exit with deduplication.
  void recordGeofenceEvent(GeofenceEvent event, [String? userId]) {
    final uid = userId ?? 'devotee_session';
    if (event == GeofenceEvent.enter) {
      if (_insideGeofenceDevotees.contains(uid)) return;
      _insideGeofenceDevotees.add(uid);

      if (_scannedTicketDevotees.contains(uid)) {
        // Devotee already scanned ticket at the gate.
        _overlapDeduplicatedCount++;
      } else {
        _adjustVisitors(1);
      }
    } else {
      _insideGeofenceDevotees.remove(uid);
      _scannedTicketDevotees.remove(uid);
      _adjustVisitors(-1);
    }
    notifyListeners();
  }

  // ── Geofence integration ───────────────────────────────────────────────────

  /// Call once from main.dart after the repository is created.
  Future<void> initGeofence() async {
    await GeofenceService.instance.init();

    GeofenceService.instance.onGeofenceEvent = (event) {
      recordGeofenceEvent(event);
    };

    await GeofenceService.instance.startMonitoring();
  }

  void _adjustVisitors(int delta) {
    final updated = (_crowdData.currentVisitors + delta).clamp(0, 99999);
    _crowdData = _crowdData.copyWith(
      currentVisitors: updated,
      status: _statusFromCount(updated),
      estimatedWaitMinutes: _waitFromCount(updated),
      timestamp: DateTime.now().toIso8601String(),
    );
    notifyListeners();
  }

  /// Thresholds — tune these to match your temple's actual capacity.
  String _statusFromCount(int count) {
    if (count < 500) return 'low';
    if (count < 1000) return 'moderate';
    if (count < 2000) return 'high';
    return 'veryhigh';
  }

  int _waitFromCount(int count) {
    if (count < 500) return 10;
    if (count < 1000) return 20;
    if (count < 2000) return 40;
    return 60;
  }
}
