# LensLife App State Summary

Last checked: 2026-05-25

## Repository Overview

This repository currently contains three active project areas:

- `App/`: Flutter mobile/web app for LensLife users.
- `esp32/firmware/`: ESP32-S3 firmware for the smart contact lens case.
- `product_website/`: Vite/React product landing page.

There are also supporting product, measurement, and implementation notes at the repository root.

## Flutter App (`App/`)

The Flutter app is the most complete deployable surface right now.

### Current User-Facing Features

- Splash screen with LensLife branding and loading transition.
- Local prototype authentication:
  - Create account with name, email, and password validation.
  - Login against an in-memory account store.
  - Password visibility toggle.
  - Logout from dashboard.
- Main dashboard with bottom navigation:
  - Home
  - Shop
  - Care
- Home dashboard:
  - Account greeting.
  - ESP32 BLE connection card.
  - Lens wear status card.
  - Cleanliness, eye safety, and lens age rings.
  - Deposit level, replacement estimate, lens type, and wear-time metric tiles.
  - Editable lens setup modal for daily, biweekly, and monthly lenses.
  - 30-day sample wear-time history chart.
  - Cleaning recommendation alert.
  - Stored readings list.
- Shop tab:
  - Monthly liner refill plan.
  - 3-month pack.
  - Starter kit.
  - Prototype checkout snackbars.
- Care tab:
  - Sample nearby optometrist cards.
  - Prototype appointment request snackbars.

### Current BLE / Sensor Features

- Scans for LensLife ESP32 devices by advertised service UUID/name fallback.
- Connects to the ESP32 GATT service `0xAB00`.
- Reads/subscribes to:
  - `0xAB01` SENSOR_DATA
  - `0xAB02` DEVICE_STATUS
  - `0xAB03` COMMAND
- Parses the 21-byte sensor payload:
  - `deltaTFouling`
  - `deltaTResidual`
  - `phCorrected`
  - `tempCelsius`
  - `anomalyScore`
  - `classifyResult`
- Parses device status bits:
  - kill condition
  - pH risk
  - temperature validity
  - blank staleness
  - pH sensor validity
  - IR sensor validity
- Sends commands:
  - acquire blank
  - trigger vibration
  - request sensor read
- Displays latest reading, status summary, and health summary in the dashboard card.

### Current Local Analytics / Storage Features

- Computes lens health score from:
  - fouling delta T
  - pH
  - temperature
  - wear days
  - AQI
- Detects anomalies with Welford baseline statistics.
- Handles IR-only mode when pH is invalid.
- Persists session aggregate data in SQLite:
  - baseline mean
  - baseline M2
  - session count
  - cluster ID
  - federated-learning priors
- Stores Welford state for:
  - delta T
  - pH
  - temperature

### Current Federated Learning Sync Features

- Builds a privacy-preserving cluster ID.
- Ensures a default cluster ID exists before sync.
- Records session delta T after valid IR readings.
- Runs background sync only when Wi-Fi or ethernet is available.
- Requires at least 14 sessions before syncing.
- Posts local aggregate stats to `FlSyncConfig.syncUrl`.
- Writes returned `prior_mean` and `prior_std` to SQLite.
- Sync failures are caught and logged so they do not break the app flow.

### Flutter Verification Results

Passed:

- `dart format lib/main.dart`
- `flutter analyze`
- `flutter test`
- `flutter build web`

Output artifact:

- `App/build/web`

Blocked:

- `flutter build apk --debug` is blocked on this machine because no Android SDK is configured: `No Android SDK found. Try setting the ANDROID_HOME environment variable.`

Known non-blocking note:

- Flutter prints a repeated `flutter_blue_plus` Windows plugin warning about `flutter_blue_plus_winrt`. The current web build, analyzer, and tests still pass. This may matter if Windows desktop is a target.

### Code Cleanup Done During This Check

- Updated deprecated Flutter `withOpacity` calls to `withValues(alpha: ...)`.
- Replaced placeholder underscore callback arguments that triggered analyzer info messages.
- Re-formatted `App/lib/main.dart`.

## ESP32 Firmware (`esp32/firmware/`)

The firmware is structured as an ESP-IDF/NimBLE project for ESP32-S3.

### Current Firmware Features

- Reed-switch wake flow:
  - Cold boot waits for lid close.
  - Reed wake starts measurement.
  - Unexpected wake returns to deep sleep.
- Hardware probing:
  - IR path through ADS1115 A1 and IR LED.
  - Optional pH channel through ADS1115 A0.
  - Optional DS18B20 temperature sensor.
  - Optional vibration motor.
  - Optional WS2812 RGB status LED.
- Measurement cycle:
  - Reads pre-clean IR voltage.
  - Runs vibration cleaning if motor is available.
  - Reads post-clean IR voltage.
  - Reads temperature when available, otherwise uses 25 C.
  - Waits for pH settle and reads pH when pH hardware is detected.
  - Computes sensor frame values.
  - Computes anomaly score.
  - Updates Welford statistics.
  - Classifies result.
  - Detects stale blank calibration.
- BLE peripheral:
  - Advertises as `LensLife`.
  - GATT service `0xAB00`.
  - SENSOR_DATA characteristic `0xAB01`: read/notify.
  - DEVICE_STATUS characteristic `0xAB02`: read.
  - COMMAND characteristic `0xAB03`: write.
  - Waits for a subscriber and sends the measurement frame.
- RGB status:
  - Green for safe.
  - Yellow for pH risk.
  - Red for replace/fouling risk.
  - Blue while waiting for BLE connection.
  - Off before deep sleep.
- Power flow:
  - Stops BLE after notification.
  - Shows final status briefly.
  - Enters deep sleep.

### Firmware Verification Results

Blocked:

- `idf.py` is not installed/on PATH.
- `pio` is not installed/on PATH.

Static review notes:

- The firmware source is organized consistently with the README and Flutter BLE expectations.
- One TODO remains in `esp32/firmware/main/ml/lenslife_classify.c`: replace the placeholder classifier with a sklearn tree export.

## Product Website (`product_website/`)

The product website is a Vite/React landing page generated from a Figma bundle.

### Current Website Features

- Sticky desktop/mobile navigation.
- Smooth scroll to sections.
- Hero section with LensLife messaging and CTAs.
- Interactive demo component.
- About section.
- Problem/solution comparison cards.
- Technology/how-it-works/pricing content in the landing page.
- Shared UI component library based on Radix/shadcn-style components.

### Website Verification Results

Blocked:

- `pnpm` is not installed/on PATH.
- `node_modules` is not present.
- `npm run build` fails because `vite` is not installed.
- An attempted `npm install --no-package-lock` stalled without output and did not create `node_modules`.

To verify the website later:

```bash
cd product_website
pnpm install
pnpm build
```

or install dependencies with the package manager you want to standardize on, then run the Vite build.

## Deployment Readiness

Ready enough to deploy now:

- Flutter web app, based on successful `flutter build web`.

Needs environment setup before deploy:

- Android app: install/configure Android SDK and set `ANDROID_HOME`.
- ESP32 firmware: install ESP-IDF or PlatformIO and run the firmware build.
- Product website: install `pnpm` or dependencies, then run the Vite build.

Main product gaps still present:

- Authentication is prototype-only and in-memory.
- Several dashboard values are sample/static until fully wired to persisted sensor history.
- Shop checkout and care appointment booking are placeholder snackbars.
- Website hero still uses a product image placeholder.
- Firmware classifier is still a placeholder.
