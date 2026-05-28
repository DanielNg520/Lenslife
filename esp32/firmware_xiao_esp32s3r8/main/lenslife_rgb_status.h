#pragma once

#include <stdbool.h>

#include "lenslife_sensor.h"

#ifdef __cplusplus
extern "C" {
#endif

/** WS2812 onboard RGB — case signal (green / yellow / red). */
bool lenslife_rgb_init(void);
void lenslife_rgb_show_phase0(lenslife_phase0_state_t state);
void lenslife_rgb_show_connecting(void);
void lenslife_rgb_off(void);

#ifdef __cplusplus
}
#endif
