#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

bool lenslife_actuators_init(void);
void lenslife_ir_led_set(bool on);
void lenslife_vibration_set(bool on);
void lenslife_vibration_run_ms(uint32_t duration_ms);

/** Button to GND with INPUT_PULLUP: true while pressed (pin low). */
bool lenslife_button_is_pressed(void);

/** Legacy name — same as button pressed (was reed/lid closed). */
bool lenslife_reed_is_closed(void);

#ifdef __cplusplus
}
#endif
