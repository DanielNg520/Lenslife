import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/esp32_device_status.dart';
import '../models/esp32_sensor_payload.dart';
import 'esp32_gatt_uuids.dart';

typedef SensorPayloadCallback = void Function(
  Esp32SensorPayload payload,
  Esp32DeviceStatus? deviceStatus,
);

/// BLE central client for the ESP32 NimBLE GATT server (0xAB00–0xAB03).
class Esp32BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _sensorDataChar;
  BluetoothCharacteristic? _deviceStatusChar;
  BluetoothCharacteristic? _commandChar;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  SensorPayloadCallback? onSensorPayload;

  bool get isConnected => _device != null && _sensorDataChar != null;

  Future<void> scanAndConnect({
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('Scanning for LensLife case...');

    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();

      final completer = Completer<void>();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (final result in results) {
          final name = result.device.platformName.toUpperCase();
          final hasService = result.advertisementData.serviceUuids
              .contains(Esp32GattUuids.service);

          if (hasService ||
              name.contains('LENSLIFE') ||
              name.contains('XIAO') ||
              name.contains('ESP32')) {
            await FlutterBluePlus.stopScan();
            await _scanSubscription?.cancel();
            _scanSubscription = null;
            onStatus?.call('Connecting to ${result.device.platformName}...');
            await _connect(result.device, onStatus: onStatus);
            if (!completer.isCompleted) {
              completer.complete();
            }
            return;
          }
        }
      });

      await FlutterBluePlus.startScan(
        withServices: [Esp32GattUuids.service],
        timeout: const Duration(seconds: 8),
      );

      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 8)),
      ]);

      if (!isConnected) {
        await FlutterBluePlus.stopScan();
        await _scanSubscription?.cancel();
        _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
          for (final result in results) {
            final name = result.device.platformName.toUpperCase();
            if (name.contains('LENSLIFE') ||
                name.contains('XIAO') ||
                name.contains('ESP32')) {
              await FlutterBluePlus.stopScan();
              await _scanSubscription?.cancel();
              _scanSubscription = null;
              onStatus?.call('Connecting to ${result.device.platformName}...');
              await _connect(result.device, onStatus: onStatus);
              if (!completer.isCompleted) completer.complete();
              return;
            }
          }
        });
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
        await Future.any([
          completer.future,
          Future.delayed(const Duration(seconds: 6)),
        ]);
      }

      if (!isConnected) {
        onStatus?.call('No LensLife device found');
      }
    } catch (error, stackTrace) {
      developer.log(
        'BLE scan failed',
        name: 'Esp32BleService',
        error: error,
        stackTrace: stackTrace,
      );
      onStatus?.call('Scan failed: $error');
      rethrow;
    }
  }

  Future<void> _connect(
    BluetoothDevice device, {
    void Function(String status)? onStatus,
  }) async {
    await disconnect();

    await device.connect(
      timeout: const Duration(seconds: 12),
      license: License.free,
    );

    final services = await device.discoverServices();
    BluetoothCharacteristic? sensor;
    BluetoothCharacteristic? status;
    BluetoothCharacteristic? command;

    for (final service in services) {
      if (service.uuid != Esp32GattUuids.service) {
        continue;
      }
      for (final c in service.characteristics) {
        if (c.uuid == Esp32GattUuids.sensorData) {
          sensor = c;
        } else if (c.uuid == Esp32GattUuids.deviceStatus) {
          status = c;
        } else if (c.uuid == Esp32GattUuids.command) {
          command = c;
        }
      }
    }

    if (sensor == null) {
      await device.disconnect();
      onStatus?.call('ESP32 service 0xAB00 not found');
      throw StateError('SENSOR_DATA characteristic 0xAB01 missing');
    }

    _device = device;
    _sensorDataChar = sensor;
    _deviceStatusChar = status;
    _commandChar = command;

    if (sensor.properties.notify) {
      await sensor.setNotifyValue(true);
      await _notifySubscription?.cancel();
      _notifySubscription = sensor.lastValueStream.listen(_onNotify);
    }

    final deviceStatus = await readDeviceStatus();
    onStatus?.call('Connected to ${device.platformName}');

    if (sensor.properties.read) {
      final initial = await sensor.read();
      _onNotify(initial, deviceStatus: deviceStatus);
    }
  }

  Future<void> _onNotify(List<int> value, {Esp32DeviceStatus? deviceStatus}) async {
    final payload = Esp32SensorPayload.tryParse(value);
    if (payload == null) {
      developer.log(
        'Ignoring NOTIFY: expected ${Esp32SensorPayload.byteLength} bytes, got ${value.length}',
        name: 'Esp32BleService',
      );
      return;
    }
    final status = deviceStatus ?? await readDeviceStatus();
    onSensorPayload?.call(payload, status);
  }

  Future<Esp32DeviceStatus?> readDeviceStatus() async {
    final characteristic = _deviceStatusChar;
    if (characteristic == null || !characteristic.properties.read) {
      return null;
    }
    try {
      final bytes = await characteristic.read();
      return Esp32DeviceStatus.tryParse(bytes);
    } catch (error, stackTrace) {
      developer.log(
        'DEVICE_STATUS read failed',
        name: 'Esp32BleService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> sendCommand(Esp32Command command) async {
    final characteristic = _commandChar;
    if (characteristic == null) {
      throw StateError('Not connected — COMMAND characteristic unavailable');
    }
    if (!characteristic.properties.write &&
        !characteristic.properties.writeWithoutResponse) {
      throw StateError('COMMAND characteristic is not writable');
    }
    await characteristic.write(
      [command.code],
      withoutResponse: characteristic.properties.writeWithoutResponse,
    );
  }

  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    try {
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _sensorDataChar = null;
    _deviceStatusChar = null;
    _commandChar = null;
  }

  void dispose() {
    unawaited(disconnect());
  }
}
