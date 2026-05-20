# LensLife App — FL Sync Integration Change Log

**Date:** 2026-05-19  
**Task:** Implement server connection per `flutter_fl_sync_guideline.md`  
**Scope:** `App/` folder (Flutter)

---

## Summary

Added federated-learning (FL) background sync to a remote FastAPI server at `POST http://<VPS_IP>:8080/sync`. The app reads Welford baseline statistics from sqflite, POSTs aggregated stats (no raw ΔT, no PII), and writes returned `prior_mean` / `prior_std` back to the database.

Sync runs only when:
- Device is on **WiFi** (not cellular alone)
- **`session_count >= 14`**
- **`cluster_id`** is set (from onboarding)

Failures are logged silently; no UI feedback.

**Not modified (per guideline):** `lib/main.dart`, `lib/models/`, `lib/screens/`, BLE logic, Riverpod, charts.

---

## New Files

### `lib/services/fl_sync_service.dart`
- `FlSyncService.maybeSyncAsync()` — main entry point
- `_isOnWifi()` — uses `connectivity_plus` (wifi or ethernet)
- `_readStats()` — reads `cluster_id`, `mean`, `M2`, `count` from sqflite
- `_postSync()` — JSON POST via `http`, 10 second timeout
- `_writePriors()` — persists `prior_mean`, `prior_std`
- Errors logged with `dart:developer` `log()`, no user-facing errors

### `lib/services/session_database.dart`
- Opens `lenslife.db` (sqflite v2)
- `sessions` table (single stats row `id = 1`):
  - `baseline_mean`, `baseline_M2`, `session_count`, `cluster_id`, `prior_mean`, `prior_std`
- `onUpgrade` from v1→v2: `ALTER TABLE` adds `prior_mean`, `prior_std` if missing
- `recordSessionDeltaT(double deltaT)` — Welford online update
- `saveClusterId(String)` — onboarding persistence
- `readStatsRow()` / `writePriors()` — used by sync service

### `lib/services/session_service.dart`
- **`SessionService.recordSession(deltaT)`** — call after each BLE session write:
  1. Updates sqflite stats
  2. `await FlSyncService().maybeSyncAsync()`
- **`SessionService.completeOnboarding(...)`** — builds cluster hash and saves `cluster_id`

### `lib/services/fl_sync_config.dart`
- `FlSyncConfig.syncUrl` → `http://<host>:8080/sync`
- Host from `--dart-define=FL_SYNC_HOST=...` (default: `127.0.0.1`)

### `lib/utils/cluster_id.dart`
- `buildClusterId()` — hashes lens material, MPS brand, wear bin, AQI bin, city region (per guideline)

---

## Modified Files

### `pubspec.yaml`
**Added dependencies:**
| Package | Purpose |
|---------|---------|
| `sqflite: ^2.4.2` | Local stats persistence |
| `path: ^1.9.1` | Database file path |
| `http: ^1.4.0` | FL sync POST only |
| `connectivity_plus: ^6.1.4` | WiFi check before sync |

### `android/app/src/main/AndroidManifest.xml`
- `INTERNET` permission
- `ACCESS_NETWORK_STATE` permission
- `android:usesCleartextTraffic="true"` on `<application>` (HTTP VPS endpoint)

### `ios/Runner/Info.plist`
- `NSAppTransportSecurity`:
  - `NSAllowsLocalNetworking` = true
  - `NSAllowsArbitraryLoads` = true (HTTP to VPS IP)

### `macos/Runner/DebugProfile.entitlements`
- Added `com.apple.security.network.client` (outbound HTTP)

### `macos/Runner/Release.entitlements`
- Added `com.apple.security.network.client`

### `pubspec.lock`
- Resolved versions for new packages (auto-updated by `flutter pub get`)

---

## Generated / Tool-Updated (not hand-edited)

These changed when running `flutter pub get` after adding plugins:

- `macos/Flutter/GeneratedPluginRegistrant.swift` — registers `connectivity_plus`, `sqflite`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`
- `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig` (may include CocoaPods includes)
- `macos/Flutter/Flutter-Debug.xcconfig`, `macos/Flutter/Flutter-Release.xcconfig`

Untracked Podfiles (if present): `ios/Podfile`, `macos/Podfile` — from Flutter tooling, not part of FL sync spec.

---

## API Contract (Server)

**Request** `POST /sync`  
`Content-Type: application/json`

```json
{
  "cluster_id": "string",
  "mean": 0.08,
  "M2": 0.001,
  "count": 14
}
```

**Response**

```json
{
  "prior_mean": 0.08,
  "prior_std": 0.014
}
```

---

## Integration Points (for future BLE / onboarding code)

```dart
import 'package:lenslifeapp/services/session_service.dart';

// After each sensor session is saved:
await SessionService.recordSession(deltaT);

// Once at onboarding completion:
await SessionService.completeOnboarding(
  lensMaterial: 'silicone_hydrogel',
  mpsBrand: 'optifree',
  wearHoursPerDay: 10,
  aqiBin: 42,
  cityRegion: 'San Francisco',
);
```

**Set VPS host at build/run time:**

```bash
flutter run --dart-define=FL_SYNC_HOST=203.0.113.10
```

---

## Verification

- `flutter pub get` — succeeded
- `dart analyze lib/` — no errors in new service files (pre-existing infos in `main.dart` only)

---

## File Tree (new)

```
App/lib/
├── services/
│   ├── fl_sync_config.dart
│   ├── fl_sync_service.dart
│   ├── session_database.dart
│   └── session_service.dart
└── utils/
    └── cluster_id.dart
```

---

## Line Count (approximate)

| Area | Lines added |
|------|-------------|
| New Dart sources | ~330 |
| pubspec + platform config | ~20 |
| pubspec.lock (resolved deps) | ~169 |

**Total git diff (App-related):** ~530 insertions across 19 paths (including lockfile and generated registrants).
