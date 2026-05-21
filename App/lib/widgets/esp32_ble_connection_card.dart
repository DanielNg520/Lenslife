import 'dart:async';

import 'package:flutter/material.dart';

import '../ble/esp32_ble_service.dart';
import '../models/esp32_device_status.dart';
import '../models/esp32_sensor_payload.dart';
import '../services/sensor_session_handler.dart';

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
    final statusByte =
        deviceStatus ?? await _ble.readDeviceStatus();

    final result = await SensorSessionHandler.processPayload(
      payload,
      deviceStatus: statusByte,
    );

    if (!mounted) return;

    setState(() {
      latestReading = payload.summary;
      deviceStatusText = statusByte?.summary ?? '';
      if (result != null) {
        lastHealthScore = result.healthScore.round();
        healthSummary =
            'Health ${result.healthScore.round()}%'
            '${result.isAnomaly ? ' · anomaly' : ''}'
            '${result.killTriggered ? ' · replace soon' : ''}'
            '${result.phRisk ? ' · pH risk' : ''}';
      }
    });
  }

  Future<void> _scanAndConnect() async {
    setState(() {
      scanning = true;
      connecting = true;
      status = 'Scanning...';
    });

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
          if (!_ble.isConnected) {
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
      status = 'Disconnected';
      latestReading = 'Waiting for device';
      deviceStatusText = '';
      healthSummary = '';
      lastHealthScore = null;
    });
  }

  Future<void> _sendCommand(Esp32Command command, String label) async {
    try {
      await _ble.sendCommand(command);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label sent to case')),
        );
      }
    } catch (e) {
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
