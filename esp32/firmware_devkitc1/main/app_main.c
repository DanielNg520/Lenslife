#include "lenslife_actuators.h"
#include "lenslife_ble.h"
#include "lenslife_hw.h"
#include "lenslife_measure.h"
#include "lenslife_nvs.h"
#include "lenslife_pins.h"
#include "lenslife_power.h"
#include "lenslife_rgb_status.h"
#include "lenslife_sensor.h"

#include "esp_log.h"
#include "esp_sleep.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "host/ble_hs.h"

static const char *TAG = "lenslife_main";

/*
 * WiFi disabled by design. FL sync is Flutter's responsibility via phone WiFi.
 * Do not initialize esp_wifi or nvs_flash wifi entries.
 *
 * Onboard WS2812 (GPIO48): green / yellow / red case status + blue while BLE advertising.
 */

static bool wait_for_reed_close(uint32_t timeout_ms)
{
    const TickType_t deadline = xTaskGetTickCount() + pdMS_TO_TICKS(timeout_ms);
    while (xTaskGetTickCount() < deadline) {
        if (lenslife_reed_is_closed()) {
            return true;
        }
        vTaskDelay(pdMS_TO_TICKS(50));
    }
    return false;
}

static bool wait_ble_host_sync(uint32_t timeout_ms)
{
    const TickType_t deadline = xTaskGetTickCount() + pdMS_TO_TICKS(timeout_ms);
    while (xTaskGetTickCount() < deadline) {
        if (ble_hs_synced()) {
            return true;
        }
        vTaskDelay(pdMS_TO_TICKS(20));
    }
    return false;
}

static bool woke_from_reed(void)
{
    esp_sleep_wakeup_cause_t wake = esp_sleep_get_wakeup_cause();
#if CONFIG_IDF_TARGET_ESP32S3
    return wake == ESP_SLEEP_WAKEUP_EXT1;
#else
    return wake == ESP_SLEEP_WAKEUP_EXT0;
#endif
}

void app_main(void)
{
    esp_sleep_wakeup_cause_t wake = esp_sleep_get_wakeup_cause();
    ESP_LOGI(TAG, "LensLife ESP32-S3 boot, wake cause=%d", wake);

    if (!lenslife_nvs_init()) {
        ESP_LOGE(TAG, "NVS init failed");
        lenslife_power_enter_deep_sleep();
    }
    lenslife_actuators_init();

    if (woke_from_reed()) {
        ESP_LOGI(TAG, "reed wake — lid closed, starting measurement");
    } else if (wake == ESP_SLEEP_WAKEUP_UNDEFINED) {
        ESP_LOGI(TAG, "cold boot — waiting for lid close (reed GPIO%d)",
                 LENSELIFE_PIN_REED_SWITCH);
        if (!wait_for_reed_close(LENSELIFE_REED_WAIT_MS)) {
            ESP_LOGW(TAG, "lid not closed — sleeping");
            lenslife_power_enter_deep_sleep();
        }
    } else {
        ESP_LOGW(TAG, "unexpected wake — sleeping");
        lenslife_power_enter_deep_sleep();
    }

    if (!lenslife_reed_is_closed()) {
        ESP_LOGW(TAG, "reed open — abort cycle");
        lenslife_power_enter_deep_sleep();
    }

    if (!lenslife_measure_init_hardware()) {
        ESP_LOGE(TAG, "hardware init failed");
        lenslife_power_enter_deep_sleep();
    }

    lenslife_sensor_frame_t frame = {0};
    if (!lenslife_measure_run_cycle(&frame)) {
        ESP_LOGE(TAG, "measurement cycle failed");
        lenslife_power_enter_deep_sleep();
    }

    if (!lenslife_ble_init()) {
        ESP_LOGE(TAG, "NimBLE init failed");
        lenslife_power_enter_deep_sleep();
    }

    if (!wait_ble_host_sync(5000)) {
        ESP_LOGE(TAG, "BLE host did not sync");
        lenslife_power_enter_deep_sleep();
    }

    lenslife_rgb_show_connecting();
    lenslife_ble_wait_and_notify(&frame, LENSELIFE_BLE_WAIT_MS);
    lenslife_measure_increment_session_count();

    lenslife_ble_stop();
    if (lenslife_hw_caps()->rgb_ok) {
        lenslife_rgb_show_phase0(lenslife_sensor_phase0_state(&frame));
        vTaskDelay(pdMS_TO_TICKS(2000));
    }

    lenslife_power_enter_deep_sleep();
}
