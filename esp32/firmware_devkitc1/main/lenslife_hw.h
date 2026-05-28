#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/** Runtime capability flags set once at boot by lenslife_hw_probe(). */
typedef struct {
    bool i2c_ok;
    bool ads_ok;
    bool ir_ok;       /* ADS1115 A1 + IR LED path */
    bool ph_hw;       /* A0 channel looks like a connected pH front-end */
    bool temp_hw;     /* DS18B20 presence detected */
    bool motor_ok;
    bool battery_ok;
    bool rgb_ok;
} lenslife_hw_caps_t;

/** ph_mode NVS: 0=auto probe, 1=force enable, 2=force disable */
#define LENSELIFE_PH_MODE_AUTO     0U
#define LENSELIFE_PH_MODE_FORCE_ON  1U
#define LENSELIFE_PH_MODE_FORCE_OFF 2U

#define LENSELIFE_STATUS_PH_VALID  0x10U
#define LENSELIFE_STATUS_IR_VALID  0x20U

#define LENSELIFE_PH_NEUTRAL       7.0f

void lenslife_hw_probe(void);
const lenslife_hw_caps_t *lenslife_hw_caps(void);

#ifdef __cplusplus
}
#endif
