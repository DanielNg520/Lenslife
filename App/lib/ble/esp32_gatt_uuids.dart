import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// GATT layout from ESP32_BLE_Implementation.md (service 0xAB00).
abstract final class Esp32GattUuids {
  static final Guid service = Guid('0000ab00-0000-1000-8000-00805f9b34fb');
  static final Guid sensorData = Guid('0000ab01-0000-1000-8000-00805f9b34fb');
  static final Guid deviceStatus = Guid('0000ab02-0000-1000-8000-00805f9b34fb');
  static final Guid command = Guid('0000ab03-0000-1000-8000-00805f9b34fb');
}
