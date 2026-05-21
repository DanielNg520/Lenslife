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
  final bool phValid;
  final bool irValid;
  final bool tempValid;

  const SensorSessionResult({
    required this.payload,
    required this.healthScore,
    required this.isAnomaly,
    required this.killTriggered,
    required this.phRisk,
    required this.phValid,
    required this.irValid,
    required this.tempValid,
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

    final phValid = deviceStatus?.phSensorValid ?? false;
    final irValid = deviceStatus?.irSensorValid ?? true;
    final tempValid = deviceStatus?.tempReadValid ?? false;

    final repo = await WelfordRepository.open();
    final wDT = await repo.load('delta_T');
    final wPH = await repo.load('pH');
    final wTmp = await repo.load('temp_c');

    final killTriggered = deviceStatus?.killConditionTriggered ??
        payload.deltaTFouling > killThreshold;
    final phRisk = deviceStatus?.phRisk ??
        isPhRisk(payload.phCorrected, phValid: phValid);

    final anomaly = isAnomaly(
      deltaT: payload.deltaTFouling,
      pH: payload.phCorrected,
      wDT: wDT,
      wPH: wPH,
      phValid: phValid,
    );

    final score = computeHealthScore(
      deltaT: payload.deltaTFouling,
      pH: payload.phCorrected,
      tempC: payload.tempCelsius,
      wearDays: wearDays,
      aqi: aqi,
      wDT: wDT,
      wPH: wPH,
      phValid: phValid,
    );

    final wDTNew = wDT.update(payload.deltaTFouling);
    await repo.save('delta_T', wDTNew);

    if (phValid) {
      await repo.save('pH', wPH.update(payload.phCorrected));
    }
    if (tempValid) {
      await repo.save('temp_c', wTmp.update(payload.tempCelsius));
    }

    if (irValid) {
      await SessionService.recordSession(payload.deltaTFouling);
    }

    return SensorSessionResult(
      payload: payload,
      healthScore: score,
      isAnomaly: anomaly,
      killTriggered: killTriggered,
      phRisk: phRisk,
      phValid: phValid,
      irValid: irValid,
      tempValid: tempValid,
    );
  }
}
