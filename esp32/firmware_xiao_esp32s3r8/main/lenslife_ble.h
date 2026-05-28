#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "lenslife_sensor.h"

#ifdef __cplusplus
extern "C" {
#endif

bool lenslife_ble_init(void);
void lenslife_ble_host_task(void *param);
bool lenslife_ble_start_advertising(void);
bool lenslife_ble_publish_frame(const lenslife_sensor_frame_t *frame);
bool lenslife_ble_wait_and_notify(const lenslife_sensor_frame_t *frame, uint32_t timeout_ms);
void lenslife_ble_stop(void);

#ifdef __cplusplus
}
#endif
