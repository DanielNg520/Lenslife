#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool lenslife_ir_sensor_read_volts(float *volts_out);
void lenslife_ir_monitor_start(void);

#ifdef __cplusplus
}
#endif
