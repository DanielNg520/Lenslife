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

    final score = result?.healthScore ??
        HealthAnalytics.computeHealthScore(
          deltaTFouling: payload.deltaTFouling,
          phCorrected: payload.phCorrected,
          killTriggered: kill,
          phRisk: phBad,
          anomaly: result?.isAnomaly ?? false,
        );

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

  double get foulingRatio =>
    (payload.deltaTFouling / HealthAnalytics.deltaTKill).clamp(0.0, 1.0).toDouble();

  double get cleanlinessPercent =>
    (1.0 - foulingRatio).clamp(0.0, 1.0).toDouble();

  String get cleanlinessText => '${(cleanlinessPercent * 100).round()}%';

  String get depositLevel {
    if (killTriggered || payload.deltaTFouling >= HealthAnalytics.deltaTKill) {
      return 'High';
    }
    if (payload.deltaTFouling >= HealthAnalytics.deltaTKill * 0.50) {
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
    if (killTriggered || phRisk || isAnomaly) return 'Caution';
    return 'Good';
  }

  String get eyeSafetySubText {
    if (phRisk) return 'pH risk';
    if (killTriggered) return 'Dirty reading';
    if (isAnomaly) return 'Unusual trend';
    return 'No risk';
  }

  double get eyeSafetyPercent =>
    (healthScore / 100.0).clamp(0.0, 1.0).toDouble();

  String get phText => payload.phCorrected.toStringAsFixed(2);

  String get detailText =>
      'ΔT ${payload.deltaTFouling.toStringAsFixed(4)} • residual ${payload.deltaTResidual.toStringAsFixed(4)}';
}

final ValueNotifier<LiveSensorReading?> lensLiveReadingNotifier =
    ValueNotifier<LiveSensorReading?>(null);