# LensLife ML Implementation — Cursor Prompt

## Context

You are implementing the ML pipeline for LensLife, a smart contact lens case.
The device uses an ESP32-S3-WROOM-1-N16R8 (16MB flash, 8MB PSRAM, dual-core LX7 @ 240MHz, hardware FPU).
Firmware is ESP-IDF. The mobile app is Flutter with `flutter_blue_plus`, `sqflite`, `riverpod`, `fl_chart`.

The sensing pipeline produces three values per session:
- `delta_T_fouling` = (T_pre − T_post) / T_blank  — IR turbidity delta
- `pH_corrected`    = pH_raw + (T_c − 25) × 0.003 — temperature-compensated pH
- `temp_c`          — DS18B20 temperature in Celsius

These are the only ML features. Do not invent additional features.

---

## What you are implementing

Two components in parallel:

1. **ESP32 firmware** — Phase 0 upgrade: replace two independent hard thresholds with a
   multivariate anomaly score (diagonal Mahalanobis / combined z-score across all three features),
   plus a placeholder decision tree classifier.

2. **Flutter app** — Phase 1: vector Welford EMA persisted in sqflite, health score computation,
   and anomaly detection that activates after 14 sessions.

---

## Part 1 — ESP32 firmware

> **Find the file that currently handles sensor reads and OLED output after a measurement cycle.**
> It likely contains the existing hard-threshold checks (delta_T > 0.05, pH outside 6.8–7.4).
> All changes in Part 1 go into that file and its companion header, or into a new
> `ml/lenslife_ml.c` + `ml/lenslife_ml.h` pair if the sensor file is already large.
> Do not touch GPIO, I2C, ADS1115, DS18B20, or BLE code.

### 1a. Welford state struct

Add this struct as a `static` global. Do NOT heap-allocate it — no `malloc`, no `heap_caps_malloc`.
It must live in internal DRAM (.bss). The ESP32-S3 has ~225KB heap available with BLE active;
the struct costs ~28 bytes total. There is no memory pressure, but static allocation
is correct practice here because this state is singleton and must survive the sensor task lifetime.

```c
typedef struct {
    float mean;
    float M2;      // Welford's M2 accumulator (sum of squared deviations from running mean)
    int   count;
} welford_t;

static welford_t w_dT   = {0.0f, 0.0f, 0};
static welford_t w_pH   = {0.0f, 0.0f, 0};
static welford_t w_temp = {0.0f, 0.0f, 0};
```

### 1b. Welford update and std functions

```c
// Welford online algorithm — numerically stable, single-pass.
// Call once per session after computing delta_T, pH_corrected, temp_c.
void welford_update(welford_t *w, float x) {
    w->count++;
    float delta = x - w->mean;
    w->mean += delta / (float)w->count;
    w->M2   += delta * (x - w->mean);
}

// Sample standard deviation. Returns 1.0 before 2 samples (safe epsilon).
float welford_std(const welford_t *w) {
    if (w->count < 2) return 1.0f;
    return sqrtf(w->M2 / (float)(w->count - 1));
}
```

### 1c. Anomaly score (replaces the two hard-threshold checks)

```c
// Diagonal Mahalanobis distance in z-score space.
// Returns a single float representing combined deviation from the user's baseline.
// Threshold 2.5 is the starting point — tune from bench data.
float lenslife_anomaly_score(float dT, float pH, float temp_c) {
    float z_dT   = (dT    - w_dT.mean)   / (welford_std(&w_dT)   + 1e-6f);
    float z_pH   = (pH    - w_pH.mean)   / (welford_std(&w_pH)   + 1e-6f);
    float z_temp = (temp_c - w_temp.mean) / (welford_std(&w_temp) + 1e-6f);
    return sqrtf(z_dT*z_dT + z_pH*z_pH + z_temp*z_temp);
}
```

> **Replace the existing `if (delta_T > 0.05)` and `if (pH < 6.8 || pH > 7.4)` OLED checks**
> with a call to `lenslife_anomaly_score()`. Keep the hard kill condition as a fast early-exit
> BEFORE the anomaly score (it is a confirmed bench-validated threshold and must always fire):
>
> ```c
> // Hard kill — always check first regardless of Welford count
> if (delta_T > 0.05f) {
>     oled_show_warning("Replace soon");  // use whatever your OLED function is called
> } else {
>     float score = lenslife_anomaly_score(delta_T, pH_corrected, temp_c);
>     if (score > 2.5f) {
>         oled_show_warning("Anomaly detected");
>     } else {
>         oled_show_ok("Safe to wear");
>     }
>     // Also check pH hard threshold independently for the pH-specific message
>     if (pH_corrected < 6.8f || pH_corrected > 7.4f) {
>         oled_show_warning("pH risk");
>     }
> }
> ```

### 1d. Decision tree classifier (placeholder)

> **Create `ml/lenslife_classify.c` and `ml/lenslife_classify.h`.**
> This function is a placeholder. It will be replaced with sklearn-generated C
> once bench data is available. Do not write a "smart" heuristic here — the
> placeholder must be obviously a placeholder so it gets replaced later.

```c
// lenslife_classify.h
#pragma once
// Returns: 0 = safe, 1 = caution, 2 = replace
// PLACEHOLDER — replace body with sklearn DecisionTreeClassifier export
// once 20+ labeled bench sessions are available.
int lenslife_classify(float dT, float pH, float temp_c, int wear_days);
```

```c
// lenslife_classify.c
#include "lenslife_classify.h"

int lenslife_classify(float dT, float pH, float temp_c, int wear_days) {
    // TODO: replace with sklearn tree export
    // Offline training command:
    //   clf = DecisionTreeClassifier(max_depth=4, min_samples_leaf=2)
    //   clf.fit(X, y)  # X: [dT, pH, temp, wear_days], y: [0,1,2]
    //   print(export_text(clf))  → translate output to C if/else
    if (dT > 0.05f)               return 2;
    if (pH < 6.5f || pH > 7.6f)  return 1;
    if (wear_days > 25)           return 1;
    return 0;
}
```

### 1e. NVS persistence for Welford state

> **Find where the firmware currently saves any persistent state (NVS namespace, boot init).
> Add load/save calls for the three Welford structs there.**
> If no NVS code exists yet, create `ml/lenslife_nvs.c` + `ml/lenslife_nvs.h`.
> Use namespace `"lenslife"`. Keys: `"dT_mean"`, `"dT_m2"`, `"dT_cnt"`,
> `"pH_mean"`, `"pH_m2"`, `"pH_cnt"`, `"tmp_mean"`, `"tmp_m2"`, `"tmp_cnt"`.
> Total NVS usage: ~48 bytes of values + overhead. No size risk.

```c
// Save — call after every successful measurement cycle
void lenslife_welford_save(void) {
    nvs_handle_t h;
    nvs_open("lenslife", NVS_READWRITE, &h);
    nvs_set_blob(h, "dT_mean",  &w_dT.mean,    sizeof(float));
    nvs_set_blob(h, "dT_m2",    &w_dT.M2,      sizeof(float));
    nvs_set_i32 (h, "dT_cnt",   w_dT.count);
    nvs_set_blob(h, "pH_mean",  &w_pH.mean,    sizeof(float));
    nvs_set_blob(h, "pH_m2",    &w_pH.M2,      sizeof(float));
    nvs_set_i32 (h, "pH_cnt",   w_pH.count);
    nvs_set_blob(h, "tmp_mean", &w_temp.mean,  sizeof(float));
    nvs_set_blob(h, "tmp_m2",   &w_temp.M2,    sizeof(float));
    nvs_set_i32 (h, "tmp_cnt",  w_temp.count);
    nvs_commit(h);
    nvs_close(h);
}

// Load — call once at boot before first measurement
void lenslife_welford_load(void) {
    nvs_handle_t h;
    esp_err_t err = nvs_open("lenslife", NVS_READONLY, &h);
    if (err != ESP_OK) return;  // first boot — keep zero-init defaults
    size_t sz = sizeof(float);
    nvs_get_blob(h, "dT_mean",  &w_dT.mean,    &sz);
    nvs_get_blob(h, "dT_m2",    &w_dT.M2,      &sz);
    nvs_get_i32 (h, "dT_cnt",   &w_dT.count);
    nvs_get_blob(h, "pH_mean",  &w_pH.mean,    &sz);
    nvs_get_blob(h, "pH_m2",    &w_pH.M2,      &sz);
    nvs_get_i32 (h, "pH_cnt",   &w_pH.count);
    nvs_get_blob(h, "tmp_mean", &w_temp.mean,  &sz);
    nvs_get_blob(h, "tmp_m2",   &w_temp.M2,    &sz);
    nvs_get_i32 (h, "tmp_cnt",  &w_temp.count);
    nvs_close(h);
}
```

### 1f. BLE payload struct

> **Find the existing BLE GATT notification/characteristic write.**
> Replace whatever you find with this packed struct as the payload.
> Do NOT send a computed 0–100 score from the ESP32 — the score is computed in Flutter.

```c
typedef struct __attribute__((packed)) {
    float   delta_T_fouling;   // (T_pre - T_post) / T_blank
    float   delta_T_residual;  // T_post / T_blank
    float   pH_corrected;      // temperature-compensated pH
    float   temp_c;            // DS18B20 reading
    float   anomaly_score;     // raw z-score from lenslife_anomaly_score()
    uint8_t classify_result;   // 0/1/2 from lenslife_classify()
} ble_payload_t;  // 21 bytes
```

---

## Part 2 — Flutter app

> **Find the existing BLE receive handler — the callback or stream listener that receives
> a notification from the ESP32 characteristic. All changes in Part 2 start there.**
> Also find the sqflite database initialization file (likely `database_helper.dart` or similar).

### 2a. sqflite schema additions

> **In the database initialization file, add this table if it does not exist.
> Do not modify any existing tables.**

```dart
await db.execute('''
  CREATE TABLE IF NOT EXISTS welford_state (
    feature TEXT PRIMARY KEY,
    mean    REAL NOT NULL DEFAULT 0.0,
    m2      REAL NOT NULL DEFAULT 0.0,
    count   INTEGER NOT NULL DEFAULT 0
  )
''');

// Seed the three feature rows on first run
await db.execute('''
  INSERT OR IGNORE INTO welford_state (feature, mean, m2, count)
  VALUES ('delta_T', 0.0, 0.0, 0),
         ('pH',      0.0, 0.0, 0),
         ('temp_c',  0.0, 0.0, 0)
''');
```

### 2b. WelfordState model + repository

> **Create `lib/ml/welford_state.dart`.**

```dart
// lib/ml/welford_state.dart

class WelfordState {
  final double mean;
  final double m2;
  final int count;

  const WelfordState({
    this.mean  = 0.0,
    this.m2    = 0.0,
    this.count = 0,
  });

  // Welford online update — call once per new session value.
  // Returns a new immutable WelfordState (do not mutate in place).
  WelfordState update(double x) {
    final n     = count + 1;
    final delta = x - mean;
    final newMean = mean + delta / n;
    final newM2   = m2 + delta * (x - newMean);
    return WelfordState(mean: newMean, m2: newM2, count: n);
  }

  // Sample standard deviation. Returns 1.0 before 2 samples.
  double get std => count < 2 ? 1.0 : sqrt(m2 / (count - 1));

  // Z-score of a new observation against this baseline.
  double zScore(double x) => (x - mean) / (std + 1e-9);

  Map<String, dynamic> toMap(String feature) =>
      {'feature': feature, 'mean': mean, 'm2': m2, 'count': count};

  factory WelfordState.fromMap(Map<String, dynamic> m) =>
      WelfordState(mean: m['mean'], m2: m['m2'], count: m['count']);
}
```

> **Create `lib/ml/welford_repository.dart`.**
> This handles all sqflite reads and writes for Welford state.
> Use the existing database helper — do not open a second database connection.

```dart
// lib/ml/welford_repository.dart
// Prompt to Cursor: import your existing DatabaseHelper / db singleton here.
// The table name is 'welford_state'. Feature keys are 'delta_T', 'pH', 'temp_c'.

class WelfordRepository {
  final Database db;  // inject — use your existing db instance
  WelfordRepository(this.db);

  Future<WelfordState> load(String feature) async {
    final rows = await db.query(
      'welford_state',
      where: 'feature = ?',
      whereArgs: [feature],
    );
    if (rows.isEmpty) return const WelfordState();
    return WelfordState.fromMap(rows.first);
  }

  Future<void> save(String feature, WelfordState state) async {
    await db.insert(
      'welford_state',
      state.toMap(feature),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
```

### 2c. Health score computation

> **Create `lib/ml/health_score.dart`.**
> This is the only place the 0–100 score is computed. Do not compute it anywhere else.

```dart
// lib/ml/health_score.dart
import 'dart:math';
import 'welford_state.dart';

const double _killThreshold = 0.05;   // bench-confirmed IR kill condition
const double _anomalyThreshold = 2.5; // combined z-score threshold

// Returns 0–100. Clamps at both ends.
double computeHealthScore({
  required double deltaT,
  required double pH,
  required double tempC,
  required int    wearDays,
  required int    aqi,
  required WelfordState wDT,
  required WelfordState wPH,
}) {
  double score = 100.0;

  // IR fouling — normalized to kill condition (0.05 = 40pt deduction)
  score -= (deltaT / _killThreshold).clamp(0.0, 1.0) * 40.0;

  // pH deviation — distance outside safe zone 6.8–7.4
  double pHDist = 0.0;
  if (pH < 6.8) pHDist = 6.8 - pH;
  if (pH > 7.4) pHDist = pH - 7.4;
  score -= pHDist * 30.0;

  // Wear days — non-linear, maxes at 30 days
  score -= (wearDays / 30.0).clamp(0.0, 1.0) * 15.0;

  // AQI penalty (OpenWeatherMap integration — pass 0 if unavailable)
  if (aqi > 200)      score -= 20.0;
  else if (aqi > 150) score -= 10.0;

  return score.clamp(0.0, 100.0);
}

// Multivariate anomaly detection — activates after 14 sessions per feature.
// Before 14 sessions: falls back to the hard IR kill condition only.
bool isAnomaly({
  required double deltaT,
  required double pH,
  required WelfordState wDT,
  required WelfordState wPH,
}) {
  // Hard kill always fires regardless of session count
  if (deltaT > _killThreshold) return true;

  if (wDT.count >= 14 && wPH.count >= 14) {
    final zDT = wDT.zScore(deltaT);
    final zPH = wPH.zScore(pH);
    return sqrt(zDT * zDT + zPH * zPH) > _anomalyThreshold;
  }

  return false;
}
```

### 2d. BLE receive handler wiring

> **In the existing BLE notification handler / characteristic listener:**
> 1. Deserialize the 21-byte `ble_payload_t` in the same field order as the C struct.
> 2. Call `welfordRepo.load()` for `delta_T` and `pH`.
> 3. Call `.update()` on each, then `welfordRepo.save()`.
> 4. Call `computeHealthScore()` with the updated states.
> 5. Call `isAnomaly()`.
> 6. Update Riverpod state with the new score and anomaly flag.
>
> **Do not call `computeHealthScore()` or `isAnomaly()` from anywhere else in the codebase.**
> If a widget needs the score, it reads it from the Riverpod provider — not by calling these functions directly.

```dart
// Pseudocode — adapt to your existing BLE stream / provider structure.
// Prompt to Cursor: find the onValueReceived / characteristic.lastValueStream
// subscription and wire this logic in there.

Future<void> _onBlePayload(List<int> bytes) async {
  if (bytes.length < 21) return;  // guard against partial packets

  final buf = Uint8List.fromList(bytes).buffer.asByteData();
  final deltaT       = buf.getFloat32(0,  Endian.little);
  final deltaTResid  = buf.getFloat32(4,  Endian.little);
  final pHCorrected  = buf.getFloat32(8,  Endian.little);
  final tempC        = buf.getFloat32(12, Endian.little);
  final anomalyScore = buf.getFloat32(16, Endian.little);
  final classResult  = buf.getUint8(20);

  // Load Welford state from sqflite
  final wDT  = await welfordRepo.load('delta_T');
  final wPH  = await welfordRepo.load('pH');
  final wTmp = await welfordRepo.load('temp_c');

  // Update Welford state with new observations
  final wDTNew  = wDT.update(deltaT);
  final wPHNew  = wPH.update(pHCorrected);
  final wTmpNew = wTmp.update(tempC);

  // Persist updated state
  await welfordRepo.save('delta_T', wDTNew);
  await welfordRepo.save('pH',      wPHNew);
  await welfordRepo.save('temp_c',  wTmpNew);

  // Compute score and anomaly
  final score = computeHealthScore(
    deltaT:   deltaT,
    pH:       pHCorrected,
    tempC:    tempC,
    wearDays: ref.read(wearDaysProvider),  // from onboarding
    aqi:      ref.read(aqiProvider),       // from OpenWeatherMap
    wDT:      wDTNew,
    wPH:      wPHNew,
  );

  final anomaly = isAnomaly(
    deltaT: deltaT,
    pH:     pHCorrected,
    wDT:    wDTNew,
    wPH:    wPHNew,
  );

  // Push to Riverpod — let widgets rebuild from state, not from this function
  ref.read(sessionResultProvider.notifier).update(
    score:        score,
    anomaly:      anomaly,
    classResult:  classResult,
    anomalyScore: anomalyScore,
    rawPayload: SessionRawData(
      deltaT: deltaT, deltaTResidual: deltaTResid,
      pH: pHCorrected, tempC: tempC,
    ),
  );
}
```

---

## Hard constraints — do not violate these

| # | Rule |
|---|------|
| 1 | `welford_t` structs on ESP32 are `static` globals — never `malloc`'d |
| 2 | PSRAM (`MALLOC_CAP_SPIRAM`) is never used for sensor state or ML structs |
| 3 | DMA buffers (I2C, SPI) use `MALLOC_CAP_DMA \| MALLOC_CAP_INTERNAL` only |
| 4 | Decision tree in `lenslife_classify.c` is a pure C switch/if-else — no external lib |
| 5 | Health score (0–100) is computed only in Flutter, never on ESP32 |
| 6 | BLE payload is always the `ble_payload_t` packed struct — 21 bytes, little-endian |
| 7 | `computeHealthScore()` and `isAnomaly()` are called only from the BLE handler |
| 8 | `WelfordState` is immutable in Dart — `.update()` returns a new instance |
| 9 | Forbidden GPIO pins: 35, 36, 37 (PSRAM bus), 38 (RGB LED), 0 (BOOT) — do not reassign |
| 10 | ADS1115 PGA is ±4.096V — do not change gain register |

---

## What NOT to do

- Do not add TFLite Micro — no model file, no arena, no interpreter. That is Phase 2.
- Do not compute a health score on the ESP32. The ESP32 sends raw physics values.
- Do not add WiFi code to the ESP32 — BLE only for now.
- Do not create a second sqflite database. Add the `welford_state` table to the existing db.
- Do not store Welford state in SharedPreferences — use sqflite for consistency with FL sync.
- Do not add any new GPIO assignments without checking the forbidden list above.
- Do not use `double` in ESP32 firmware — use `float` everywhere (LX7 FPU is single-precision).

---

## Files to create

```
firmware/
  ml/
    lenslife_ml.c          ← welford_update, welford_std, lenslife_anomaly_score, NVS load/save
    lenslife_ml.h
    lenslife_classify.c    ← placeholder decision tree
    lenslife_classify.h

lib/
  ml/
    welford_state.dart     ← WelfordState model + update/zScore logic
    welford_repository.dart ← sqflite load/save wrapper
    health_score.dart      ← computeHealthScore(), isAnomaly()
```

> **After creating these files, search the existing codebase for the BLE notification handler
> and the boot/init sequence. Wire `lenslife_welford_load()` into boot and
> `lenslife_welford_save()` + `lenslife_anomaly_score()` into the measurement cycle.
> Wire `_onBlePayload()` into the Flutter BLE stream. Do not move or rename any existing files.**
