#include "lenslife_battery.h"

#include "lenslife_pins.h"

#include "esp_adc/adc_oneshot.h"
#include "esp_log.h"

static const char *TAG = "lenslife_battery";

static adc_oneshot_unit_handle_t s_adc;
static adc_channel_t s_channel;
static bool s_ready;

bool lenslife_battery_init(void)
{
    adc_unit_t unit_id;
    if (adc_oneshot_io_to_channel(LENSELIFE_PIN_BATTERY_ADC, &unit_id, &s_channel) != ESP_OK) {
        ESP_LOGW(TAG, "battery ADC GPIO%d unsupported", LENSELIFE_PIN_BATTERY_ADC);
        return false;
    }

    adc_oneshot_unit_init_cfg_t unit_cfg = {
        .unit_id = unit_id,
    };
    if (adc_oneshot_new_unit(&unit_cfg, &s_adc) != ESP_OK) {
        ESP_LOGW(TAG, "battery ADC unit init failed");
        return false;
    }

    adc_oneshot_chan_cfg_t chan_cfg = {
        .bitwidth = ADC_BITWIDTH_DEFAULT,
        .atten = ADC_ATTEN_DB_12,
    };
    if (adc_oneshot_config_channel(s_adc, s_channel, &chan_cfg) != ESP_OK) {
        ESP_LOGW(TAG, "battery ADC channel config failed");
        return false;
    }

    s_ready = true;
    ESP_LOGI(TAG, "battery ADC ready on GPIO%d", LENSELIFE_PIN_BATTERY_ADC);
    return true;
}

bool lenslife_battery_read_volts(float *volts_out)
{
    if (!s_ready || !volts_out) {
        return false;
    }

    int raw = 0;
    if (adc_oneshot_read(s_adc, s_channel, &raw) != ESP_OK) {
        return false;
    }

    *volts_out = ((float)raw / 4095.0f) * 3.3f;
    return true;
}
