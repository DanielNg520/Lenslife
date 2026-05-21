#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    float mean;
    float M2;
    int count;
} welford_t;

void welford_update(welford_t *w, float x);
float welford_std(const welford_t *w);

float lenslife_anomaly_score(float dT, float pH, float temp_c);

void lenslife_welford_save(void);
void lenslife_welford_load(void);

void lenslife_welford_update_session(float dT, float pH, float temp_c);

#ifdef __cplusplus
}
#endif
