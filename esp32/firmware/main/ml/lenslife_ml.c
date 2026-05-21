#include "lenslife_ml.h"

#include <math.h>

#include "nvs.h"

#include "lenslife_nvs.h"

static welford_t w_dT   = {0.0f, 0.0f, 0};
static welford_t w_pH   = {0.0f, 0.0f, 0};
static welford_t w_temp = {0.0f, 0.0f, 0};

void welford_update(welford_t *w, float x)
{
    w->count++;
    float delta = x - w->mean;
    w->mean += delta / (float)w->count;
    w->M2 += delta * (x - w->mean);
}

float welford_std(const welford_t *w)
{
    if (w->count < 2) {
        return 1.0f;
    }
    return sqrtf(w->M2 / (float)(w->count - 1));
}

float lenslife_anomaly_score(float dT, float pH, float temp_c)
{
    return lenslife_anomaly_score_filtered(dT, pH, temp_c, true, true);
}

float lenslife_anomaly_score_filtered(
    float dT,
    float pH,
    float temp_c,
    bool ph_valid,
    bool temp_valid)
{
    float sum = 0.0f;
    float z_dT = (dT - w_dT.mean) / (welford_std(&w_dT) + 1e-6f);
    sum += z_dT * z_dT;

    if (ph_valid) {
        float z_pH = (pH - w_pH.mean) / (welford_std(&w_pH) + 1e-6f);
        sum += z_pH * z_pH;
    }
    if (temp_valid) {
        float z_temp = (temp_c - w_temp.mean) / (welford_std(&w_temp) + 1e-6f);
        sum += z_temp * z_temp;
    }
    return sqrtf(sum);
}

void lenslife_welford_save(void)
{
    nvs_handle_t h;
    if (nvs_open(LENSELIFE_NVS_NAMESPACE, NVS_READWRITE, &h) != ESP_OK) {
        return;
    }

    nvs_set_blob(h, "dT_mean", &w_dT.mean, sizeof(float));
    nvs_set_blob(h, "dT_m2", &w_dT.M2, sizeof(float));
    nvs_set_i32(h, "dT_cnt", w_dT.count);
    nvs_set_blob(h, "pH_mean", &w_pH.mean, sizeof(float));
    nvs_set_blob(h, "pH_m2", &w_pH.M2, sizeof(float));
    nvs_set_i32(h, "pH_cnt", w_pH.count);
    nvs_set_blob(h, "tmp_mean", &w_temp.mean, sizeof(float));
    nvs_set_blob(h, "tmp_m2", &w_temp.M2, sizeof(float));
    nvs_set_i32(h, "tmp_cnt", w_temp.count);
    nvs_commit(h);
    nvs_close(h);
}

void lenslife_welford_load(void)
{
    nvs_handle_t h;
    if (nvs_open(LENSELIFE_NVS_NAMESPACE, NVS_READONLY, &h) != ESP_OK) {
        return;
    }

    size_t sz = sizeof(float);
    nvs_get_blob(h, "dT_mean", &w_dT.mean, &sz);
    sz = sizeof(float);
    nvs_get_blob(h, "dT_m2", &w_dT.M2, &sz);
    nvs_get_i32(h, "dT_cnt", &w_dT.count);
    sz = sizeof(float);
    nvs_get_blob(h, "pH_mean", &w_pH.mean, &sz);
    sz = sizeof(float);
    nvs_get_blob(h, "pH_m2", &w_pH.M2, &sz);
    nvs_get_i32(h, "pH_cnt", &w_pH.count);
    sz = sizeof(float);
    nvs_get_blob(h, "tmp_mean", &w_temp.mean, &sz);
    sz = sizeof(float);
    nvs_get_blob(h, "tmp_m2", &w_temp.M2, &sz);
    nvs_get_i32(h, "tmp_cnt", &w_temp.count);
    nvs_close(h);
}

void lenslife_welford_update_session(float dT, float pH, float temp_c)
{
    lenslife_welford_update_session_filtered(dT, pH, temp_c, true, true);
}

void lenslife_welford_update_session_filtered(
    float dT,
    float pH,
    float temp_c,
    bool ph_valid,
    bool temp_valid)
{
    welford_update(&w_dT, dT);
    if (ph_valid) {
        welford_update(&w_pH, pH);
    }
    if (temp_valid) {
        welford_update(&w_temp, temp_c);
    }
    lenslife_welford_save();
}
