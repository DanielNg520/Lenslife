#pragma once

/**
 * LensLife — XIAO ESP32-S3R8 (perfboard wiring guide).
 *
 *  D1 / GPIO2  → RGB red (220 Ω)
 *  D2 / GPIO3  → RGB green (220 Ω)
 *  D3 / GPIO4  → RGB blue (220 Ω)   common cathode → GND
 *  D4 / GPIO5  → ADS1115 SDA
 *  D5 / GPIO6  → ADS1115 SCL
 *  D7 / GPIO44 → optional push button (not used in this no-button build)
 *  D9 / GPIO8  → IR emitter (100 Ω)
 *  D10 / GPIO9 → vibration MOSFET gate (100 Ω + 100 kΩ pulldown)
 *
 * ADS1115 A1 → IR photodiode node. A0 unused unless pH module added later.
 * TP4056 OUT+ → battery only (not 3V3). No ADC sense pin in this build.
 *
 * Forbidden on R8: GPIO 0 (boot), 35–37 (OPI PSRAM), 21 (onboard USER_LED).
 */

#define LENSELIFE_PIN_I2C_SDA        5
#define LENSELIFE_PIN_I2C_SCL        6

#define LENSELIFE_PIN_RGB_RED        2
#define LENSELIFE_PIN_RGB_GREEN      3
#define LENSELIFE_PIN_RGB_BLUE       4

#define LENSELIFE_PIN_IR_LED         8
#define LENSELIFE_PIN_VIBRATION      9
/** No-button bench build: start automatically on boot and repeat on a timer. */
#ifndef LENSELIFE_USE_BUTTON
#define LENSELIFE_USE_BUTTON         0
#endif

/** Optional push button: LOW when pressed (internal pull-up enabled). */
#define LENSELIFE_PIN_BUTTON         44

/** GPIO44 is not an RTC pin — use light-sleep GPIO wake, not EXT1 deep sleep. */
#define LENSELIFE_BUTTON_USE_LIGHT_SLEEP_WAKE  1

#ifndef LENSELIFE_USE_VIBRATION
#define LENSELIFE_USE_VIBRATION      1
#endif

#ifndef LENSELIFE_USE_BATTERY
#define LENSELIFE_USE_BATTERY        0
#endif

#ifndef LENSELIFE_USE_DS18B20
#define LENSELIFE_USE_DS18B20        0
#endif

#if LENSELIFE_PIN_I2C_SDA != 5 || LENSELIFE_PIN_I2C_SCL != 6
#error "XIAO ESP32-S3 D4/D5 are GPIO5/GPIO6 for SDA/SCL in this profile"
#endif

#if LENSELIFE_USE_BUTTON && LENSELIFE_PIN_BUTTON != 44
#error "XIAO ESP32-S3 D7 is GPIO44; keep button wake on GPIO44 or update sleep handling"
#endif

#if LENSELIFE_PIN_IR_LED != 8 || LENSELIFE_PIN_VIBRATION != 9
#error "XIAO ESP32-S3 D9/D10 are GPIO8/GPIO9 in this profile"
#endif

#if LENSELIFE_PIN_RGB_RED == LENSELIFE_PIN_RGB_GREEN || \
    LENSELIFE_PIN_RGB_RED == LENSELIFE_PIN_RGB_BLUE || \
    LENSELIFE_PIN_RGB_GREEN == LENSELIFE_PIN_RGB_BLUE || \
    LENSELIFE_PIN_RGB_RED == LENSELIFE_PIN_I2C_SDA || \
    LENSELIFE_PIN_RGB_GREEN == LENSELIFE_PIN_I2C_SDA || \
    LENSELIFE_PIN_RGB_BLUE == LENSELIFE_PIN_I2C_SDA || \
    LENSELIFE_PIN_RGB_RED == LENSELIFE_PIN_I2C_SCL || \
    LENSELIFE_PIN_RGB_GREEN == LENSELIFE_PIN_I2C_SCL || \
    LENSELIFE_PIN_RGB_BLUE == LENSELIFE_PIN_I2C_SCL || \
    LENSELIFE_PIN_IR_LED == LENSELIFE_PIN_VIBRATION
#error "LensLife XIAO pin conflict: RGB, I2C, IR, and motor pins must be unique"
#endif

#if LENSELIFE_USE_BUTTON && ( \
    LENSELIFE_PIN_IR_LED == LENSELIFE_PIN_BUTTON || \
    LENSELIFE_PIN_VIBRATION == LENSELIFE_PIN_BUTTON)
#error "LensLife XIAO pin conflict: button must not share IR or motor pins"
#endif

#if LENSELIFE_USE_BATTERY && !defined(LENSELIFE_PIN_BATTERY_ADC)
#error "Define LENSELIFE_PIN_BATTERY_ADC before enabling LENSELIFE_USE_BATTERY"
#endif

#if LENSELIFE_USE_DS18B20 && !defined(LENSELIFE_PIN_ONEWIRE)
#error "Define LENSELIFE_PIN_ONEWIRE before enabling LENSELIFE_USE_DS18B20"
#endif

#define LENSELIFE_I2C_FREQ_HZ        400000
#define LENSELIFE_ADS1115_ADDR       0x48

#define LENSELIFE_DELTAT_KILL        0.05f
#define LENSELIFE_PH_LOW             6.8f
#define LENSELIFE_PH_HIGH            7.4f
#define LENSELIFE_PH_PROBE_V_MIN     0.15f
#define LENSELIFE_PH_PROBE_V_MAX     3.90f
#define LENSELIFE_BLANK_STALE_SEC    (7U * 24U * 3600U)
#define LENSELIFE_VIBRATION_MS       10000
#define LENSELIFE_PH_SETTLE_MS       30000
#define LENSELIFE_BUTTON_WAIT_MS     120000
#define LENSELIFE_RGB_DISPLAY_MS     10000
#define LENSELIFE_BLE_WAIT_MS        90000
#define LENSELIFE_AUTO_CYCLE_IDLE_MS 30000
#define LENSELIFE_IR_MONITOR_MS      500

#ifndef LENSELIFE_USE_IR_MONITOR
#define LENSELIFE_USE_IR_MONITOR     1
#endif

#define LENSELIFE_BLE_DEVICE_NAME    "LensLife"

/** @deprecated use LENSELIFE_PIN_BUTTON */
#define LENSELIFE_PIN_REED_SWITCH    LENSELIFE_PIN_BUTTON
#define LENSELIFE_REED_WAIT_MS       LENSELIFE_BUTTON_WAIT_MS
