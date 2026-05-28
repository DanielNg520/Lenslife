#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    float mean;
    float M2;
    int32_t count;
} welford_t;

void welford_update(welford_t *w, float x);
float welford_std(const welford_t *w);

float lenslife_anomaly_score(float dT, float pH, float temp_c);

float lenslife_anomaly_score_filtered(
    float dT,
    float pH,
    float temp_c,
    bool ph_valid,
    bool temp_valid);

void lenslife_welford_save(void);
void lenslife_welford_load(void);

void lenslife_welford_update_session(float dT, float pH, float temp_c);

void lenslife_welford_update_session_filtered(
    float dT,
    float pH,
    float temp_c,
    bool ph_valid,
    bool temp_valid);

#ifdef __cplusplus
}
#endif
