#pragma once

/**
 * LensLife XIAO ESP32-S3R8 pin map.
 *
 * Present: ADS1115 (I2C), IR emitter + ADS1115 receiver, external WS2812 RGB,
 * optional vibration puck, optional battery ADC from TP4056/divider.
 */
#define LENSELIFE_PIN_I2C_SDA        5
#define LENSELIFE_PIN_I2C_SCL        6
#define LENSELIFE_PIN_ONEWIRE        4
#define LENSELIFE_PIN_IR_LED         44
#define LENSELIFE_PIN_VIBRATION      43
#define LENSELIFE_PIN_REED_SWITCH    7
#define LENSELIFE_PIN_RGB_WS2812     21
#define LENSELIFE_PIN_BATTERY_ADC    2

#ifndef LENSELIFE_USE_VIBRATION
#define LENSELIFE_USE_VIBRATION      1
#endif

#ifndef LENSELIFE_USE_BATTERY
#define LENSELIFE_USE_BATTERY        1
#endif

#define LENSELIFE_I2C_FREQ_HZ        100000
#define LENSELIFE_ADS1115_ADDR       0x48

#define LENSELIFE_DELTAT_KILL        0.05f
#define LENSELIFE_PH_LOW             6.8f
#define LENSELIFE_PH_HIGH            7.4f
/** A0 voltage window for auto-detecting a pH front-end (open/floating AIN is usually outside). */
#define LENSELIFE_PH_PROBE_V_MIN     0.15f
#define LENSELIFE_PH_PROBE_V_MAX     3.90f
#define LENSELIFE_BLANK_STALE_SEC    (7U * 24U * 3600U)
#define LENSELIFE_VIBRATION_MS       10000
#define LENSELIFE_PH_SETTLE_MS       30000
#define LENSELIFE_REED_WAIT_MS       120000
#define LENSELIFE_RGB_DISPLAY_MS     10000
#define LENSELIFE_BLE_WAIT_MS        90000

#define LENSELIFE_BLE_DEVICE_NAME    "LensLife"
