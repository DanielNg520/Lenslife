#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool lenslife_ds18b20_init(void);
bool lenslife_ds18b20_read_celsius(float *temp_out);

#ifdef __cplusplus
}
#endif
