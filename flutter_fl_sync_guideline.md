# LensLife Flutter — FL Sync Integration Guideline
## For Cursor Agent

---

## Context

This is the LensLife Flutter app. It connects to an ESP32-S3 via BLE, receives raw sensor readings, computes a contamination health score locally, and periodically syncs compressed statistics to a remote FastAPI server that performs federated averaging across users.

**Do not change any existing BLE, sqflite, or riverpod logic unless explicitly told to.**
**Do not install any packages not listed here.**

---

## What needs to be built

A single `fl_sync_service.dart` that:
1. Reads `baseline_mean`, `baseline_M2`, `session_count` from sqflite
2. Reads `cluster_id` from sqflite (computed at onboarding, stored once)
3. POSTs these 4 values to the FL server
4. Receives `prior_mean` and `prior_std` back
5. Writes the updated priors into sqflite
6. Only syncs when WiFi is available and session_count >= 14

---

## Server details

- **URL:** `http://<VPS_IP>:8080/sync`
- **Method:** POST
- **Content-Type:** application/json
- **Request body:**
```json
{
  "cluster_id": "string",
  "mean": 0.08,
  "M2": 0.001,
  "count": 14
}
```
- **Response body:**
```json
{
  "prior_mean": 0.08,
  "prior_std": 0.014
}
```

---

## Packages to use

Already in pubspec.yaml — do not add new ones:
- `sqflite` — local persistence
- `riverpod` — state management
- `flutter_blue_plus` — BLE (do not touch)
- `fl_chart` — charts (do not touch)

Add only these if not already present:
- `http` — for the POST call
- `connectivity_plus` — to check WiFi before syncing

---

## sqflite schema assumptions

The existing sessions table has at minimum these columns. Do not alter the schema, only read/write these columns:

| Column | Type | Description |
|---|---|---|
| `baseline_mean` | REAL | Welford running mean of ΔT |
| `baseline_M2` | REAL | Welford M2 accumulator |
| `session_count` | INTEGER | Total sessions recorded |
| `cluster_id` | TEXT | Hash of onboarding profile (lens material + MPS brand + wear bin + AQI bin + region) |
| `prior_mean` | REAL | Last server-returned prior mean |
| `prior_std` | REAL | Last server-returned prior std |

If `prior_mean` and `prior_std` columns don't exist yet, add them via `ALTER TABLE` in the existing db migration block.

---

## fl_sync_service.dart — full spec

```dart
// lib/services/fl_sync_service.dart

// This service is called after every session is written to sqflite.
// It checks connectivity, reads stats, POSTs to server, writes back priors.

class FlSyncService {

  // Entry point — call this after sqflite session write completes
  Future<void> maybeSyncAsync() async { ... }

  // Returns true if WiFi (not just mobile data)
  Future<bool> _isOnWifi() async { ... }

  // Reads baseline_mean, baseline_M2, session_count, cluster_id from sqflite
  Future<Map<String, dynamic>> _readStats() async { ... }

  // POSTs to server, returns {prior_mean, prior_std} or null on failure
  Future<Map<String, double>?> _postSync(Map<String, dynamic> stats) async { ... }

  // Writes prior_mean and prior_std back to sqflite
  Future<void> _writePriors(double priorMean, double priorStd) async { ... }
}
```

### Behavior rules:
- If `session_count < 14`: return early, do not sync. Local Welford baseline hasn't converged yet.
- If not on WiFi: return early silently. Do not show any error to user.
- If POST fails (timeout, server error): log the error, return silently. Do not crash or show error UI. Retry on next session.
- Timeout: 10 seconds max on the HTTP call.
- After successful sync: write `prior_mean` and `prior_std` to sqflite. These replace the cold-start defaults in the anomaly detection logic.

---

## How prior_mean and prior_std are used downstream

In the existing anomaly detection (already implemented in Dart):

```dart
bool isAnomaly(double deltaT, double mean, double m2, int count) {
  if (deltaT > 0.05) return true;
  if (count >= 14) return deltaT > mean + 2.0 * sqrt(m2 / (count - 1));
  return false;
}
```

After FL sync, the health score computation should seed its initial `mean` from `prior_mean` if `session_count < 14` (cold start). Once the user has 14+ sessions, their local Welford mean takes over. The Cursor agent does NOT need to modify this logic — just ensure `prior_mean` is written to sqflite so it's available.

---

## cluster_id generation

If `cluster_id` is not yet being generated, add this at onboarding completion:

```dart
String buildClusterId({
  required String lensMaterial,   // e.g. "silicone_hydrogel"
  required String mpsBrand,       // e.g. "optifree"
  required int wearHoursPerDay,   // bin: <8, 8-12, >12
  required int aqiBin,            // bin: <50, 50-150, >150
  required String cityRegion,     // coarse GPS city name
}) {
  // Bin wear hours
  String wearBin = wearHoursPerDay < 8 ? 'low'
      : wearHoursPerDay <= 12 ? 'mid' : 'high';

  // Bin AQI
  String aqiBinStr = aqiBin < 50 ? 'good'
      : aqiBin <= 150 ? 'moderate' : 'poor';

  String raw = '$lensMaterial|$mpsBrand|$wearBin|$aqiBinStr|$cityRegion';

  // Use a simple stable hash — no crypto needed, cluster granularity not security
  return raw.hashCode.toRadixString(16);
}
```

Store the result in sqflite at onboarding. Never recompute per session.

---

## File placement

```
lib/
├── services/
│   └── fl_sync_service.dart    ← create this
├── models/                     ← do not touch
├── screens/                    ← do not touch
└── main.dart                   ← do not touch
```

---

## Call site

In whatever file currently handles post-session sqflite writes, add at the end:

```dart
await FlSyncService().maybeSyncAsync();
```

This is fire-and-forget from the UI perspective — the await is just to avoid unhandled futures, but the user should not wait on it.

---

## What NOT to do

- Do not add a loading spinner or UI feedback for sync — it's a background operation
- Do not retry in a loop — one attempt per session
- Do not send raw ΔT values — only `mean`, `M2`, `count` (aggregated statistics)
- Do not send any PII — cluster_id is a hash, no names or emails
- Do not use `http` package for anything other than this sync call
- Do not touch BLE scan logic
