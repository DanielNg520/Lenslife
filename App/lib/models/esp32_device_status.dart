/// DEVICE_STATUS bitmask (1 byte) from ESP32_BLE_Implementation.md.
class Esp32DeviceStatus {
  final bool killConditionTriggered;
  final bool phRisk;
  final bool tempReadValid;
  final bool blankIsStale;

  const Esp32DeviceStatus({
    required this.killConditionTriggered,
    required this.phRisk,
    required this.tempReadValid,
    required this.blankIsStale,
  });

  static Esp32DeviceStatus? tryParse(List<int> bytes) {
    if (bytes.isEmpty) {
      return null;
    }
    final status = bytes.first;
    return Esp32DeviceStatus(
      killConditionTriggered: (status & 0x01) != 0,
      phRisk: (status & 0x02) != 0,
      tempReadValid: (status & 0x04) != 0,
      blankIsStale: (status & 0x08) != 0,
    );
  }

  String get summary {
    final parts = <String>[];
    if (killConditionTriggered) parts.add('kill triggered');
    if (phRisk) parts.add('pH risk');
    if (tempReadValid) parts.add('temp OK');
    if (blankIsStale) parts.add('blank stale (>7d)');
    if (parts.isEmpty) return 'All clear';
    return parts.join(', ');
  }
}

/// COMMAND byte values (Flutter → ESP32 WRITE on 0xAB03).
enum Esp32Command {
  acquireBlank(0x01),
  triggerVibration(0x02),
  requestSensorRead(0x03);

  final int code;
  const Esp32Command(this.code);
}
