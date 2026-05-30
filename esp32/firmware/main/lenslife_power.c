#include "lenslife_power.h"

#include "lenslife_actuators.h"
#include "lenslife_pins.h"
#include "lenslife_rgb_status.h"

#include "driver/gpio.h"
#include "esp_log.h"
#include "esp_sleep.h"

static const char *TAG = "lenslife_power";

void lenslife_power_configure_reed_wake(void)
{
    gpio_config_t cfg = {
        .pin_bit_mask = 1ULL << LENSELIFE_PIN_REED_SWITCH,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&cfg);
}

void lenslife_power_enter_deep_sleep(void)
{
    lenslife_ir_led_set(false);
    lenslife_vibration_set(false);
    lenslife_rgb_off();

    lenslife_power_configure_reed_wake();

#if CONFIG_IDF_TARGET_ESP32S3
    gpio_wakeup_enable(LENSELIFE_PIN_REED_SWITCH, GPIO_INTR_LOW_LEVEL);
    esp_sleep_enable_gpio_wakeup();
#else
    esp_sleep_enable_ext0_wakeup(LENSELIFE_PIN_REED_SWITCH, 0);
#endif

    ESP_LOGI(TAG, "deep sleep — next wake on reed GPIO%d (lid close)", LENSELIFE_PIN_REED_SWITCH);
    esp_deep_sleep_start();
}
