import '../ml/health_score.dart';
import '../ml/welford_repository.dart';
import '../models/esp32_device_status.dart';
import '../models/esp32_sensor_payload.dart';
import 'session_service.dart';

/// Result after persisting a BLE session and running local analytics.
class SensorSessionResult {
  final Esp32SensorPayload payload;
  final double healthScore;
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
/// [computeHealthScore] and [isAnomaly] are only invoked from this BLE path.
class SensorSessionHandler {
  SensorSessionHandler._();

  static const int _defaultWearDays = 0;
  static const int _defaultAqi = 0;

  static Future<SensorSessionResult?> processPayload(
    Esp32SensorPayload payload, {
    Esp32DeviceStatus? deviceStatus,
    int wearDays = _defaultWearDays,
    int aqi = _defaultAqi,
  }) async {
    await SessionService.ensureClusterIdForSync();

    final repo = await WelfordRepository.open();
    final wDT = await repo.load('delta_T');
    final wPH = await repo.load('pH');
    final wTmp = await repo.load('temp_c');

    final killTriggered = deviceStatus?.killConditionTriggered ??
        payload.deltaTFouling > killThreshold;
    final phRisk =
        deviceStatus?.phRisk ?? isPhRisk(payload.phCorrected);

    final anomaly = isAnomaly(
      deltaT: payload.deltaTFouling,
      pH: payload.phCorrected,
      wDT: wDT,
      wPH: wPH,
    );

    final score = computeHealthScore(
      deltaT: payload.deltaTFouling,
      pH: payload.phCorrected,
      tempC: payload.tempCelsius,
      wearDays: wearDays,
      aqi: aqi,
      wDT: wDT,
      wPH: wPH,
    );

    final wDTNew = wDT.update(payload.deltaTFouling);
    final wPHNew = wPH.update(payload.phCorrected);
    final wTmpNew = wTmp.update(payload.tempCelsius);

    await repo.save('delta_T', wDTNew);
    await repo.save('pH', wPHNew);
    await repo.save('temp_c', wTmpNew);

    await SessionService.recordSession(payload.deltaTFouling);

    return SensorSessionResult(
      payload: payload,
      healthScore: score,
      isAnomaly: anomaly,
      killTriggered: killTriggered,
      phRisk: phRisk,
    );
  }
}
