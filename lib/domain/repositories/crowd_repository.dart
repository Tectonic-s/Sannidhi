import '../../data/models/crowd_telemetry_model.dart';

abstract class CrowdRepository {
  CrowdTelemetryModel getCrowdData();
  void updateCrowdData(CrowdTelemetryModel data);
  Future<void> refreshCrowdData();
}
