import 'package:flutter/material.dart';
import '../../domain/repositories/crowd_repository.dart';
import '../../core/services/geofence_service.dart';
import '../models/crowd_telemetry_model.dart';

class MockCrowdRepository with ChangeNotifier implements CrowdRepository {
  CrowdTelemetryModel _crowdData = CrowdTelemetryModel(
    status: 'moderate',
    estimatedWaitMinutes: 25,
    timestamp: DateTime.now().toIso8601String(),
    currentVisitors: 1250,
  );

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

  // ── Geofence integration ───────────────────────────────────────────────────

  /// Call once from main.dart after the repository is created.
  Future<void> initGeofence() async {
    await GeofenceService.instance.init();

    GeofenceService.instance.onGeofenceEvent = (event) {
      if (event == GeofenceEvent.enter) {
        _adjustVisitors(1);
      } else {
        _adjustVisitors(-1);
      }
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
