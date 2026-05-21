#include "lenslife_sensor.h"

#include <math.h>
#include <string.h>

#include "lenslife_hw.h"
#include "lenslife_pins.h"

void lenslife_sensor_compute(
    float t_pre,
    float t_post,
    float ph_raw,
    float temp_c,
    float t_blank,
    bool ph_valid,
    lenslife_sensor_values_t *out)
{
    float blank = t_blank;
    if (blank < 1e-6f) {
        blank = 1.0f;
    }

    out->deltaT_fouling = (t_pre - t_post) / blank;
    out->deltaT_residual = t_post / blank;
    if (ph_valid) {
        out->ph_corrected = ph_raw + (temp_c - 25.0f) * 0.003f;
    } else {
        out->ph_corrected = LENSELIFE_PH_NEUTRAL;
    }
    out->temp_celsius = temp_c;
    out->t_blank = t_blank;
}

uint8_t lenslife_sensor_build_status_byte(const lenslife_sensor_frame_t *frame)
{
    uint8_t status = 0;
    if (frame->kill_condition) {
        status |= 0x01;
    }
    if (frame->ph_risk) {
        status |= 0x02;
    }
    if (frame->temp_valid) {
        status |= 0x04;
    }
    if (frame->blank_stale) {
        status |= 0x08;
    }
    if (frame->ph_valid) {
        status |= LENSELIFE_STATUS_PH_VALID;
    }
    if (frame->ir_valid) {
        status |= LENSELIFE_STATUS_IR_VALID;
    }
    return status;
}

void lenslife_sensor_pack_ble_payload(const lenslife_sensor_frame_t *frame, uint8_t out[21])
{
    ble_payload_t payload = {
        .delta_T_fouling = frame->values.deltaT_fouling,
        .delta_T_residual = frame->values.deltaT_residual,
        .pH_corrected = frame->values.ph_corrected,
        .temp_c = frame->values.temp_celsius,
        .anomaly_score = frame->anomaly_score,
        .classify_result = frame->classify_result,
    };
    memcpy(out, &payload, sizeof(payload));
}

lenslife_phase0_state_t lenslife_sensor_phase0_state(const lenslife_sensor_frame_t *frame)
{
    if (frame->kill_condition) {
        return LENSELIFE_PHASE0_REPLACE_SOON;
    }
    if (frame->ph_valid && frame->ph_risk) {
        return LENSELIFE_PHASE0_PH_RISK;
    }
    if (frame->anomaly_score > 2.5f) {
        return LENSELIFE_PHASE0_ANOMALY;
    }
    return LENSELIFE_PHASE0_SAFE;
}

const char *lenslife_phase0_label(lenslife_phase0_state_t state)
{
    switch (state) {
    case LENSELIFE_PHASE0_SAFE:
        return "Safe to wear";
    case LENSELIFE_PHASE0_REPLACE_SOON:
        return "Replace soon";
    case LENSELIFE_PHASE0_ANOMALY:
        return "Anomaly detected";
    case LENSELIFE_PHASE0_PH_RISK:
    default:
        return "pH risk";
    }
}
