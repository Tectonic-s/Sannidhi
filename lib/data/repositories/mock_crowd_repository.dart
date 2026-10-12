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

  // ── Dual-Source Deduplication (GPS Geofence + Gate Ticket Scans) ─────────
  final Set<String> _insideGeofenceDevotees = {};
  final Set<String> _scannedTicketDevotees = {};
  final Map<String, int> _geofenceGroupCounts = {};
  final Map<String, int> _scannedPassGroupCounts = {};
  int _overlapDeduplicatedCount = 0;

  // ── 3-Tier Multiplier & Family Estimation Telemetry ──────────────────────
  int _tier1BookingLinkedCount = 420;
  int _tier2DeclaredCount = 580;
  final int _tier3UnlinkedDevices = 140;

  double _demographicMultiplier = 1.8; // default weekday: 1.8x
  String _multiplierMode = 'weekday'; // 'weekday' (1.8x), 'weekend' (2.5x), 'festival' (3.2x), 'custom'

  int get overlapDeduplicatedCount => _overlapDeduplicatedCount;
  int get geofenceDevoteeCount => _insideGeofenceDevotees.length;
  int get scannedTicketCount => _scannedTicketDevotees.length;

  int get tier1BookingLinkedCount => _tier1BookingLinkedCount;
  int get tier2DeclaredCount => _tier2DeclaredCount;
  int get tier3UnlinkedDevices => _tier3UnlinkedDevices;
  int get tier3MacroEstimatedDevotees => (_tier3UnlinkedDevices * _demographicMultiplier).round();
  double get demographicMultiplier => _demographicMultiplier;
  String get multiplierMode => _multiplierMode;

  /// Combined true footfall considering all 3 tiers
  int get totalEstimatedFootfall {
    final computed = _tier1BookingLinkedCount + _tier2DeclaredCount + tier3MacroEstimatedDevotees;
    return computed > 0 ? computed : _crowdData.currentVisitors;
  }

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
    await Future.delayed(const Duration(seconds: 1));
    _crowdData = _crowdData.copyWith(
      currentVisitors: totalEstimatedFootfall,
      status: _statusFromCount(totalEstimatedFootfall),
      estimatedWaitMinutes: _waitFromCount(totalEstimatedFootfall),
      timestamp: DateTime.now().toIso8601String(),
    );
    notifyListeners();
  }

  // ── 3-Tier Multiplier Controls ─────────────────────────────────────────────

  void setDemographicMultiplier(double factor, [String? mode]) {
    _demographicMultiplier = factor.clamp(1.0, 5.0);
    if (mode != null) {
      _multiplierMode = mode;
    } else {
      if ((factor - 1.8).abs() < 0.05) {
        _multiplierMode = 'weekday';
      } else if ((factor - 2.5).abs() < 0.05) {
        _multiplierMode = 'weekend';
      } else if ((factor - 3.2).abs() < 0.05) {
        _multiplierMode = 'festival';
      } else {
        _multiplierMode = 'custom';
      }
    }
    _recalculateTotalFromTiers();
    notifyListeners();
  }

  void _recalculateTotalFromTiers() {
    final updated = totalEstimatedFootfall;
    _crowdData = _crowdData.copyWith(
      currentVisitors: updated,
      status: _statusFromCount(updated),
      estimatedWaitMinutes: _waitFromCount(updated),
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Gate Staff 1-Tap Quick Counter for unregistered families without smartphones
  void recordWalkinFamilyQuickCount(int count) {
    _tier2DeclaredCount += count;
    _adjustVisitors(count);
    notifyListeners();
  }

  /// Records a gate ticket scan with dual-source deduplication.
  /// If the devotee is already inside the geofence, avoids counting them twice.
  void recordTicketVerification(String ticketOrUserId, {int ticketCount = 1}) {
    final effectiveCount = ticketCount > 0 ? ticketCount : 1;
    if (_scannedTicketDevotees.contains(ticketOrUserId)) return;
    _scannedTicketDevotees.add(ticketOrUserId);
    _scannedPassGroupCounts[ticketOrUserId] = effectiveCount;

    if (_insideGeofenceDevotees.contains(ticketOrUserId)) {
      // Devotee was already counted when entering the GPS geofence.
      _overlapDeduplicatedCount += effectiveCount;
    } else {
      // Walk-in / non-geofenced devotee pass. Increment count once.
      _tier1BookingLinkedCount += effectiveCount;
      _adjustVisitors(effectiveCount);
    }
    notifyListeners();
  }

  /// Records geofence entry/exit with 3-tier contextual group reconciliation
  void recordGeofenceEvent(
    GeofenceEvent event, [
    String? userId,
    int devoteeCount = 1,
    int tier = 2,
  ]) {
    final uid = userId ?? 'devotee_session';
    final effectiveCount = devoteeCount > 0 ? devoteeCount : 1;

    if (event == GeofenceEvent.enter) {
      if (_insideGeofenceDevotees.contains(uid)) return;
      _insideGeofenceDevotees.add(uid);
      _geofenceGroupCounts[uid] = effectiveCount;

      if (_scannedTicketDevotees.contains(uid)) {
        // Devotee already scanned ticket at the gate. Reconcile overlap.
        _overlapDeduplicatedCount += effectiveCount;
      } else {
        if (tier == 1) {
          _tier1BookingLinkedCount += effectiveCount;
        } else {
          _tier2DeclaredCount += effectiveCount;
        }
        _adjustVisitors(effectiveCount);
      }
    } else {
      _insideGeofenceDevotees.remove(uid);
      _scannedTicketDevotees.remove(uid);
      final count = _geofenceGroupCounts.remove(uid) ?? effectiveCount;
      if (tier == 1) {
        _tier1BookingLinkedCount = (_tier1BookingLinkedCount - count).clamp(0, 99999);
      } else {
        _tier2DeclaredCount = (_tier2DeclaredCount - count).clamp(0, 99999);
      }
      _adjustVisitors(-count);
    }
    notifyListeners();
  }

  /// Records a manual or interactive family declaration from bottom sheet / notification
  void recordFamilyGroupDeclaration({required int count, bool isTier1 = false}) {
    final previousCount = _geofenceGroupCounts['devotee_session'] ?? 1;
    final delta = count - previousCount;
    _geofenceGroupCounts['devotee_session'] = count;

    if (isTier1) {
      _tier1BookingLinkedCount = (_tier1BookingLinkedCount + delta).clamp(0, 99999);
    } else {
      _tier2DeclaredCount = (_tier2DeclaredCount + delta).clamp(0, 99999);
    }
    _adjustVisitors(delta);
    notifyListeners();
  }

  // ── Geofence integration ───────────────────────────────────────────────────

  /// Call once from main.dart after repository creation
  Future<void> initGeofence() async {
    await GeofenceService.instance.init();

    // Listen to 3-tier contextual arrival
    GeofenceService.instance.onArrivalContextResolved = (context) {
      recordGeofenceEvent(
        context.event,
        'devotee_session',
        context.devoteeCount,
        context.tier,
      );
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
