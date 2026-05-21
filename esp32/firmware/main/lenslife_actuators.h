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

/** Reed N/O to GND: returns true when lid is closed (magnet present, pin low). */
bool lenslife_reed_is_closed(void);

#ifdef __cplusplus
}
#endif
