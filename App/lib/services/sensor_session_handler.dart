import '../models/esp32_device_status.dart';
import '../models/esp32_sensor_payload.dart';
import 'health_analytics.dart';
import 'session_database.dart';
import 'session_service.dart';

/// Result after persisting a BLE session and running local analytics.
class SensorSessionResult {
  final Esp32SensorPayload payload;
  final int healthScore;
  final bool isAnomaly;
  final bool killTriggered;
  final bool phRisk;

  const SensorSessionResult({
    required this.payload,
    required this.healthScore,
    required this.isAnomaly,
    required this.killTriggered,
    required this.phRisk,
  });
}

/// Parses ESP32 NOTIFY data, updates Welford stats, triggers FL server sync.
class SensorSessionHandler {
  SensorSessionHandler._();

  static Future<SensorSessionResult?> processPayload(
    Esp32SensorPayload payload, {
    Esp32DeviceStatus? deviceStatus,
  }) async {
    await SessionService.ensureClusterIdForSync();

    await SessionService.recordSession(payload.deltaTFouling);

    final row = await SessionDatabase.readStatsRow();
    final mean = (row['baseline_mean'] as num?)?.toDouble() ?? 0.0;
    final m2 = (row['baseline_M2'] as num?)?.toDouble() ?? 0.0;
    final count = (row['session_count'] as int?) ?? 0;
    final priorMean = (row['prior_mean'] as num?)?.toDouble();

    final effectiveMean =
        count < 14 && priorMean != null ? priorMean : mean;

    final killTriggered = deviceStatus?.killConditionTriggered ??
        payload.deltaTFouling > HealthAnalytics.deltaTKill;
    final phRisk = deviceStatus?.phRisk ??
        HealthAnalytics.isPhRisk(payload.phCorrected);

    final anomaly = HealthAnalytics.isAnomaly(
      deltaT: payload.deltaTFouling,
      mean: effectiveMean,
      m2: m2,
      count: count,
    );

    final healthScore = HealthAnalytics.computeHealthScore(
      deltaTFouling: payload.deltaTFouling,
      phCorrected: payload.phCorrected,
      killTriggered: killTriggered,
      phRisk: phRisk,
      anomaly: anomaly,
    );

    return SensorSessionResult(
      payload: payload,
      healthScore: healthScore,
      isAnomaly: anomaly,
      killTriggered: killTriggered,
      phRisk: phRisk,
    );
  }
}
