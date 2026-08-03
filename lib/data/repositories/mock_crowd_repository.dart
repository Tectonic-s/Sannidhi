import 'package:flutter/material.dart';
import '../../domain/repositories/crowd_repository.dart';
import '../models/crowd_telemetry_model.dart';

class MockCrowdRepository with ChangeNotifier implements CrowdRepository {
  CrowdTelemetryModel _crowdData = CrowdTelemetryModel(
    status: 'Moderate',
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
    _crowdData = CrowdTelemetryModel(
      status: 'Moderate',
      estimatedWaitMinutes: 25,
      timestamp: DateTime.now().toIso8601String(),
      currentVisitors: 1250,
    );
    notifyListeners();
  }
}
