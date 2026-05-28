#include "lenslife_rgb_status.h"

#include "lenslife_pins.h"

#include "esp_log.h"
#include "led_strip.h"

static const char *TAG = "lenslife_rgb";

static led_strip_handle_t s_strip;
static bool s_ready;

bool lenslife_rgb_init(void)
{
    if (s_ready) {
        return true;
    }

    led_strip_config_t strip_config = {
        .strip_gpio_num = LENSELIFE_PIN_RGB_WS2812,
        .max_leds = 1,
        .led_pixel_format = LED_PIXEL_FORMAT_GRB,
        .led_model = LED_MODEL_WS2812,
        .flags.invert_out = false,
    };

    led_strip_rmt_config_t rmt_config = {
        .clk_src = RMT_CLK_SRC_DEFAULT,
        .resolution_hz = 10 * 1000 * 1000,
        .flags.with_dma = false,
    };

    esp_err_t err = led_strip_new_rmt_device(&strip_config, &rmt_config, &s_strip);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "led_strip init failed on GPIO%d: %s",
                 LENSELIFE_PIN_RGB_WS2812, esp_err_to_name(err));
        return false;
    }

    lenslife_rgb_off();
    s_ready = true;
    ESP_LOGI(TAG, "DevKitC onboard WS2812 status LED on GPIO%d", LENSELIFE_PIN_RGB_WS2812);
    return true;
}

static void set_rgb(uint8_t r, uint8_t g, uint8_t b)
{
    if (!s_ready || !s_strip) {
        return;
    }
    led_strip_set_pixel(s_strip, 0, r, g, b);
    led_strip_refresh(s_strip);
}

void lenslife_rgb_show_phase0(lenslife_phase0_state_t state)
{
    if (!s_ready && !lenslife_rgb_init()) {
        return;
    }

    switch (state) {
    case LENSELIFE_PHASE0_SAFE:
        ESP_LOGI(TAG, "RGB signal: GREEN (safe)");
        set_rgb(0, 255, 0);
        break;
    case LENSELIFE_PHASE0_REPLACE_SOON:
        ESP_LOGI(TAG, "RGB signal: RED (replace soon / fouling)");
        set_rgb(255, 0, 0);
        break;
    case LENSELIFE_PHASE0_ANOMALY:
        ESP_LOGI(TAG, "RGB signal: ORANGE (anomaly detected)");
        set_rgb(255, 128, 0);
        break;
    case LENSELIFE_PHASE0_PH_RISK:
    default:
        ESP_LOGI(TAG, "RGB signal: YELLOW (pH risk)");
        set_rgb(255, 200, 0);
        break;
    }
}

void lenslife_rgb_show_connecting(void)
{
    if (!s_ready && !lenslife_rgb_init()) {
        return;
    }
    ESP_LOGI(TAG, "RGB signal: BLUE (BLE advertising)");
    set_rgb(0, 0, 255);
}

void lenslife_rgb_off(void)
{
    if (!s_strip) {
        return;
    }
    led_strip_clear(s_strip);
    led_strip_refresh(s_strip);
}
