#pragma once

/**
 * LensLife ESP32-S3-WROOM-1 N16R8 pin map (ESP32_BLE_Implementation.md).
 *
 * Present: ADS1115 (I2C), DS18B20, IR LED (sensor), vibration motor, reed (GPIO7),
 *          onboard WS2812 RGB (GPIO38) for case status (green / yellow / red).
 * Not used: SSD1306 OLED.
 *
 * RGB GPIO: 38 on ESP32-S3-DevKitC-1 v1.1 / LensLife PCB per spec.
 *            Use 48 if your board wires WS2812 to GPIO48 (older DevKitC-1).
 * Never use GPIO 0, 35, 36, 37 for custom peripherals (38 = WS2812 only).
 */
#define LENSELIFE_PIN_I2C_SDA        8
#define LENSELIFE_PIN_I2C_SCL        9
#define LENSELIFE_PIN_ONEWIRE        4
#define LENSELIFE_PIN_IR_LED         5
#define LENSELIFE_PIN_VIBRATION      6
#define LENSELIFE_PIN_REED_SWITCH    7
#define LENSELIFE_PIN_RGB_WS2812     38

#define LENSELIFE_I2C_FREQ_HZ        100000
#define LENSELIFE_ADS1115_ADDR       0x48

#define LENSELIFE_DELTAT_KILL        0.05f
#define LENSELIFE_PH_LOW             6.8f
#define LENSELIFE_PH_HIGH            7.4f
#define LENSELIFE_BLANK_STALE_SEC    (7U * 24U * 3600U)
#define LENSELIFE_VIBRATION_MS       10000
#define LENSELIFE_PH_SETTLE_MS       30000
#define LENSELIFE_REED_WAIT_MS       120000
#define LENSELIFE_RGB_DISPLAY_MS     10000
#define LENSELIFE_BLE_WAIT_MS        90000

#define LENSELIFE_BLE_DEVICE_NAME    "LensLife"
