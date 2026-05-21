# LensLife — ESP32 BLE GATT Server Implementation Spec
**For Cursor | ESP-IDF + NimBLE | May 2026**

---

## Role of This Component

ESP32 is a **BLE peripheral (server)**. Flutter is the central (client).

ESP32 responsibilities:
- Run the measurement protocol on lid close
- Apply Phase 0 hard thresholds
- Display result on OLED
- Transmit raw sensor payload over BLE GATT NOTIFY
- Enter deep sleep immediately after

ESP32 never:
- Initializes WiFi (comment this explicitly in code)
- Talks to the Flower server
- Computes health score, EMA baseline, anomaly detection beyond hard thresholds, cluster ID, or AQI penalty

---

## Hardware Pin Assignments

| Signal | GPIO | Notes |
|---|---|---|
| I2C SDA | 8 | Shared: ADS1115 + SSD1306 OLED |
| I2C SCL | 9 | Shared: ADS1115 + SSD1306 OLED |
| DS18B20 1-Wire | 4 | 4.7kΩ pullup to 3.3V |
| IR LED anode | 5 | 56Ω series resistor to 3.3V |
| Vibration motor | 6 | 1kΩ to 2N2222 base; collector to motor |
| Reed switch | 7 | N/O, other side to GND; wakeup source |

### Forbidden GPIOs — never assign, never configure

| GPIO | Reason |
|---|---|
| 35, 36, 37 | OPI PSRAM bus — hardware conflict |
| 38 | Onboard WS2812B RGB LED |
| 0 | BOOT strapping pin |

---

## I2C Device Addresses

| Device | Address |
|---|---|
| ADS1115 | `0x48` (ADDR pin to GND) |
| SSD1306 OLED | `0x3C` |

Both share GPIO8/9. No address conflict.

---

## ADS1115 Configuration

- PGA: **±4.096V only**
  - ±6.144V exceeds VDD — hardware damage risk
  - ±2.048V clips pH signal
- Sample rate: 128 SPS
- Channel A0: pH module analog output (PO pin)
- Channel A1: IR photodiode (10kΩ pullup to 3.3V)
- Mode: single-shot per reading

---

## NVS Keys (nvs_flash — survives deep sleep)

```c
"t_blank"         // float   — last valid T_blank voltage reading
"blank_timestamp" // uint32  — unix epoch of last blank acquisition
"session_count"   // uint32  — incremented each full measurement cycle
```

**Critical:** T_blank must be read from NVS on every wake. Global variables are wiped on deep sleep entry. This is the most common ESP-IDF deep sleep bug.

---

## Measurement Sequence (order is non-negotiable)

```
1.  Wake from deep sleep via GPIO7 reed switch (lid close)
2.  Init NVS → read t_blank, blank_timestamp, session_count
3.  Init I2C → ADS1115 + SSD1306
4.  Init 1-Wire → DS18B20
5.  Read T_pre   (ADS1115 A1, IR photodiode, lens in case)
6.  GPIO5 HIGH → vibration motor ON (via GPIO6/2N2222) → 10s → OFF
7.  Read T_post  (ADS1115 A1, IR photodiode, after vibration)
8.  Read temp_c  (DS18B20, GPIO4)
9.  Wait for pH probe settle (30s timeout or button confirm)
10. Read pH_raw  (ADS1115 A0)
11. Compute derived values (see formulas below)
12. Phase 0 threshold check → OLED display
13. Init NimBLE → advertise → wait for Flutter connection
14. On connect: NOTIFY SENSOR_DATA characteristic
15. Increment session_count → write to NVS
16. OLED off → esp_deep_sleep_start()
```

---

## Computed Values (on-device)

```c
float deltaT_fouling  = (T_pre - T_post) / t_blank;
float deltaT_residual = T_post / t_blank;
float pH_corrected    = pH_raw + (temp_c - 25.0f) * 0.003f;
```

Everything else (health score, EMA, anomaly, cluster, AQI) is computed in Flutter.

---

## Phase 0 Thresholds (hardcoded, never BLE-configurable)

```c
#define DELTA_T_KILL  0.05f   // bench-validated kill condition
#define PH_LOW        6.8f
#define PH_HIGH       7.4f
```

These are safety floors. Flutter may apply tighter personalized thresholds on top. ESP32 cannot be made less sensitive than these values.

---

## OLED Output (SSD1306, 0.96", I2C 0x3C)

Three possible states only:

| Condition | Display |
|---|---|
| deltaT ≤ 0.05 AND pH in [6.8, 7.4] | `"Safe"` |
| deltaT > 0.05 | `"Replace soon"` |
| pH outside [6.8, 7.4] | `"pH risk"` |

OLED stays on for **10 seconds** after display, then off before deep sleep. Do not leave it on indefinitely.

---

## BLE GATT Structure

**Stack: NimBLE** (not Bluedroid — NimBLE is significantly lighter on flash and RAM)

**One service, three characteristics:**

### Service UUID: `0xAB00`

| Characteristic | UUID | Properties | Size |
|---|---|---|---|
| `SENSOR_DATA` | `0xAB01` | NOTIFY + READ | 20 bytes |
| `DEVICE_STATUS` | `0xAB02` | READ | 1 byte |
| `COMMAND` | `0xAB03` | WRITE | 1 byte |

---

### SENSOR_DATA Payload (20 bytes, little-endian floats)

```
Bytes [0–3]   float  deltaT_fouling
Bytes [4–7]   float  deltaT_residual
Bytes [8–11]  float  pH_corrected
Bytes [12–15] float  temp_celsius
Bytes [16–19] float  T_blank         ← Flutter uses this to detect baseline drift
```

Flutter parses this as 5 consecutive `float32` little-endian values.

---

### DEVICE_STATUS Byte (bitmask)

```
bit 0: kill_condition_triggered   (deltaT_fouling > 0.05)
bit 1: pH_risk                    (pH outside 6.8–7.4)
bit 2: temp_read_valid            (DS18B20 responded successfully)
bit 3: blank_is_stale             (1 = last blank >7 days old, needs re-blank)
bits 4–7: reserved, set to 0
```

---

### COMMAND Byte (Flutter → ESP32, WRITE)

```
0x01  Trigger T_blank acquisition (user confirmed no lens in case)
0x02  Trigger vibration motor manually (bench testing)
0x03  Request immediate sensor data read
```

On receiving `0x01`, ESP32 reads ADS1115 A1 with no lens present, writes result to NVS key `"t_blank"` and updates `"blank_timestamp"`. This is the only way to refresh the blank.

---

## Power Rules

```c
// After BLE notify completes:
esp_sleep_enable_ext0_wakeup(GPIO_NUM_7, 0); // wake on lid close (active low)
esp_deep_sleep_start();

// WiFi must never be initialized. Add this comment in app_main:
// WiFi disabled by design. FL sync is Flutter's responsibility via phone WiFi.
// Do not initialize esp_wifi or nvs_flash wifi entries.
```

---

## Cursor Implementation Scope (in order)

1. ESP-IDF project scaffold with NimBLE component enabled in `CMakeLists.txt`
2. NVS init + `nvs_read_float`, `nvs_write_float`, `nvs_read_u32`, `nvs_write_u32` helpers
3. ADS1115 I2C driver — single-ended read on A0 and A1, PGA ±4.096V
4. DS18B20 1-Wire driver on GPIO4
5. IR LED control on GPIO5 (GPIO output high/low, no PWM)
6. Vibration motor control on GPIO6 (GPIO output high/low, no PWM)
7. Reed switch deep sleep wakeup on GPIO7
8. SSD1306 OLED I2C driver on GPIO8/9 — 3 display states only
9. Measurement sequence function in exact order above
10. Phase 0 threshold logic feeding OLED state
11. NimBLE GATT server — service `0xAB00`, characteristics `0xAB01–0xAB03`
12. SENSOR_DATA pack function (5 floats → 20-byte little-endian buffer)
13. DEVICE_STATUS bitmask builder
14. COMMAND handler for `0x01`, `0x02`, `0x03`
15. Deep sleep entry with GPIO7 wakeup after BLE notify confirmed

---

## What Flutter Expects

Flutter (`flutter_blue_plus`) connects, enables NOTIFY on `0xAB01`, receives the 20-byte payload, and parses:

```dart
ByteData bd = ByteData.sublistView(Uint8List.fromList(value));
double deltaTFouling  = bd.getFloat32(0,  Endian.little);
double deltaTResidual = bd.getFloat32(4,  Endian.little);
double phCorrected    = bd.getFloat32(8,  Endian.little);
double tempCelsius    = bd.getFloat32(12, Endian.little);
double tBlank         = bd.getFloat32(16, Endian.little);
```

Flutter then runs Phase 1 EMA anomaly detection and computes the 0–100 health score independently. ESP32 has no visibility into that result.
