# XIAO ESP32-S3R8 Profile

Firmware aligned with the **XIAO Quick Rewiring Guide** (perfboard build).

```bash
cd esp32/firmware_xiao_esp32s3r8
pio run -e xiao-esp32s3r8
```

Monitor/flashing: **USB-C** (USB Serial/JTAG). D6/D7 are not used for UART console.

## Pin map

| XIAO pad | GPIO | Firmware signal |
|----------|------|-----------------|
| D1 | 2 | RGB red |
| D2 | 3 | RGB green |
| D3 | 4 | RGB blue |
| D4 | 5 | I2C SDA (ADS1115) |
| D5 | 6 | I2C SCL |
| D7 | 44 | Push button (INPUT_PULLUP → GND) |
| D9 | 8 | IR emitter |
| D10 | 9 | Vibration MOSFET gate |
| 3V3 | — | ADS1115 VDD, photodiode pull-up |
| GND | — | Common ground |

## Behavior

1. **Cold boot** — waits up to 2 min for a button press on D7.
2. **Measurement** — I2C ADS1115 @ 0x48, IR on A1, emitter on D9; optional 10 s vibration on D10.
3. **BLE** — advertises as `LensLife`, notifies the app; RGB **blue** while connecting.
4. **Status RGB** — green / yellow (R+G) / red / orange (R+G) from Phase 0 result.
5. **Sleep** — **light sleep** until button pressed again (GPIO44 is not RTC-capable for deep-sleep EXT1).

IR photodiode path is probed at boot (emitter on → read A1). pH on A0 is auto-detected only if a module is wired; this guide leaves A0 unused.

## Not in this wiring build

| Feature | Status |
|---------|--------|
| WS2812 | Removed — discrete RGB only |
| DS18B20 | Disabled (D3 is blue LED) |
| Battery ADC | Disabled (no sense pin in guide) |
| Reed switch | Replaced by push button on D7 |

## Status colors (common cathode)

| Phase | LEDs on |
|-------|---------|
| Safe | Green |
| pH risk | Red + green (yellow) |
| Replace soon | Red |
| Anomaly | Red + green (orange) |
| BLE active | Blue |

## DevKitC

Use `esp32/firmware_devkitc1` for the DevKit pin map (GPIO48 WS2812, reed on GPIO7, etc.).
