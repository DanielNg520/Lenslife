#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool lenslife_battery_init(void);
bool lenslife_battery_read_volts(float *volts_out);

#ifdef __cplusplus
}
#endif
