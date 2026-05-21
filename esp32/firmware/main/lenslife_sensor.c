#include "lenslife_sensor.h"

#include <math.h>
#include <string.h>

#include "lenslife_pins.h"

void lenslife_sensor_compute(
    float t_pre,
    float t_post,
    float ph_raw,
    float temp_c,
    float t_blank,
    lenslife_sensor_values_t *out)
{
    float blank = t_blank;
    if (blank < 1e-6f) {
        blank = 1.0f;
    }

    out->deltaT_fouling = (t_pre - t_post) / blank;
    out->deltaT_residual = t_post / blank;
    out->ph_corrected = ph_raw + (temp_c - 25.0f) * 0.003f;
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
    return status;
}

void lenslife_sensor_pack_payload(const lenslife_sensor_values_t *values, uint8_t out[20])
{
    memcpy(&out[0], &values->deltaT_fouling, 4);
    memcpy(&out[4], &values->deltaT_residual, 4);
    memcpy(&out[8], &values->ph_corrected, 4);
    memcpy(&out[12], &values->temp_celsius, 4);
    memcpy(&out[16], &values->t_blank, 4);
}

lenslife_phase0_state_t lenslife_sensor_phase0_state(const lenslife_sensor_frame_t *frame)
{
    if (frame->ph_risk) {
        return LENSELIFE_PHASE0_PH_RISK;
    }
    if (frame->kill_condition) {
        return LENSELIFE_PHASE0_REPLACE_SOON;
    }
    if (frame->values.deltaT_fouling <= LENSELIFE_DELTAT_KILL &&
        frame->values.ph_corrected >= LENSELIFE_PH_LOW &&
        frame->values.ph_corrected <= LENSELIFE_PH_HIGH) {
        return LENSELIFE_PHASE0_SAFE;
    }
    return LENSELIFE_PHASE0_PH_RISK;
}

const char *lenslife_phase0_label(lenslife_phase0_state_t state)
{
    switch (state) {
    case LENSELIFE_PHASE0_SAFE:
        return "Safe";
    case LENSELIFE_PHASE0_REPLACE_SOON:
        return "Replace soon";
    case LENSELIFE_PHASE0_PH_RISK:
    default:
        return "pH risk";
    }
}
