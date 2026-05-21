import '../utils/cluster_id.dart';
import 'fl_sync_service.dart';
import 'session_database.dart';

/// Call after each BLE session is persisted (stats write + background FL sync).
class SessionService {
  SessionService._();

  static Future<void> recordSession(double deltaT) async {
    await SessionDatabase.recordSessionDeltaT(deltaT);
    await FlSyncService().maybeSyncAsync();
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
