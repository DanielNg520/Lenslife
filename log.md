# LensLife — Implementation Log

**Project:** LensLife smart contact lens case  
**Target hardware:** ESP32-S3-WROOM-1 N16R8 + Flutter app (`App/`)  
**Primary references:** `flutter_fl_sync_guideline.md`, `ESP32_BLE_Implementation.md`, `lenslife_ml_cursor_prompt.md`  
**Log scope:** Work performed via Cursor agent sessions (federated sync, BLE, ESP-IDF firmware, PlatformIO, hardware alignment, ML pipeline).

---

## 1. Executive summary

LensLife was extended from a UI-only Flutter prototype into a two-part system:

| Layer | Role |
|-------|------|
| **ESP32 firmware** (`esp32/firmware/`) | Sensor protocol, Phase 0 thresholds, onboard RGB status, NimBLE GATT server, deep sleep on reed wake |
| **Flutter app** (`App/`) | BLE central, parses 21-byte payloads, per-feature Welford in sqflite, 0–100 health score + anomaly (14-session gate), background FL sync to VPS |

The ESP32 never uses WiFi or talks to the FL server. The phone syncs aggregated statistics over WiFi when `session_count >= 14`.

---

## 2. System architecture

```
[Lid close → reed GPIO7]
        ↓
[ESP32-S3] measure → Welford update + z-score → Phase 0 → RGB (G/Y/R/orange) → NimBLE NOTIFY 0xAB01 (21 B)
        ↓ BLE
[Flutter] parse → Welford (delta_T, pH, temp_c) → health score / anomaly → sqflite → POST /sync (WiFi)
        ↓
[VPS] prior_mean, prior_std → sqflite
```

---

## 3. Flutter app (`App/`)

### 3.1 Federated learning (FL) sync

Implemented per `flutter_fl_sync_guideline.md`.

| File | Purpose |
|------|---------|
| `lib/services/fl_sync_config.dart` | `http://<FL_SYNC_HOST>:8080/sync` via `--dart-define=FL_SYNC_HOST` (default `127.0.0.1`) |
| `lib/services/fl_sync_service.dart` | WiFi-only check, read stats, POST, write `prior_mean` / `prior_std`; 10 s timeout; silent failure |
| `lib/services/session_database.dart` | sqflite `sessions` row: Welford `baseline_mean`, `baseline_M2`, `session_count`, `cluster_id`, priors |
| `lib/services/session_service.dart` | `recordSession()` → DB update + `unawaited` FL sync; `completeOnboarding()` / `ensureClusterIdForSync()` |
| `lib/utils/cluster_id.dart` | Stable SHA-256 cluster hash (16 hex chars) from lens/MPS/wear/AQI/region |

**Sync rules:** WiFi only; `session_count >= 14`; requires `cluster_id`; no UI spinner; one attempt per session.

**Dependencies added (`pubspec.yaml`):** `sqflite`, `path`, `http`, `connectivity_plus`, `crypto`, `flutter_blue_plus`, `flutter_launcher_icons`.

### 3.2 BLE integration (ESP32 spec)

Replaced placeholder GATT UUIDs with spec-compliant NimBLE layout.

| File | Purpose |
|------|---------|
| `lib/ble/esp32_gatt_uuids.dart` | Service `0xAB00`, chars `0xAB01`–`0xAB03` |
| `lib/ble/esp32_ble_service.dart` | Scan, connect, NOTIFY on `0xAB01`, READ status, WRITE commands |
| `lib/models/esp32_sensor_payload.dart` | 21-byte parser (4× float32 LE + anomaly score + classify byte) |
| `lib/models/esp32_device_status.dart` | 1-byte status bitmask + `Esp32Command` enum |
| `lib/services/sensor_session_handler.dart` | NOTIFY → analytics → `SessionService.recordSession()` |
| `lib/widgets/esp32_ble_connection_card.dart` | Dashboard UI: connect, readings, health summary, calibrate blank / read now |

**Commands (0xAB03):** `0x01` T_blank, `0x02` vibration, `0x03` measure now.

### 3.3 Local analytics / ML (app — Phase 1)

Implemented per `lenslife_ml_cursor_prompt.md`. Health score (0–100) is computed **only in Flutter**, only from the BLE path (`sensor_session_handler.dart`).

| File | Purpose |
|------|---------|
| `lib/ml/welford_state.dart` | Immutable Welford model: `.update()`, `.std`, `.zScore()` |
| `lib/ml/welford_repository.dart` | sqflite load/save for `welford_state` table |
| `lib/ml/health_score.dart` | `computeHealthScore()` (ΔT, pH, wear days, AQI) and `isAnomaly()` (kill @ 0.05, multivariate z after 14 sessions) |
| `lib/services/sensor_session_handler.dart` | NOTIFY → score/anomaly **before** Welford update → persist → `SessionService.recordSession()` for FL |
| `lib/services/session_database.dart` | DB v3: added `welford_state` (`delta_T`, `pH`, `temp_c`); existing `sessions` row unchanged for FL sync |

**Removed:** `lib/services/health_analytics.dart` (superseded by `lib/ml/health_score.dart`).

**Defaults:** `wearDays` and `aqi` pass as `0` until onboarding / OpenWeatherMap providers exist (prompt mentioned Riverpod; app does not use it yet).

### 3.4 Platform / manifest

| Change | Detail |
|--------|--------|
| `android/app/src/main/AndroidManifest.xml` | `INTERNET`, `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, cleartext HTTP |
| `ios/Runner/Info.plist` | `NSBluetoothAlwaysUsageDescription`, ATS for HTTP VPS |
| `macos/Runner/*.entitlements` | Network client (macOS dev) |
| `test/widget_test.dart` | Smoke test for `LensLifeApp` splash |
| `App/FL_SYNC_CHANGES_LOG.md` | Earlier FL-only change log (companion doc) |

**Not modified (per guideline):** core UI structure in `lib/main.dart` beyond swapping in `Esp32BleConnectionCard`.

---

## 4. ESP32 firmware (`esp32/firmware/`)

### 4.1 Stack

- **Framework:** ESP-IDF + **NimBLE** (not Bluedroid)
- **Target:** ESP32-S3-WROOM-1 N16R8 (16 MB flash, 8 MB OPI PSRAM)
- **WiFi:** explicitly disabled in `app_main.c`

### 4.2 Source modules

| Module | Responsibility |
|--------|----------------|
| `app_main.c` | Reed wake → measure → BLE → notify → deep sleep |
| `lenslife_nvs.c` | `t_blank`, `blank_timestamp`, `session_count` |
| `lenslife_i2c.c` / `lenslife_ads1115.c` | I2C, ADS1115 A0 pH / A1 IR, PGA ±4.096 V, 128 SPS |
| `lenslife_ds18b20.c` | 1-Wire temperature on GPIO4 |
| `lenslife_actuators.c` | IR LED GPIO5, motor GPIO6, reed GPIO7 |
| `lenslife_sensor.c` | Derived values, `ble_payload_t` pack (21 B), Phase 0 state (kill → pH → anomaly → safe) |
| `lenslife_measure.c` | Full measurement sequence; Welford load at init, anomaly score, classify, NVS save |
| `ml/lenslife_ml.c` | Static `welford_t` for ΔT / pH / temp; diagonal Mahalanobis; NVS keys in `"lenslife"` |
| `ml/lenslife_classify.c` | Placeholder decision tree (0 safe / 1 caution / 2 replace) — replace with sklearn export later |
| `lenslife_ble.c` | GATT `0xAB00`–`0xAB03`, NOTIFY, COMMAND handler |
| `lenslife_rgb_status.c` | Onboard WS2812 via `espressif/led_strip` (RMT) |
| `lenslife_power.c` | Deep sleep, wake on reed active-low |

### 4.3 GPIO map (current hardware)

| Signal | GPIO | Notes |
|--------|------|--------|
| I2C SDA / SCL | 8 / 9 | ADS1115 @ `0x48` |
| DS18B20 | 4 | 1-Wire |
| IR LED | 5 | Sensor illumination (not status RGB) |
| Vibration motor | 6 | 10 s cleaning cycle |
| Reed switch | 7 | Lid close → wake + trigger |
| WS2812 RGB | 48 | Onboard status LED (DevKitC-1; see below) |

**Not used:** SSD1306 OLED, external RGB LED pins from legacy `.ino`, GPIO 0/35/36/37/38 for generic IO (38 dedicated to WS2812).

### 4.4 Hardware decisions (evolution)

| Topic | Decision |
|-------|----------|
| **OLED** | Removed — no SSD1306 driver; Phase 0 logged on serial only |
| **Reed switch** | **Kept** — lid close wakes device and starts measurement |
| **Case RGB** | **Onboard WS2812 (GPIO48)** — green / yellow / red + blue while BLE advertising; not separate red/green/yellow discrete LEDs |
| **Legacy `IR_sensor_reading.ino`** | Deprecated; marked with comment pointing to `esp32/firmware/` |

### 4.5 RGB status mapping

| Color | Meaning |
|-------|---------|
| Green | Phase 0 safe |
| Yellow | pH risk |
| Red | Replace soon / fouling (`deltaT_fouling > 0.05`) |
| Orange | Anomaly detected (combined z-score > 2.5) |
| Blue | BLE advertising |
| Off | Deep sleep |

Default WS2812 pin is **GPIO48** (`LENSELIFE_PIN_RGB_WS2812` in `main/lenslife_pins.h`). Use **GPIO38** only on boards that wire the LED there.

### 4.6 Measurement sequence

1. Reed wake (or cold-boot wait for lid close, up to 120 s)  
2. NVS load → I2C → 1-Wire  
3. T_pre (IR A1) → vibration 10 s → T_post → DS18B20  
4. pH settle (30 s max, early exit if lid opens)  
5. pH (ADS A0) → derived values → anomaly score (pre-update) → Welford update + NVS → classify → Phase 0 + RGB 10 s  
6. NimBLE advertise → wait for phone → NOTIFY 21 bytes  
7. `session_count++` → RGB shows result briefly → deep sleep until next reed wake  

### 4.7 Build configuration

| File | Purpose |
|------|---------|
| `CMakeLists.txt` | ESP-IDF project `lenslife_case` |
| `sdkconfig.defaults` | esp32s3, NimBLE, 16 MB flash, OPI PSRAM |
| `main/idf_component.yml` | Managed dep `espressif/led_strip` ^2.5.5 |
| `platformio.ini` | PlatformIO envs `esp32-s3-n16r8` / `esp32-s3-devkitc-1` |
| `PLATFORMIO.md` | Build → upload → monitor checklist |

---

## 5. BLE / FL API contracts

### 5.1 GATT (ESP32 ↔ Flutter)

**Service:** `0xAB00`

| UUID | Name | Properties |
|------|------|------------|
| `0xAB01` | SENSOR_DATA | NOTIFY + READ, 21 bytes |
| `0xAB02` | DEVICE_STATUS | READ, 1 byte bitmask |
| `0xAB03` | COMMAND | WRITE, 1 byte |

**Device name:** `LensLife`

**NOTIFY payload (`ble_payload_t`, 21 bytes, little-endian):**

| Offset | Field | Type |
|--------|--------|------|
| 0–3 | `delta_T_fouling` | float32 |
| 4–7 | `delta_T_residual` | float32 |
| 8–11 | `pH_corrected` | float32 |
| 12–15 | `temp_c` | float32 |
| 16–19 | `anomaly_score` | float32 (diagonal Mahalanobis z on device) |
| 20 | `classify_result` | uint8 (0 safe / 1 caution / 2 replace) |

No 0–100 health score on ESP32. `T_blank` is no longer in the NOTIFY payload (still in NVS for measurement math).

**DEVICE_STATUS bits:** kill, pH risk, temp valid, blank stale (>7 days)

### 5.2 FL server (Flutter ↔ VPS)

**POST** `http://<VPS_IP>:8080/sync`

```json
{ "cluster_id": "string", "mean": 0.08, "M2": 0.001, "count": 14 }
```

**Response:**

```json
{ "prior_mean": 0.08, "prior_std": 0.014 }
```

---

## 6. Files created (high level)

### Flutter — new under `App/lib/`

```
ble/esp32_gatt_uuids.dart
ble/esp32_ble_service.dart
models/esp32_sensor_payload.dart
models/esp32_device_status.dart
services/fl_sync_config.dart
services/fl_sync_service.dart
services/session_database.dart
services/session_service.dart
services/sensor_session_handler.dart
utils/cluster_id.dart
widgets/esp32_ble_connection_card.dart
ml/welford_state.dart
ml/welford_repository.dart
ml/health_score.dart
```

### ESP32 — new under `esp32/firmware/`

```
CMakeLists.txt
sdkconfig.defaults
platformio.ini
PLATFORMIO.md
README.md
main/app_main.c
main/lenslife_*.c/h          (drivers, BLE, measure, RGB, power)
main/ml/lenslife_*.c/h       (on-device ML)
main/idf_component.yml
```

### Docs / meta

```
flutter_fl_sync_guideline.md   (pre-existing spec)
ESP32_BLE_Implementation.md  (pre-existing spec; BLE payload layout see §5.1 / §12)
lenslife_ml_cursor_prompt.md   (ML Phase 0/1 implementation spec)
esp32/README.md
App/FL_SYNC_CHANGES_LOG.md
log.md                         (this file)
```

### Removed / deprecated

- `App/session_service.dart` (duplicate at wrong path — deleted)
- `App/lib/services/health_analytics.dart` (replaced by `lib/ml/health_score.dart`)
- `esp32/firmware/main/lenslife_ssd1306.c/h` (OLED removed)
- Initial wrong BLE UUIDs in `main.dart` (replaced by `Esp32BleConnectionCard`)
- 20-byte BLE payload with `T_blank` as fifth float (replaced by 21-byte `ble_payload_t`)

---

## 7. Fixes and maintenance during implementation

| Issue | Resolution |
|-------|------------|
| Corrupt `pubspec.lock` (duplicate `sdks:`) | Regenerated via `flutter pub get` |
| `session_service` blocking BLE with `await` on 10 s HTTP | Changed to `unawaited(FlSyncService().maybeSyncAsync())` |
| `widget_test.dart` referenced non-existent `MyApp` | Updated to `LensLifeApp` smoke test |
| ESP-IDF vs Arduino split | Production path is `esp32/firmware/` only |
| PlatformIO first-time build | Documented: build must succeed before upload |

---

## 8. How to run / flash

### Flutter

```bash
cd App
flutter pub get
flutter run --dart-define=FL_SYNC_HOST=<your.vps.ip>
```

### ESP32 (PlatformIO)

```bash
cd esp32/firmware
pio run -e esp32-s3-n16r8
pio run -e esp32-s3-n16r8 -t upload
pio device monitor -e esp32-s3-n16r8
```

See `esp32/firmware/PLATFORMIO.md` for troubleshooting (port, BOOT+RESET, GPIO48 RGB).

---

## 9. Out of scope / not implemented

- VPS FastAPI server implementation (client only in app)
- Riverpod / `fl_chart` integration (not wired; BLE card uses `setState` today)
- TFLite Micro on ESP32 (Phase 2 per ML prompt)
- Sklearn-exported decision tree in `lenslife_classify.c` (placeholder thresholds only until bench data)
- On-device WiFi or FL on ESP32
- Discrete external RGB LED pins (legacy `.ino` only)
- OLED UI on case
- Automated CI for firmware or app

---

## 10. Verification status

| Component | Analyzer / build |
|-----------|------------------|
| Flutter `lib/` | `dart analyze lib/` — clean (infos in `main.dart` only) |
| ESP-IDF firmware | Not CI-built in agent environment; structure matches ESP-IDF + PIO layout |

---

## 11. Related documentation

| Document | Location |
|----------|----------|
| FL sync guideline | `flutter_fl_sync_guideline.md` |
| ESP32 BLE spec | `ESP32_BLE_Implementation.md` (20-byte layout superseded by §5.1 / §12) |
| ML implementation prompt | `lenslife_ml_cursor_prompt.md` |
| FL app change log | `App/FL_SYNC_CHANGES_LOG.md` |
| Firmware README | `esp32/firmware/README.md` |
| PlatformIO guide | `esp32/firmware/PLATFORMIO.md` |

---

## 12. ML pipeline implementation (2026-05-20)

Cursor session implementing `lenslife_ml_cursor_prompt.md`: Phase 0 firmware upgrade + Phase 1 Flutter analytics.

### 12.1 ML features (fixed set)

Only three physics-derived features per session:

- `delta_T_fouling` = (T_pre − T_post) / T_blank  
- `pH_corrected` = pH_raw + (T_c − 25) × 0.003  
- `temp_c` — DS18B20 Celsius  

### 12.2 ESP32 — Phase 0 upgrade

| Item | Detail |
|------|--------|
| Welford state | Three `static` `welford_t` globals in internal DRAM (no heap/PSRAM) |
| Anomaly | `lenslife_anomaly_score()` — diagonal Mahalanobis (combined z); threshold 2.5 |
| Hard kill | `delta_T_fouling > 0.05` still checked first (bench-validated); drives red RGB |
| Phase 0 order | Kill → pH band (6.8–7.4) → anomaly z → safe |
| NVS | Keys `dT_mean/m2/cnt`, `pH_*`, `tmp_*` in namespace `"lenslife"`; load at `lenslife_measure_init_hardware()`, save after each cycle |
| Classify | `lenslife_classify()` placeholder in `ml/lenslife_classify.c` (wear_days = `session_count`) |
| Scoring order | Anomaly computed **before** Welford update with current session |
| BLE | `lenslife_sensor_pack_ble_payload()`; `s_sensor_payload[21]` in `lenslife_ble.c` |
| CMake | Added `ml/lenslife_ml.c`, `ml/lenslife_classify.c` to `main/CMakeLists.txt` |

**Not touched:** GPIO, I2C, ADS1115, DS18B20, NimBLE service layout (UUIDs unchanged).

### 12.3 Flutter — Phase 1

| Item | Detail |
|------|--------|
| Schema | `session_database.dart` v3 → `welford_state` table + seed rows |
| Models | `Esp32SensorPayload` → 21 bytes; `anomalyScore`, `classifyResult`; removed `tBlank` from NOTIFY |
| Analytics | `computeHealthScore()` / `isAnomaly()` only from `SensorSessionHandler.processPayload()` |
| Welford | Per-feature EMA in sqflite; update **after** score/anomaly for current reading |
| FL sync | Unchanged: `sessions` row + `recordSession(deltaT)` still feeds `/sync` |
| UI | `esp32_ble_connection_card.dart` — health % from `double` score |

### 12.4 Hard constraints honored

- No TFLite, no WiFi on ESP32, no health score on device  
- Single sqflite DB; Welford not in SharedPreferences  
- `float` only on ESP32; forbidden GPIO list unchanged  
- ADS1115 PGA ±4.096 V unchanged  

### 12.5 Sensor degradation (2026-05-20)

- `lenslife_hw.c` — boot probe for IR / pH / temp / motor / RGB; minimum requirement is IR path  
- IR-only: skips pH settle and A0; `ph_valid=false`; neutral pH 7.0 in payload; no false pH risk  
- ML: `lenslife_anomaly_score_filtered()` and Welford updates skip invalid features  
- STATUS bits `0x10` (pH valid), `0x20` (IR valid); Flutter gates pH score/Welford on `phSensorValid`  
- NVS `ph_mode`: 0=auto, 1=force on, 2=force off  

### 12.6 Follow-ups

- Wire `wearDays` / `aqi` into `SensorSessionHandler.processPayload()` from onboarding and weather  
- Replace `lenslife_classify.c` body after 20+ labeled bench sessions  
- Update `ESP32_BLE_Implementation.md` to match 21-byte payload and STATUS bits  

---

*End of implementation log.*
