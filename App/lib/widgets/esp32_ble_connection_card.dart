import 'dart:async';

import 'package:flutter/material.dart';

import '../ble/esp32_ble_service.dart';
import '../models/esp32_device_status.dart';
import '../models/esp32_sensor_payload.dart';
import '../services/sensor_session_handler.dart';
import '../services/live_sensor_store.dart';

/// Dashboard card: ESP32 BLE connect + NOTIFY → local analytics + FL server sync.
class Esp32BleConnectionCard extends StatefulWidget {
  const Esp32BleConnectionCard({super.key});

  @override
  State<Esp32BleConnectionCard> createState() => _Esp32BleConnectionCardState();
}

class _Esp32BleConnectionCardState extends State<Esp32BleConnectionCard> {
  final _ble = Esp32BleService();

  bool scanning = false;
  bool connecting = false;
  bool hasRequestedRead = false;
  String status = 'Not connected';
  String latestReading = 'Waiting for device';
  String deviceStatusText = '';
  String healthSummary = '';
  int? lastHealthScore;

  @override
  void initState() {
    super.initState();
    _ble.onSensorPayload = _handleSensorPayload;
  }

  Future<void> _handleSensorPayload(
    Esp32SensorPayload payload,
    Esp32DeviceStatus? deviceStatus,
  ) async {
    // The BLE service may read an initial cached/default value right after connecting.
    // Do not show Health 40% or update the dashboard until the user taps Read now.
    if (!hasRequestedRead) {
      if (!mounted) return;
      setState(() {
        latestReading = 'Connected. Tap Read now to take a reading.';
        healthSummary = '';
        lastHealthScore = null;
      });
      lensLiveReadingNotifier.value = null;
      return;
    }

    Esp32DeviceStatus? statusByte = deviceStatus;

    try {
      statusByte ??= await _ble.readDeviceStatus();
    } catch (e) {
      debugPrint('Device status read failed: $e');
    }

    SensorSessionResult? result;

    try {
      result = await SensorSessionHandler.processPayload(
        payload,
        deviceStatus: statusByte,
      );
    } catch (e) {
      debugPrint('Sensor session processing failed: $e');
    }

    lensLiveReadingNotifier.value = LiveSensorReading.fromBle(
      payload: payload,
      deviceStatus: statusByte,
      result: result,
    );

    if (!mounted) return;

    setState(() {
      latestReading = payload.summary;
      deviceStatusText = statusByte?.summary ?? '';

      if (result != null) {
        lastHealthScore = result.healthScore;
        healthSummary =
            'Health ${result.healthScore}%'
            '${result.isAnomaly ? ' · anomaly' : ''}'
            '${result.killTriggered ? ' · replace soon' : ''}'
            '${result.phRisk ? ' · pH risk' : ''}';
      } else {
        lastHealthScore = null;
        healthSummary = 'Live reading received';
      }
    });
  }

  Future<void> _scanAndConnect() async {
    setState(() {
      scanning = true;
      connecting = true;
      hasRequestedRead = false;
      status = 'Scanning...';
      latestReading = 'Waiting for device';
      deviceStatusText = '';
      healthSummary = '';
      lastHealthScore = null;
    });
    lensLiveReadingNotifier.value = null;

    try {
      await _ble.scanAndConnect(
        onStatus: (msg) {
          if (mounted) setState(() => status = msg);
        },
      );
    } catch (_) {
      // Status already set by service.
    } finally {
      if (mounted) {
        setState(() {
          scanning = false;
          connecting = false;
          if (_ble.isConnected) {
            latestReading = 'Connected. Tap Read now to take a reading.';
          } else {
            status = status.contains('Connected') ? status : 'Not connected';
          }
        });
      }
    }
  }

  Future<void> _disconnect() async {
    await _ble.disconnect();
    if (!mounted) return;
    setState(() {
      hasRequestedRead = false;
      status = 'Disconnected';
      latestReading = 'Waiting for device';
      deviceStatusText = '';
      healthSummary = '';
      lastHealthScore = null;
    });
    lensLiveReadingNotifier.value = null;
  }

  Future<void> _sendCommand(Esp32Command command, String label) async {
    final isReadCommand = command == Esp32Command.requestSensorRead;

    try {
      if (isReadCommand && mounted) {
        setState(() {
          hasRequestedRead = true;
          latestReading = 'Reading sensor data...';
          healthSummary = '';
          lastHealthScore = null;
        });
      }

      await _ble.sendCommand(command);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label sent to case')),
        );
      }
    } catch (e) {
      if (isReadCommand && mounted) {
        setState(() {
          hasRequestedRead = false;
          latestReading = 'Connected. Tap Read now to take a reading.';
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Command failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _ble.isConnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DED3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEVICE CONNECTION',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: connected ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            latestReading,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF444444),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (deviceStatusText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Status: $deviceStatusText',
              style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
            ),
          ],
          if (healthSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              healthSummary,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: lastHealthScore != null && lastHealthScore! < 50
                    ? const Color(0xFF875000)
                    : const Color(0xFF151515),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (connected) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _sendCommand(
                    Esp32Command.acquireBlank,
                    'T_blank acquisition',
                  ),
                  child: const Text('Calibrate blank'),
                ),
                OutlinedButton(
                  onPressed: () => _sendCommand(
                    Esp32Command.requestSensorRead,
                    'Sensor read',
                  ),
                  child: const Text('Read now'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: scanning || connecting
                  ? null
                  : connected
                      ? _disconnect
                      : _scanAndConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF151515),
                foregroundColor: Colors.white,
              ),
              icon: Icon(
                connected ? Icons.link_off : Icons.bluetooth_searching,
              ),
              label: Text(
                scanning
                    ? 'Scanning...'
                    : connecting && !connected
                        ? 'Connecting...'
                        : connected
                            ? 'Disconnect'
                            : 'Scan & Connect',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
