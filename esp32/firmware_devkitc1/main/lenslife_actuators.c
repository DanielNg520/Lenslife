#include "lenslife_actuators.h"

#include "lenslife_pins.h"

#include "driver/gpio.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "lenslife_actuators";

bool lenslife_actuators_init(void)
{
    gpio_config_t out_cfg = {
        .pin_bit_mask = (1ULL << LENSELIFE_PIN_IR_LED) | (1ULL << LENSELIFE_PIN_VIBRATION),
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    if (gpio_config(&out_cfg) != ESP_OK) {
        return false;
    }

    gpio_config_t reed_cfg = {
        .pin_bit_mask = 1ULL << LENSELIFE_PIN_REED_SWITCH,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    if (gpio_config(&reed_cfg) != ESP_OK) {
        return false;
    }

    lenslife_ir_led_set(false);
    lenslife_vibration_set(false);
    ESP_LOGI(TAG, "GPIO IR=%d MOTOR=%d REED=%d RGB_WS2812=%d",
             LENSELIFE_PIN_IR_LED, LENSELIFE_PIN_VIBRATION, LENSELIFE_PIN_REED_SWITCH,
             LENSELIFE_PIN_RGB_WS2812);
    return true;
}

void lenslife_ir_led_set(bool on)
{
    gpio_set_level(LENSELIFE_PIN_IR_LED, on ? 1 : 0);
}

void lenslife_vibration_set(bool on)
{
    gpio_set_level(LENSELIFE_PIN_VIBRATION, on ? 1 : 0);
}

void lenslife_vibration_run_ms(uint32_t duration_ms)
{
    lenslife_vibration_set(true);
    vTaskDelay(pdMS_TO_TICKS(duration_ms));
    lenslife_vibration_set(false);
}

bool lenslife_reed_is_closed(void)
{
    return gpio_get_level(LENSELIFE_PIN_REED_SWITCH) == 0;
}
