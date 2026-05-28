#pragma once

#include <stdbool.h>

#include "driver/i2c_master.h"

#ifdef __cplusplus
extern "C" {
#endif

bool lenslife_i2c_init(void);
i2c_master_bus_handle_t lenslife_i2c_bus(void);
i2c_master_dev_handle_t lenslife_i2c_dev(uint8_t addr_7bit);

#ifdef __cplusplus
}
#endif
