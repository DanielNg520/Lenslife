#include "lenslife_actuators.h"

#include "lenslife_pins.h"

#include "driver/gpio.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "lenslife_actuators";

static bool s_ready;

bool lenslife_actuators_init(void)
{
    if (s_ready) {
        return true;
    }

    uint64_t out_mask = (1ULL << LENSELIFE_PIN_IR_LED);
#if LENSELIFE_USE_VIBRATION
    out_mask |= (1ULL << LENSELIFE_PIN_VIBRATION);
#endif

    gpio_config_t out_cfg = {
        .pin_bit_mask = out_mask,
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    if (gpio_config(&out_cfg) != ESP_OK) {
        return false;
    }

#if LENSELIFE_USE_BUTTON
    gpio_config_t btn_cfg = {
        .pin_bit_mask = 1ULL << LENSELIFE_PIN_BUTTON,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    if (gpio_config(&btn_cfg) != ESP_OK) {
        return false;
    }
#endif

    lenslife_ir_led_set(false);
#if LENSELIFE_USE_VIBRATION
    lenslife_vibration_set(false);
#endif
#if LENSELIFE_USE_BUTTON
    ESP_LOGI(TAG, "IR=D9(GPIO%d) motor=D10(GPIO%d) button=D7(GPIO%d)",
             LENSELIFE_PIN_IR_LED, LENSELIFE_PIN_VIBRATION, LENSELIFE_PIN_BUTTON);
#else
    ESP_LOGI(TAG, "IR=D9(GPIO%d) motor=D10(GPIO%d) no-button auto-run",
             LENSELIFE_PIN_IR_LED, LENSELIFE_PIN_VIBRATION);
#endif
    s_ready = true;
    return true;
}

void lenslife_ir_led_set(bool on)
{
    gpio_set_level(LENSELIFE_PIN_IR_LED, on ? 1 : 0);
}

void lenslife_vibration_set(bool on)
{
#if LENSELIFE_USE_VIBRATION
    gpio_set_level(LENSELIFE_PIN_VIBRATION, on ? 1 : 0);
#else
    (void)on;
#endif
}

void lenslife_vibration_run_ms(uint32_t duration_ms)
{
    lenslife_vibration_set(true);
    vTaskDelay(pdMS_TO_TICKS(duration_ms));
    lenslife_vibration_set(false);
}

bool lenslife_button_is_pressed(void)
{
#if LENSELIFE_USE_BUTTON
    return gpio_get_level(LENSELIFE_PIN_BUTTON) == 0;
#else
    return false;
#endif
}

bool lenslife_reed_is_closed(void)
{
    return lenslife_button_is_pressed();
}
