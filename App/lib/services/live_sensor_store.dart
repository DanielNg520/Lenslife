import 'package:flutter/foundation.dart';

import '../models/esp32_device_status.dart';
import '../models/esp32_sensor_payload.dart';
import 'health_analytics.dart';
import 'sensor_session_handler.dart';

class LiveSensorReading {
  final Esp32SensorPayload payload;
  final Esp32DeviceStatus? deviceStatus;
  final int healthScore;
  final bool isAnomaly;
  final bool killTriggered;
  final bool phRisk;
  final DateTime receivedAt;

  const LiveSensorReading({
    required this.payload,
    required this.deviceStatus,
    required this.healthScore,
    required this.isAnomaly,
    required this.killTriggered,
    required this.phRisk,
    required this.receivedAt,
  });

  static const double demoLowThreshold = 0.35;
  static const double demoHighThreshold = 0.80;

  static double _demoFoulingRatio(double deltaTFouling) {
    final value = deltaTFouling.abs();

    if (value <= demoLowThreshold) return 0.10;
    if (value >= demoHighThreshold) return 1.0;

    return ((value - demoLowThreshold) /
            (demoHighThreshold - demoLowThreshold))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  factory LiveSensorReading.fromBle({
    required Esp32SensorPayload payload,
    required Esp32DeviceStatus? deviceStatus,
    required SensorSessionResult? result,
  }) {
    final kill = result?.killTriggered ??
        deviceStatus?.killConditionTriggered ??
        payload.deltaTFouling > HealthAnalytics.deltaTKill;

    final phBad = result?.phRisk ??
        deviceStatus?.phRisk ??
        HealthAnalytics.isPhRisk(payload.phCorrected);

    final demoRatio = _demoFoulingRatio(payload.deltaTFouling);

    final score = phBad || kill
        ? 25
        : ((1.0 - demoRatio) * 100).round().clamp(0, 100);

    return LiveSensorReading(
      payload: payload,
      deviceStatus: deviceStatus,
      healthScore: score,
      isAnomaly: result?.isAnomaly ?? false,
      killTriggered: kill,
      phRisk: phBad,
      receivedAt: DateTime.now(),
    );
  }

  double get foulingRatio => _demoFoulingRatio(payload.deltaTFouling);

  double get cleanlinessPercent =>
      (1.0 - foulingRatio).clamp(0.0, 1.0).toDouble();

  String get cleanlinessText => '${(cleanlinessPercent * 100).round()}%';

  String get depositLevel {
    final value = payload.deltaTFouling.abs();

    if (killTriggered || value >= demoHighThreshold) {
      return 'High';
    }
    if (value >= demoLowThreshold) {
      return 'Moderate';
    }
    return 'Low';
  }

  String get statusChipLabel {
    if (killTriggered) return 'Replace solution';
    if (depositLevel == 'Moderate' || isAnomaly) return 'Monitor closely';
    return 'Good';
  }

  String get wearStatusTitle {
    if (killTriggered) return 'Dirty solution detected';
    if (depositLevel == 'Moderate') return 'Moderate buildup';
    return 'Solution looks clean';
  }

  String get wearStatusMessage {
    if (killTriggered) {
      return 'The IR reading crossed the dirty threshold. Replace or clean before wearing the lenses.';
    }
    if (depositLevel == 'Moderate') {
      return 'The sample is different from the clean baseline. Monitor closely and consider cleaning tonight.';
    }
    return 'The current IR reading is close to the clean baseline. No major buildup detected.';
  }

  String get eyeSafetyText {
    if (healthScore >= 75) return 'Good';
    if (healthScore >= 40) return 'Caution';
    return 'High';
  }

  String get eyeSafetySubText {
    if (phRisk) return 'pH risk';
    if (killTriggered) return 'Dirty reading';
    if (isAnomaly) return 'Unusual trend';
    if (healthScore >= 75) return 'No risk';
    if (healthScore >= 40) return 'Medium risk';
    return 'High risk';
  }

  double get eyeSafetyPercent =>
      (healthScore / 100.0).clamp(0.0, 1.0).toDouble();

  String get phText => payload.phCorrected.toStringAsFixed(2);

  String get detailText =>
      'ΔT ${payload.deltaTFouling.toStringAsFixed(4)} • pH ${payload.phCorrected.toStringAsFixed(2)}';
}

final ValueNotifier<LiveSensorReading?> lensLiveReadingNotifier =
    ValueNotifier<LiveSensorReading?>(null);