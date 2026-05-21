# LensLife Case Firmware (ESP32-S3-WROOM-1 N16R8)

ESP-IDF + **NimBLE** peripheral firmware.

## Hardware

| Component | GPIO | Notes |
|-----------|------|--------|
| I2C SDA/SCL | 8 / 9 | ADS1115 |
| DS18B20 | 4 | Temperature |
| IR LED | 5 | Sensor illumination |
| Vibration | 6 | Cleaning cycle |
| Reed switch | 7 | Lid close → wake + measure |
| **WS2812 RGB** | **38** | Built-in case status LED |

**RGB pin:** `38` on DevKitC-1 v1.1 / LensLife spec. If your board uses **GPIO48**, change `LENSELIFE_PIN_RGB_WS2812` in `lenslife_pins.h`.

## Case status LED (WS2812)

| Color | Meaning |
|-------|---------|
| **Green** | Safe (Phase 0 pass) |
| **Yellow** | pH risk |
| **Red** | Replace soon / fouling (`deltaT_fouling > 0.05`) |
| **Blue** | BLE advertising (waiting for phone) |
| Off | Deep sleep |

Same thresholds as serial Phase 0 log. Flutter app still shows detailed health score.

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
cd esp32/firmware
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/tty.usbmodem* flash monitor
```

Uses managed component `espressif/led_strip` (RMT driver for WS2812).

## Legacy sketch

`IR_sensor_reading.ino` is deprecated (separate RGB pins). Production uses GPIO38 WS2812 via `firmware/`.
