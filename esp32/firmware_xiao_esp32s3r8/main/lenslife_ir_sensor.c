#include "lenslife_ir_sensor.h"

#include "lenslife_actuators.h"
#include "lenslife_ads1115.h"
#include "lenslife_hw.h"
#include "lenslife_pins.h"

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "freertos/task.h"

static const char *TAG = "lenslife_ir";

static SemaphoreHandle_t s_ir_lock;
static bool s_monitor_started;

static bool ensure_ir_lock(void)
{
    if (!s_ir_lock) {
        s_ir_lock = xSemaphoreCreateMutex();
    }
    return s_ir_lock != NULL;
}

bool lenslife_ir_sensor_read_volts(float *volts_out)
{
    if (!ensure_ir_lock()) {
        return false;
    }

    if (xSemaphoreTake(s_ir_lock, pdMS_TO_TICKS(1000)) != pdTRUE) {
        ESP_LOGW(TAG, "IR sample lock timeout");
        return false;
    }

    lenslife_ir_led_set(true);
    vTaskDelay(pdMS_TO_TICKS(5));
    bool ok = lenslife_ads1115_read_volts(LENSELIFE_ADS_CH_A1, volts_out);
    lenslife_ir_led_set(false);

    xSemaphoreGive(s_ir_lock);
    return ok;
}

static void ir_monitor_task(void *param)
{
    (void)param;

    for (;;) {
        const lenslife_hw_caps_t *caps = lenslife_hw_caps();
        if (caps->ir_ok) {
            float volts = 0.0f;
            if (lenslife_ir_sensor_read_volts(&volts)) {
                ESP_LOGI(TAG, "IR_MONITOR A1=%.4f V", volts);
            } else {
                ESP_LOGW(TAG, "IR_MONITOR read failed");
            }
        }
        vTaskDelay(pdMS_TO_TICKS(LENSELIFE_IR_MONITOR_MS));
    }
}

void lenslife_ir_monitor_start(void)
{
#if LENSELIFE_USE_IR_MONITOR
    if (s_monitor_started) {
        return;
    }

    if (!ensure_ir_lock()) {
        ESP_LOGW(TAG, "IR monitor disabled — lock unavailable");
        return;
    }

    BaseType_t ok = xTaskCreate(ir_monitor_task, "ir_monitor", 4096, NULL, 4, NULL);
    if (ok == pdPASS) {
        s_monitor_started = true;
        ESP_LOGI(TAG, "IR serial monitor stream every %d ms", LENSELIFE_IR_MONITOR_MS);
    } else {
        ESP_LOGW(TAG, "IR monitor task start failed");
    }
#endif
}
