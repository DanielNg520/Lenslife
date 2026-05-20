import 'dart:convert';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'fl_sync_config.dart';
import 'session_database.dart';

/// Background federated-learning sync after local session writes.
class FlSyncService {
  static const _syncTimeout = Duration(seconds: 10);

  /// Entry point — call after sqflite session write completes.
  Future<void> maybeSyncAsync() async {
    try {
      if (!await _isOnWifi()) {
        return;
      }

      final stats = await _readStats();
      final sessionCount = stats['session_count'] as int;
      if (sessionCount < 14) {
        return;
      }

      final clusterId = stats['cluster_id'] as String?;
      if (clusterId == null || clusterId.isEmpty) {
        return;
      }

      final priors = await _postSync(stats);
      if (priors == null) {
        return;
      }

      await _writePriors(priors['prior_mean']!, priors['prior_std']!);
    } catch (error, stackTrace) {
      developer.log(
        'FL sync failed',
        name: 'FlSyncService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _isOnWifi() async {
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  Future<Map<String, dynamic>> _readStats() async {
    final row = await SessionDatabase.readStatsRow();
    return {
      'cluster_id': row['cluster_id'] as String?,
      'mean': (row['baseline_mean'] as num?)?.toDouble() ?? 0.0,
      'M2': (row['baseline_M2'] as num?)?.toDouble() ?? 0.0,
      'count': (row['session_count'] as int?) ?? 0,
    };
  }

  Future<Map<String, double>?> _postSync(Map<String, dynamic> stats) async {
    final body = jsonEncode({
      'cluster_id': stats['cluster_id'],
      'mean': stats['mean'],
      'M2': stats['M2'],
      'count': stats['count'],
    });

    try {
      final response = await http
          .post(
            Uri.parse(FlSyncConfig.syncUrl),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_syncTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        developer.log(
          'FL sync HTTP ${response.statusCode}: ${response.body}',
          name: 'FlSyncService',
        );
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final priorMean = (decoded['prior_mean'] as num?)?.toDouble();
      final priorStd = (decoded['prior_std'] as num?)?.toDouble();
      if (priorMean == null || priorStd == null) {
        developer.log(
          'FL sync response missing prior fields: ${response.body}',
          name: 'FlSyncService',
        );
        return null;
      }

      return {
        'prior_mean': priorMean,
        'prior_std': priorStd,
      };
    } catch (error, stackTrace) {
      developer.log(
        'FL sync POST failed',
        name: 'FlSyncService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _writePriors(double priorMean, double priorStd) async {
    await SessionDatabase.writePriors(priorMean, priorStd);
  }
}
