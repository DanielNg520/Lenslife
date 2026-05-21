import 'dart:math';

import 'welford_state.dart';

const double killThreshold = 0.05;
const double anomalyThreshold = 2.5;

double computeHealthScore({
  required double deltaT,
  required double pH,
  required double tempC,
  required int wearDays,
  required int aqi,
  required WelfordState wDT,
  required WelfordState wPH,
  bool phValid = true,
}) {
  double score = 100.0;

  score -= (deltaT / killThreshold).clamp(0.0, 1.0) * 40.0;

  if (phValid) {
    double pHDist = 0.0;
    if (pH < 6.8) {
      pHDist = 6.8 - pH;
    }
    if (pH > 7.4) {
      pHDist = pH - 7.4;
    }
    score -= pHDist * 30.0;
  }

  score -= (wearDays / 30.0).clamp(0.0, 1.0) * 15.0;

  if (aqi > 200) {
    score -= 20.0;
  } else if (aqi > 150) {
    score -= 10.0;
  }

  return score.clamp(0.0, 100.0);
}

bool isAnomaly({
  required double deltaT,
  required double pH,
  required WelfordState wDT,
  required WelfordState wPH,
  bool phValid = true,
}) {
  if (deltaT > killThreshold) {
    return true;
  }

  if (wDT.count < 14) {
    return false;
  }

  final zDT = wDT.zScore(deltaT);
  if (phValid && wPH.count >= 14) {
    final zPH = wPH.zScore(pH);
    return sqrt(zDT * zDT + zPH * zPH) > anomalyThreshold;
  }

  return zDT.abs() > anomalyThreshold;
}

bool isPhRisk(double phCorrected, {bool phValid = true}) {
  if (!phValid) {
    return false;
  }
  return phCorrected < 6.8 || phCorrected > 7.4;
}
