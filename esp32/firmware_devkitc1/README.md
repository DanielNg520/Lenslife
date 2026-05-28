# LensLife Case Firmware (DevKitC-1, ESP32-S3-WROOM-1 N16R8)

ESP-IDF + **NimBLE** peripheral firmware.

## Hardware

| Component | GPIO | Notes |
|-----------|------|--------|
| I2C SDA/SCL | 8 / 9 | ADS1115 |
| DS18B20 | 4 | Temperature |
| IR LED | 5 | Sensor illumination |
| Vibration | 6 | Cleaning cycle |
| Reed switch | 7 | Lid close → wake + measure |
| **WS2812 RGB** | **48** | **Onboard** case status LED (DevKitC-1 only) |
| Battery sense (TP4056 divider) | 2 | Optional runtime battery monitor |

**RGB pin:** `LENSELIFE_PIN_RGB_WS2812` in `lenslife_pins.h` (default **GPIO48**). Use **38** only if your PCB routes WS2812 there instead.

## Case status LED (WS2812)

| Color | Meaning |
|-------|---------|
| **Green** | Safe (Phase 0 pass) |
| **Yellow** | pH risk |
| **Red** | Replace soon / fouling (`deltaT_fouling > 0.05`) |
| **Blue** | BLE advertising (waiting for phone) |
| Off | Deep sleep |

Same thresholds as serial Phase 0 log. Flutter app still shows detailed health score.

## Degraded / partial hardware

At boot, `lenslife_hw_probe()` detects what is connected:

| Capability | Required? | If missing |
|------------|-------------|------------|
| IR (ADS1115 A1 + LED) | **Yes** | Init fails — no fouling measurement |
| pH (ADS1115 A0) | No | Skips 30 s settle + A0 read; IR-only mode |
| DS18B20 | No | Uses 25 °C; no temp Welford updates |
| Vibration motor | No | Skips 10 s clean; IR reads still run |
| WS2812 RGB | No | Logs warning; measurement + BLE continue |

**pH auto-detect:** A0 voltage must be within `0.15–3.9 V` at probe (open AIN usually fails → IR-only).

**NVS `ph_mode` (u32):** `0` = auto (default), `1` = force pH on, `2` = force pH off.

**DEVICE_STATUS bits:** `0x10` = pH valid this session, `0x20` = IR valid. Flutter skips pH scoring when `0x10` clear.

## Flow

1. Reed wake (lid close)
2. Measure → RGB shows green / yellow / red (10 s)
3. BLE advertise → **blue** until Flutter connects → NOTIFY
4. RGB off → deep sleep until next lid close

## GATT

| UUID | Name |
|------|------|
| `0xAB00` | Service |
| `0xAB01` | SENSOR_DATA (NOTIFY, 20 B) |
| `0xAB02` | DEVICE_STATUS (READ, 1 B) |
| `0xAB03` | COMMAND (WRITE) |

Device name: `LensLife`

## Build

```bash
cd esp32/firmware_devkitc1
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/tty.usbmodem* flash monitor
```

Uses managed component `espressif/led_strip` (RMT driver for WS2812).

## Legacy sketch

`legacy/IR_sensor_reading.ino` is deprecated. Production uses onboard GPIO48 WS2812 via this folder.
