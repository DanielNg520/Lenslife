#include "lenslife_power.h"

#include "lenslife_actuators.h"
#include "lenslife_pins.h"
#include "lenslife_rgb_status.h"

#include "driver/gpio.h"
#include "esp_log.h"
#include "esp_sleep.h"

static const char *TAG = "lenslife_power";

void lenslife_power_configure_button_wake(void)
{
    gpio_config_t cfg = {
        .pin_bit_mask = 1ULL << LENSELIFE_PIN_BUTTON,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&cfg);
}

void lenslife_power_configure_reed_wake(void)
{
    lenslife_power_configure_button_wake();
}

void lenslife_power_enter_deep_sleep(void)
{
    lenslife_ir_led_set(false);
    lenslife_vibration_set(false);
    lenslife_rgb_off();

    lenslife_power_configure_button_wake();

#if LENSELIFE_BUTTON_USE_LIGHT_SLEEP_WAKE
    /*
     * GPIO44 (D7) is not an RTC GPIO — EXT1 deep-sleep wake is unavailable.
     * Light sleep + GPIO wake returns here when the button is pressed.
     */
    gpio_wakeup_enable(LENSELIFE_PIN_BUTTON, GPIO_INTR_LOW_LEVEL);
    esp_sleep_enable_gpio_wakeup();
    ESP_LOGI(TAG, "light sleep — press button on D7 (GPIO%d) to start next cycle",
             LENSELIFE_PIN_BUTTON);
    esp_light_sleep_start();
    gpio_wakeup_disable(LENSELIFE_PIN_BUTTON);
    esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_GPIO);
#else
#if CONFIG_IDF_TARGET_ESP32S3
    esp_sleep_enable_ext1_wakeup_io(1ULL << LENSELIFE_PIN_BUTTON, ESP_EXT1_WAKEUP_ANY_LOW);
#else
    esp_sleep_enable_ext0_wakeup(LENSELIFE_PIN_BUTTON, 0);
#endif
    ESP_LOGI(TAG, "deep sleep — next wake on button GPIO%d", LENSELIFE_PIN_BUTTON);
    esp_deep_sleep_start();
#endif
}
