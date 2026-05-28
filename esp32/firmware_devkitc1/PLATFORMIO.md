# Flash firmware with PlatformIO

Project root: **`esp32/firmware`** (this folder).

## What must exist (already in repo)

| File / folder | Purpose |
|---------------|---------|
| `platformio.ini` | Board + ESP-IDF framework (`src_dir = main` for ESP-IDF layout) |
| `CMakeLists.txt` | ESP-IDF project root |
| `main/*.c` + `main/CMakeLists.txt` | Firmware source |
| `main/idf_component.yml` | Downloads `led_strip` for WS2812 |
| `sdkconfig.defaults` | S3, NimBLE, 16 MB flash, PSRAM |

You do **not** need a separate `sdkconfig` in git — it is generated on first build.

## Prerequisites (on your machine)

1. [PlatformIO](https://platformio.org/) — VS Code extension **or** CLI (`pip install platformio`)
2. USB cable to the ESP32-S3 board (data-capable)
3. **Internet** on first build (toolchain + `led_strip` component download)
4. **No** separate ESP-IDF install required (PlatformIO bundles it)

## One-time setup

```bash
cd esp32/firmware
```

In VS Code: **File → Open Folder** → select `esp32/firmware` (the folder that contains `platformio.ini`).

## Step 1 — Verify build (required before upload)

Upload only works if the build succeeds.

```bash
cd esp32/firmware
pio run -e esp32-s3-n16r8
```

The `esp32-s3-n16r8` env uses board `esp32-s3-devkitc-1` with **16 MB flash** and **OPI PSRAM** overrides (N16R8 module). PlatformIO has no separate `esp32-s3-devkitc-1-n16r8` board ID in v6.10.

Optional duplicate env `esp32-s3-devkitc-1` is equivalent if you prefer that name for upload.

First build often takes **10–20+ minutes** (downloads ESP-IDF + tools).

## Step 2 — Upload

### VS Code

1. PlatformIO sidebar → **esp32-s3-n16r8** (or **esp32-s3-devkitc-1**)
2. **Upload** (must see `SUCCESS` — not only Build)

### Terminal

```bash
pio run -e esp32-s3-n16r8 -t upload
pio device monitor -e esp32-s3-n16r8
```

## Step 3 — Confirm on serial

You should see lines like:

```
LensLife ESP32-S3 boot, wake cause=...
```

If the log is empty, try another USB port or lower `upload_speed` to `460800` in `platformio.ini`.

## Pick the right USB port

List ports:

```bash
pio device list
```

If upload fails to find the board, uncomment and set in `platformio.ini`:

```ini
upload_port = /dev/cu.usbmodem1101    ; macOS example
monitor_port = /dev/cu.usbmodem1101
```

Windows example: `COM3`

## Upload problems

| Issue | Fix |
|-------|-----|
| Port not found | Install CP210x or USB-JTAG driver; try another cable (data, not charge-only) |
| Timed out waiting for packet header | Hold **BOOT**, press **RESET**, release **BOOT**, run upload again |
| Wrong chip | Board must be **ESP32-S3**; env is `esp32-s3-n16r8` |
| RGB LED wrong color / off | Default is **GPIO48**; if your board uses GPIO38, change `LENSELIFE_PIN_RGB_WS2812` in `main/lenslife_pins.h` |

## After flash

1. Close the serial monitor before uploading again (port is exclusive).
2. Close the **lid** (reed switch) to wake and run a measurement cycle.
3. On first cold boot over USB, firmware waits up to 120 s for lid close.
4. Watch serial log for `Phase 0 result:` and RGB color logs.

## Clean rebuild

```bash
pio run -t fullclean
pio run -t upload
```

## Not Arduino

This project uses **`framework = espidf`**, not Arduino. Do not open `IR_sensor_reading.ino` in PlatformIO as the main firmware.
