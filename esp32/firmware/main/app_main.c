#include "lenslife_ble.h"
#include "lenslife_nvs.h"
#include "lenslife_pins.h"
#include "lenslife_sensor.h"

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "host/ble_hs.h"

static const char *TAG = "lenslife_main";

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

void app_main(void)
{
    ESP_LOGI(TAG, "LensLife ESP32-S3 BLE ONLY TEST MODE");

    if (!lenslife_nvs_init()) {
        ESP_LOGE(TAG, "NVS init failed");
        return;
    }

    if (!lenslife_ble_init()) {
        ESP_LOGE(TAG, "NimBLE init failed");
        return;
    }

    if (!wait_ble_host_sync(5000)) {
        ESP_LOGE(TAG, "BLE host did not sync");
        return;
    }

    lenslife_sensor_frame_t frame = {0};

    frame.values.deltaT_fouling = 0.0f;
    frame.values.deltaT_residual = 0.0f;
    frame.values.ph_corrected = 0.0f;
    frame.values.temp_celsius = 0.0f;
    frame.values.t_blank = 0.0f;

    frame.kill_condition = false;
    frame.ph_risk = false;
    frame.temp_valid = false;
    frame.blank_stale = true;

    ESP_LOGI(TAG, "BLE advertising as %s", LENSELIFE_BLE_DEVICE_NAME);

    //lenslife_ble_wait_and_notify(&frame, LENSELIFE_BLE_WAIT_MS);

    ESP_LOGI(TAG, "BLE test finished. Staying awake.");
    while (true) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}