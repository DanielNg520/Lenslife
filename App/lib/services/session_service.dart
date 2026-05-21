import 'dart:async';

import '../utils/cluster_id.dart';
import 'fl_sync_service.dart';
import 'session_database.dart';

/// Call after each BLE session is persisted (stats write + background FL sync).
class SessionService {
  SessionService._();

  static Future<void> recordSession(double deltaT) async {
    await SessionDatabase.recordSessionDeltaT(deltaT);
    // Fire-and-forget: errors are caught inside maybeSyncAsync().
    unawaited(FlSyncService().maybeSyncAsync());
  }

  /// Ensures FL sync has a cluster_id (uses neutral defaults until onboarding).
  static Future<void> ensureClusterIdForSync() async {
    final row = await SessionDatabase.readStatsRow();
    final existing = row['cluster_id'] as String?;
    if (existing != null && existing.isNotEmpty) {
      return;
    }
    await completeOnboarding(
      lensMaterial: 'unknown',
      mpsBrand: 'unknown',
      wearHoursPerDay: 8,
      aqiBin: 50,
      cityRegion: 'unknown',
    );
  }

  static Future<void> completeOnboarding({
    required String lensMaterial,
    required String mpsBrand,
    required int wearHoursPerDay,
    required int aqiBin,
    required String cityRegion,
  }) async {
    final clusterId = buildClusterId(
      lensMaterial: lensMaterial,
      mpsBrand: mpsBrand,
      wearHoursPerDay: wearHoursPerDay,
      aqiBin: aqiBin,
      cityRegion: cityRegion,
    );
    await SessionDatabase.saveClusterId(clusterId);
  }
}
