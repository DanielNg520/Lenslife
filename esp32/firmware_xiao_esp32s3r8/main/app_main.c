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
 *
 * XIAO perfboard: common-cathode RGB on D1–D3, button D7, IR D9, motor D10.
 * USB Serial/JTAG for logs. GPIO44 uses light-sleep wake (not deep-sleep EXT1).
 */

static bool wait_for_button_press(uint32_t timeout_ms)
{
    const TickType_t deadline = xTaskGetTickCount() + pdMS_TO_TICKS(timeout_ms);
    while (xTaskGetTickCount() < deadline) {
        if (lenslife_button_is_pressed()) {
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

static bool run_measurement_cycle(void)
{
    if (!lenslife_measure_init_hardware()) {
        ESP_LOGE(TAG, "hardware init failed");
        return false;
    }

    lenslife_sensor_frame_t frame = {0};
    if (!lenslife_measure_run_cycle(&frame)) {
        ESP_LOGE(TAG, "measurement cycle failed");
        return false;
    }

    if (!lenslife_ble_init()) {
        ESP_LOGE(TAG, "NimBLE init failed");
        return false;
    }

    if (!wait_ble_host_sync(5000)) {
        ESP_LOGE(TAG, "BLE host did not sync");
        return false;
    }

    lenslife_rgb_show_connecting();
    lenslife_ble_wait_and_notify(&frame, LENSELIFE_BLE_WAIT_MS);
    lenslife_measure_increment_session_count();

    lenslife_ble_stop();
    if (lenslife_hw_caps()->rgb_ok) {
        lenslife_rgb_show_phase0(lenslife_sensor_phase0_state(&frame));
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
    return true;
}

void app_main(void)
{
    esp_sleep_wakeup_cause_t wake = esp_sleep_get_wakeup_cause();
    ESP_LOGI(TAG, "LensLife XIAO boot, wake cause=%d", wake);

    if (!lenslife_nvs_init()) {
        ESP_LOGE(TAG, "NVS init failed");
        lenslife_power_enter_deep_sleep();
    }
    lenslife_actuators_init();

    for (;;) {
        esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();

        if (cause == ESP_SLEEP_WAKEUP_GPIO) {
            ESP_LOGI(TAG, "button wake — starting measurement");
        } else if (cause == ESP_SLEEP_WAKEUP_UNDEFINED) {
            ESP_LOGI(TAG, "cold boot — press button on D7 (GPIO%d)",
                     LENSELIFE_PIN_BUTTON);
            if (!wait_for_button_press(LENSELIFE_BUTTON_WAIT_MS)) {
                ESP_LOGW(TAG, "no button press — sleeping");
                lenslife_power_enter_deep_sleep();
                continue;
            }
        } else {
            ESP_LOGW(TAG, "unexpected wake %d — waiting for button", cause);
            if (!wait_for_button_press(LENSELIFE_BUTTON_WAIT_MS)) {
                lenslife_power_enter_deep_sleep();
                continue;
            }
        }

        if (!lenslife_button_is_pressed()) {
            ESP_LOGW(TAG, "button released — hold to confirm or press again");
            if (!wait_for_button_press(5000)) {
                lenslife_power_enter_deep_sleep();
                continue;
            }
        }

        if (!run_measurement_cycle()) {
            lenslife_power_enter_deep_sleep();
            continue;
        }

        lenslife_power_enter_deep_sleep();
    }
}
