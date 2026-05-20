/// Federated-learning sync endpoint configuration.
///
/// Override the host at build time:
/// `flutter run --dart-define=FL_SYNC_HOST=203.0.113.10`
class FlSyncConfig {
  FlSyncConfig._();

  static const String vpsHost = String.fromEnvironment(
    'FL_SYNC_HOST',
    defaultValue: '127.0.0.1',
  );

  static const int port = 8080;

  static String get syncUrl => 'http://$vpsHost:$port/sync';
}
