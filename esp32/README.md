# LensLife ESP32

Production firmware: **`firmware/`** (ESP-IDF + NimBLE, ESP32-S3-WROOM-1 N16R8).

- **Reed GPIO7** — lid closes → measure  
- **Onboard WS2812 GPIO38** — green / yellow / red status (+ blue during BLE)  
- **Flutter app** — full health score and server sync  

See [`firmware/README.md`](firmware/README.md).

Spec: [`../ESP32_BLE_Implementation.md`](../ESP32_BLE_Implementation.md)
