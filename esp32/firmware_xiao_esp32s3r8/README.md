# XIAO ESP32-S3R8 Profile

This is a standalone firmware project folder for **Seeed XIAO ESP32-S3R8**.

Build from this folder:

```bash
cd esp32/firmware_xiao_esp32s3r8
pio run -e xiao-esp32s3r8
```

## Connected hardware for this profile

- ADS1115 (I2C)
- IR emitter (GPIO44)
- IR receiver through ADS1115 A1
- One **external** RGB status LED (WS2812, GPIO21)
- Vibration puck (GPIO43, optional)
- Battery sense input from TP4056 output divider (GPIO2, optional)

## Notes

- Vibration and battery monitoring are intentionally non-blocking.
- If either is missing, firmware continues and logs degraded capability.
- This board never uses the DevKitC onboard RGB (GPIO48); it always drives external WS2812 on GPIO21.
