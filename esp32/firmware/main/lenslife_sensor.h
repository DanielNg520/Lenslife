#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    float deltaT_fouling;
    float deltaT_residual;
    float ph_corrected;
    float temp_celsius;
    float t_blank;
} lenslife_sensor_values_t;

typedef struct {
    lenslife_sensor_values_t values;
    bool kill_condition;
    bool ph_risk;
    bool temp_valid;
    bool blank_stale;
} lenslife_sensor_frame_t;

typedef enum {
    LENSELIFE_PHASE0_SAFE = 0,
    LENSELIFE_PHASE0_REPLACE_SOON,
    LENSELIFE_PHASE0_PH_RISK,
} lenslife_phase0_state_t;

void lenslife_sensor_compute(
    float t_pre,
    float t_post,
    float ph_raw,
    float temp_c,
    float t_blank,
    lenslife_sensor_values_t *out);

uint8_t lenslife_sensor_build_status_byte(const lenslife_sensor_frame_t *frame);
void lenslife_sensor_pack_payload(const lenslife_sensor_values_t *values, uint8_t out[20]);

lenslife_phase0_state_t lenslife_sensor_phase0_state(const lenslife_sensor_frame_t *frame);
const char *lenslife_phase0_label(lenslife_phase0_state_t state);

#ifdef __cplusplus
}
#endif
