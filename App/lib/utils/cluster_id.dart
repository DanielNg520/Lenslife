import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Builds a stable cluster hash from onboarding profile fields.
///
/// SHA-256 truncated to 16 hex chars (64-bit collision space).
/// MUST be deterministic across app restarts — Dart's String.hashCode is
/// salted per VM session and cannot be used here.
String buildClusterId({
  required String lensMaterial,
  required String mpsBrand,
  required int wearHoursPerDay,
  required int aqiBin,
  required String cityRegion,
}) {
  final wearBin = wearHoursPerDay < 8
      ? 'low'
      : wearHoursPerDay <= 12
          ? 'mid'
          : 'high';

  final aqiBinStr = aqiBin < 50
      ? 'good'
      : aqiBin <= 150
          ? 'moderate'
          : 'poor';

  final raw = '$lensMaterial|$mpsBrand|$wearBin|$aqiBinStr|$cityRegion';
  final bytes = utf8.encode(raw);
  final digest = sha256.convert(bytes);
  return digest.toString().substring(0, 16);
}
