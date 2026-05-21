import 'dart:typed_data';

/// 21-byte NOTIFY payload: four float32 + anomaly score + classify byte (little-endian).
class Esp32SensorPayload {
  final double deltaTFouling;
  final double deltaTResidual;
  final double phCorrected;
  final double tempCelsius;
  final double anomalyScore;
  final int classifyResult;

  const Esp32SensorPayload({
    required this.deltaTFouling,
    required this.deltaTResidual,
    required this.phCorrected,
    required this.tempCelsius,
    required this.anomalyScore,
    required this.classifyResult,
  });

  static const int byteLength = 21;

  static Esp32SensorPayload? tryParse(List<int> bytes) {
    if (bytes.length < byteLength) {
      return null;
    }
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return Esp32SensorPayload(
      deltaTFouling: bd.getFloat32(0, Endian.little),
      deltaTResidual: bd.getFloat32(4, Endian.little),
      phCorrected: bd.getFloat32(8, Endian.little),
      tempCelsius: bd.getFloat32(12, Endian.little),
      anomalyScore: bd.getFloat32(16, Endian.little),
      classifyResult: bd.getUint8(20),
    );
  }

  String get summary =>
      'ΔT fouling: ${deltaTFouling.toStringAsFixed(4)}, '
      'ΔT residual: ${deltaTResidual.toStringAsFixed(4)}, '
      'pH: ${phCorrected.toStringAsFixed(2)}, '
      'temp: ${tempCelsius.toStringAsFixed(1)}°C, '
      'anomaly z: ${anomalyScore.toStringAsFixed(2)}, '
      'class: $classifyResult';
}
