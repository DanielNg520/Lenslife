#include "lenslife_nvs.h"

#include <string.h>

#include "esp_log.h"
#include "nvs.h"
#include "nvs_flash.h"

static const char *TAG = "lenslife_nvs";

bool lenslife_nvs_init(void)
{
    esp_err_t err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES || err == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    return err == ESP_OK;
}

static bool open_handle(nvs_handle_t *handle, nvs_open_mode_t mode)
{
    return nvs_open(LENSELIFE_NVS_NAMESPACE, mode, handle) == ESP_OK;
}

bool lenslife_nvs_read_float(const char *key, float *out, float default_val)
{
    nvs_handle_t handle;
    if (!open_handle(&handle, NVS_READONLY)) {
        *out = default_val;
        return false;
    }

    size_t size = sizeof(float);
    esp_err_t err = nvs_get_blob(handle, key, out, &size);
    nvs_close(handle);

    if (err != ESP_OK || size != sizeof(float)) {
        *out = default_val;
        return false;
    }
    return true;
}

bool lenslife_nvs_write_float(const char *key, float value)
{
    nvs_handle_t handle;
    if (!open_handle(&handle, NVS_READWRITE)) {
        return false;
    }

    esp_err_t err = nvs_set_blob(handle, key, &value, sizeof(value));
    if (err == ESP_OK) {
        err = nvs_commit(handle);
    }
    nvs_close(handle);
    return err == ESP_OK;
}

bool lenslife_nvs_read_u32(const char *key, uint32_t *out, uint32_t default_val)
{
    nvs_handle_t handle;
    if (!open_handle(&handle, NVS_READONLY)) {
        *out = default_val;
        return false;
    }

    esp_err_t err = nvs_get_u32(handle, key, out);
    nvs_close(handle);

    if (err != ESP_OK) {
        *out = default_val;
        return false;
    }
    return true;
}

bool lenslife_nvs_write_u32(const char *key, uint32_t value)
{
    nvs_handle_t handle;
    if (!open_handle(&handle, NVS_READWRITE)) {
        return false;
    }

    esp_err_t err = nvs_set_u32(handle, key, value);
    if (err == ESP_OK) {
        err = nvs_commit(handle);
    }
    nvs_close(handle);
    return err == ESP_OK;
}
