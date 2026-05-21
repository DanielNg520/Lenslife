import 'dart:math' as math;

/// Phase 1 analytics in Flutter (ESP32 only runs Phase 0 hard thresholds).
abstract final class HealthAnalytics {
  static const double deltaTKill = 0.05;
  static const double phLow = 6.8;
  static const double phHigh = 7.4;

  static bool isAnomaly({
    required double deltaT,
    required double mean,
    required double m2,
    required int count,
  }) {
    if (deltaT > deltaTKill) return true;
    if (count >= 14) {
      return deltaT > mean + 2.0 * math.sqrt(m2 / (count - 1));
    }
    return false;
  }

  static bool isPhRisk(double phCorrected) =>
      phCorrected < phLow || phCorrected > phHigh;

  /// 0–100 score from fouling, pH, and personalized anomaly (post–cold-start).
  static int computeHealthScore({
    required double deltaTFouling,
    required double phCorrected,
    required bool killTriggered,
    required bool phRisk,
    required bool anomaly,
  }) {
    if (killTriggered || deltaTFouling > deltaTKill) {
      return 25;
    }
    if (phRisk || isPhRisk(phCorrected)) {
      return 40;
    }

    var score = 100.0 - (deltaTFouling / deltaTKill) * 35.0;
    if (anomaly) {
      score -= 25.0;
    }
    return score.clamp(0, 100).round();
  }
}
