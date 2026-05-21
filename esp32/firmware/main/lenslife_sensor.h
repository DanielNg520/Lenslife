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

typedef struct __attribute__((packed)) {
    float delta_T_fouling;
    float delta_T_residual;
    float pH_corrected;
    float temp_c;
    float anomaly_score;
    uint8_t classify_result;
} ble_payload_t;

typedef struct {
    lenslife_sensor_values_t values;
    bool kill_condition;
    bool ph_risk;
    bool temp_valid;
    bool blank_stale;
    float anomaly_score;
    uint8_t classify_result;
} lenslife_sensor_frame_t;

typedef enum {
    LENSELIFE_PHASE0_SAFE = 0,
    LENSELIFE_PHASE0_REPLACE_SOON,
    LENSELIFE_PHASE0_ANOMALY,
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
void lenslife_sensor_pack_ble_payload(const lenslife_sensor_frame_t *frame, uint8_t out[21]);

lenslife_phase0_state_t lenslife_sensor_phase0_state(const lenslife_sensor_frame_t *frame);
const char *lenslife_phase0_label(lenslife_phase0_state_t state);

#ifdef __cplusplus
}
#endif
