#include "lenslife_hw.h"

#include "lenslife_actuators.h"
#include "lenslife_ads1115.h"
#include "lenslife_ds18b20.h"
#include "lenslife_i2c.h"
#include "lenslife_nvs.h"
#include "lenslife_pins.h"
#include "lenslife_rgb_status.h"

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "lenslife_hw";

static lenslife_hw_caps_t s_caps;

const lenslife_hw_caps_t *lenslife_hw_caps(void)
{
    return &s_caps;
}

static bool probe_ir_channel(void)
{
    float volts = 0.0f;
    lenslife_ir_led_set(true);
    vTaskDelay(pdMS_TO_TICKS(5));
    bool ok = lenslife_ads1115_read_volts(LENSELIFE_ADS_CH_A1, &volts);
    lenslife_ir_led_set(false);
    if (ok) {
        ESP_LOGI(TAG, "IR channel probe A1=%.4f V", volts);
    } else {
        ESP_LOGW(TAG, "IR channel probe failed (A1)");
    }
    return ok;
}

static bool probe_ph_channel(uint32_t ph_mode)
{
    if (ph_mode == LENSELIFE_PH_MODE_FORCE_OFF) {
        ESP_LOGI(TAG, "pH forced off (NVS ph_mode)");
        return false;
    }

    float volts = 0.0f;
    if (!lenslife_ads1115_read_volts(LENSELIFE_ADS_CH_A0, &volts)) {
        ESP_LOGW(TAG, "pH channel probe: A0 read failed");
        return ph_mode == LENSELIFE_PH_MODE_FORCE_ON;
    }

    bool in_range = volts >= LENSELIFE_PH_PROBE_V_MIN && volts <= LENSELIFE_PH_PROBE_V_MAX;
    ESP_LOGI(TAG, "pH channel probe A0=%.4f V in_range=%d", volts, in_range);

    if (ph_mode == LENSELIFE_PH_MODE_FORCE_ON) {
        return true;
    }
    return in_range;
}

static bool probe_temperature(void)
{
    float temp = 0.0f;
    bool ok = lenslife_ds18b20_read_celsius(&temp);
    if (ok) {
        ESP_LOGI(TAG, "DS18B20 probe OK (%.1f C)", temp);
    } else {
        ESP_LOGW(TAG, "DS18B20 not detected — using 25 C default");
    }
    return ok;
}

void lenslife_hw_probe(void)
{
    s_caps = (lenslife_hw_caps_t){0};

    uint32_t ph_mode = LENSELIFE_PH_MODE_AUTO;
    lenslife_nvs_read_u32("ph_mode", &ph_mode, LENSELIFE_PH_MODE_AUTO);

    s_caps.i2c_ok = lenslife_i2c_init();
    if (!s_caps.i2c_ok) {
        ESP_LOGE(TAG, "I2C unavailable — IR/pH ADC path disabled");
        return;
    }

    s_caps.ads_ok = lenslife_ads1115_init();
    if (!s_caps.ads_ok) {
        ESP_LOGE(TAG, "ADS1115 unavailable");
        return;
    }

    s_caps.ir_ok = probe_ir_channel();
    s_caps.ph_hw = s_caps.ads_ok && probe_ph_channel(ph_mode);
    s_caps.motor_ok = lenslife_actuators_init();
    s_caps.temp_hw = lenslife_ds18b20_init() && probe_temperature();
    s_caps.rgb_ok = lenslife_rgb_init();

    ESP_LOGI(TAG,
             "caps: i2c=%d ads=%d ir=%d ph=%d temp=%d motor=%d rgb=%d",
             s_caps.i2c_ok, s_caps.ads_ok, s_caps.ir_ok, s_caps.ph_hw,
             s_caps.temp_hw, s_caps.motor_ok, s_caps.rgb_ok);
}
