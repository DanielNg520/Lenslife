#include "lenslife_measure.h"

#include <sys/time.h>
#include <time.h>

#include "lenslife_hw.h"
#include "lenslife_i2c.h"
#include "lenslife_actuators.h"
#include "lenslife_ads1115.h"
#include "lenslife_nvs.h"
#include "lenslife_pins.h"
#include "lenslife_rgb_status.h"
#include "ml/lenslife_classify.h"
#include "ml/lenslife_ml.h"

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "lenslife_measure";

static float s_t_blank;
static uint32_t s_blank_timestamp;
static uint32_t s_session_count;

static bool read_ir_volts(float *volts)
{
    lenslife_ir_led_set(true);
    vTaskDelay(pdMS_TO_TICKS(5));
    bool ok = lenslife_ads1115_read_volts(LENSELIFE_ADS_CH_A1, volts);
    lenslife_ir_led_set(false);
    return ok;
}

static void wait_ph_settle(void)
{
    const TickType_t deadline = xTaskGetTickCount() + pdMS_TO_TICKS(LENSELIFE_PH_SETTLE_MS);
    while (xTaskGetTickCount() < deadline) {
        if (!lenslife_button_is_pressed()) {
            ESP_LOGI(TAG, "pH settle done (button released)");
            return;
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }
    ESP_LOGI(TAG, "pH settle timeout (%d ms)", LENSELIFE_PH_SETTLE_MS);
}

bool lenslife_measure_init_hardware(void)
{
    if (!lenslife_nvs_init()) {
        return false;
    }

    lenslife_nvs_read_float("t_blank", &s_t_blank, 1.0f);
    lenslife_nvs_read_u32("blank_timestamp", &s_blank_timestamp, 0);
    lenslife_nvs_read_u32("session_count", &s_session_count, 0);
    lenslife_welford_load();

    ESP_LOGI(TAG, "NVS t_blank=%.4f blank_ts=%lu session_count=%lu",
             s_t_blank, (unsigned long)s_blank_timestamp, (unsigned long)s_session_count);

    lenslife_hw_probe();

    const lenslife_hw_caps_t *caps = lenslife_hw_caps();
    if (!caps->ir_ok) {
        ESP_LOGE(TAG, "IR path not available — cannot run fouling measurements");
        return false;
    }

    if (!caps->motor_ok) {
        ESP_LOGW(TAG, "Vibration motor unavailable — cycle will skip cleaning vibration");
    }
    if (!caps->battery_ok) {
        ESP_LOGW(TAG, "Battery monitor unavailable — runtime continues without VBAT telemetry");
    }
    if (!caps->ph_hw) {
        ESP_LOGW(TAG, "pH channel not detected — IR-only / degraded mode");
    }
    if (!caps->temp_hw) {
        ESP_LOGW(TAG, "Temperature sensor not detected — using 25 C default");
    }
    if (!caps->rgb_ok) {
        ESP_LOGW(TAG, "RGB status LED unavailable");
    }

    return true;
}

bool lenslife_measure_acquire_blank(void)
{
    const lenslife_hw_caps_t *caps = lenslife_hw_caps();
    if (!caps->ir_ok) {
        ESP_LOGE(TAG, "Cannot acquire T_blank without IR channel");
        return false;
    }

    float volts = 0.0f;
    if (!read_ir_volts(&volts)) {
        return false;
    }

    s_t_blank = volts;
    s_blank_timestamp = (uint32_t)time(NULL);
    lenslife_nvs_write_float("t_blank", s_t_blank);
    lenslife_nvs_write_u32("blank_timestamp", s_blank_timestamp);
    ESP_LOGI(TAG, "T_blank acquired %.4f V", s_t_blank);
    return true;
}

bool lenslife_measure_run_cycle(lenslife_sensor_frame_t *frame_out)
{
    const lenslife_hw_caps_t *caps = lenslife_hw_caps();
    float t_pre = 0.0f;
    float t_post = 0.0f;
    float ph_raw = 0.0f;
    float temp_c = 25.0f;
    bool ph_valid = false;
    bool ir_valid = false;
    bool temp_valid = false;

    if (!caps->ir_ok) {
        ESP_LOGE(TAG, "IR path unavailable — aborting cycle");
        return false;
    }

    if (!read_ir_volts(&t_pre)) {
        ESP_LOGE(TAG, "T_pre read failed");
        return false;
    }

    if (caps->motor_ok) {
        lenslife_vibration_run_ms(LENSELIFE_VIBRATION_MS);
    } else {
        ESP_LOGW(TAG, "Skipping vibration (motor unavailable)");
    }

    if (!read_ir_volts(&t_post)) {
        ESP_LOGE(TAG, "T_post read failed");
        return false;
    }
    ir_valid = true;

    if (!temp_valid) {
        temp_c = 25.0f;
    }

    if (caps->ph_hw) {
        wait_ph_settle();
        if (lenslife_ads1115_read_volts(LENSELIFE_ADS_CH_A0, &ph_raw)) {
            ph_valid = ph_raw >= LENSELIFE_PH_PROBE_V_MIN &&
                       ph_raw <= LENSELIFE_PH_PROBE_V_MAX;
            if (!ph_valid) {
                ESP_LOGW(TAG, "pH read %.4f V outside probe window — ignoring", ph_raw);
            }
        } else {
            ESP_LOGW(TAG, "pH read failed this cycle — continuing IR-only");
        }
    } else {
        ESP_LOGD(TAG, "pH hardware not present — skipping settle and A0 read");
    }

    lenslife_sensor_compute(
        t_pre, t_post, ph_raw, temp_c, s_t_blank, ph_valid, &frame_out->values);

    frame_out->ir_valid = ir_valid;
    frame_out->ph_valid = ph_valid;
    frame_out->temp_valid = temp_valid;
    frame_out->kill_condition = frame_out->values.deltaT_fouling > LENSELIFE_DELTAT_KILL;
    frame_out->ph_risk = ph_valid &&
                          (frame_out->values.ph_corrected < LENSELIFE_PH_LOW ||
                           frame_out->values.ph_corrected > LENSELIFE_PH_HIGH);

    frame_out->anomaly_score = lenslife_anomaly_score_filtered(
        frame_out->values.deltaT_fouling,
        frame_out->values.ph_corrected,
        frame_out->values.temp_celsius,
        ph_valid,
        temp_valid);

    lenslife_welford_update_session_filtered(
        frame_out->values.deltaT_fouling,
        frame_out->values.ph_corrected,
        frame_out->values.temp_celsius,
        ph_valid,
        temp_valid);

    frame_out->classify_result = (uint8_t)lenslife_classify(
        frame_out->values.deltaT_fouling,
        frame_out->values.ph_corrected,
        frame_out->values.temp_celsius,
        (int)s_session_count,
        ph_valid);

    uint32_t now = (uint32_t)time(NULL);
    if (s_blank_timestamp == 0 || now < s_blank_timestamp) {
        frame_out->blank_stale = true;
    } else {
        frame_out->blank_stale = (now - s_blank_timestamp) > LENSELIFE_BLANK_STALE_SEC;
    }

    lenslife_phase0_state_t phase0 = lenslife_sensor_phase0_state(frame_out);
    ESP_LOGI(TAG,
             "Phase 0: %s (ir=%d ph=%d temp=%d)",
             lenslife_phase0_label(phase0),
             ir_valid, ph_valid, temp_valid);
    if (lenslife_hw_caps()->rgb_ok) {
        lenslife_rgb_show_phase0(phase0);
        vTaskDelay(pdMS_TO_TICKS(LENSELIFE_RGB_DISPLAY_MS));
    }

    ESP_LOGI(TAG,
             "deltaT_fouling=%.4f deltaT_residual=%.4f pH=%.2f temp=%.1f blank=%.4f z=%.2f",
             frame_out->values.deltaT_fouling, frame_out->values.deltaT_residual,
             frame_out->values.ph_corrected, frame_out->values.temp_celsius,
             frame_out->values.t_blank, frame_out->anomaly_score);

    return true;
}

void lenslife_measure_increment_session_count(void)
{
    s_session_count++;
    lenslife_nvs_write_u32("session_count", s_session_count);
}
