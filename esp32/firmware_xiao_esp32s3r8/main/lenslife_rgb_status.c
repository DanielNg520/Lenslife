#include "lenslife_rgb_status.h"

#include "lenslife_pins.h"

#include "driver/gpio.h"
#include "esp_log.h"

static const char *TAG = "lenslife_rgb";

static bool s_ready;

static void drive_rgb(bool r, bool g, bool b)
{
    gpio_set_level(LENSELIFE_PIN_RGB_RED, r ? 1 : 0);
    gpio_set_level(LENSELIFE_PIN_RGB_GREEN, g ? 1 : 0);
    gpio_set_level(LENSELIFE_PIN_RGB_BLUE, b ? 1 : 0);
}

bool lenslife_rgb_init(void)
{
    if (s_ready) {
        return true;
    }

    uint64_t mask = (1ULL << LENSELIFE_PIN_RGB_RED) | (1ULL << LENSELIFE_PIN_RGB_GREEN) |
                    (1ULL << LENSELIFE_PIN_RGB_BLUE);

    gpio_config_t cfg = {
        .pin_bit_mask = mask,
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    if (gpio_config(&cfg) != ESP_OK) {
        ESP_LOGE(TAG, "RGB GPIO config failed");
        return false;
    }

    s_ready = true;
    lenslife_rgb_off();
    ESP_LOGI(TAG, "common-cathode RGB on D1/D2/D3 (GPIO %d/%d/%d)",
             LENSELIFE_PIN_RGB_RED, LENSELIFE_PIN_RGB_GREEN, LENSELIFE_PIN_RGB_BLUE);
    return true;
}

void lenslife_rgb_show_phase0(lenslife_phase0_state_t state)
{
    if (!s_ready && !lenslife_rgb_init()) {
        return;
    }

    switch (state) {
    case LENSELIFE_PHASE0_SAFE:
        ESP_LOGI(TAG, "RGB: GREEN (safe)");
        drive_rgb(false, true, false);
        break;
    case LENSELIFE_PHASE0_REPLACE_SOON:
        ESP_LOGI(TAG, "RGB: RED (replace soon / fouling)");
        drive_rgb(true, false, false);
        break;
    case LENSELIFE_PHASE0_ANOMALY:
        ESP_LOGI(TAG, "RGB: ORANGE (anomaly — red+green)");
        drive_rgb(true, true, false);
        break;
    case LENSELIFE_PHASE0_PH_RISK:
    default:
        ESP_LOGI(TAG, "RGB: YELLOW (pH risk — red+green)");
        drive_rgb(true, true, false);
        break;
    }
}

void lenslife_rgb_show_connecting(void)
{
    if (!s_ready && !lenslife_rgb_init()) {
        return;
    }
    ESP_LOGI(TAG, "RGB: BLUE (BLE advertising)");
    drive_rgb(false, false, true);
}

void lenslife_rgb_off(void)
{
    if (!s_ready) {
        return;
    }
    drive_rgb(false, false, false);
}
