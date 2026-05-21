#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "lenslife_sensor.h"

#ifdef __cplusplus
extern "C" {
#endif

bool lenslife_measure_init_hardware(void);
bool lenslife_measure_acquire_blank(void);
bool lenslife_measure_run_cycle(lenslife_sensor_frame_t *frame_out);
void lenslife_measure_increment_session_count(void);

#ifdef __cplusplus
}
#endif
