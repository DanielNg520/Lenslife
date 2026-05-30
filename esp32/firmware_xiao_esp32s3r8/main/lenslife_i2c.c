#include "lenslife_i2c.h"

#include "lenslife_pins.h"

#include "esp_log.h"

static const char *TAG = "lenslife_i2c";

static i2c_master_bus_handle_t s_bus;
static i2c_master_dev_handle_t s_ads_dev;
static bool s_ready;

bool lenslife_i2c_init(void)
{
    if (s_ready) {
        return true;
    }

    i2c_master_bus_config_t bus_cfg = {
        .i2c_port = I2C_NUM_0,
        .sda_io_num = LENSELIFE_PIN_I2C_SDA,
        .scl_io_num = LENSELIFE_PIN_I2C_SCL,
        .clk_source = I2C_CLK_SRC_DEFAULT,
        .glitch_ignore_cnt = 7,
        .flags.enable_internal_pullup = true,
    };

    esp_err_t err = i2c_new_master_bus(&bus_cfg, &s_bus);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "i2c bus init failed: %s", esp_err_to_name(err));
        return false;
    }

    i2c_device_config_t ads_cfg = {
        .dev_addr_length = I2C_ADDR_BIT_LEN_7,
        .device_address = LENSELIFE_ADS1115_ADDR,
        .scl_speed_hz = LENSELIFE_I2C_FREQ_HZ,
    };
    err = i2c_master_bus_add_device(s_bus, &ads_cfg, &s_ads_dev);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "ADS1115 dev add failed: %s", esp_err_to_name(err));
        return false;
    }

    s_ready = true;
    ESP_LOGI(TAG, "I2C ready D4/SDA=%d D5/SCL=%d @ %lu Hz (ADS1115 0x%02X)",
             LENSELIFE_PIN_I2C_SDA, LENSELIFE_PIN_I2C_SCL,
             (unsigned long)LENSELIFE_I2C_FREQ_HZ, LENSELIFE_ADS1115_ADDR);
    return true;
}

i2c_master_bus_handle_t lenslife_i2c_bus(void)
{
    return s_bus;
}

i2c_master_dev_handle_t lenslife_i2c_dev(uint8_t addr_7bit)
{
    if (addr_7bit == LENSELIFE_ADS1115_ADDR) {
        return s_ads_dev;
    }
    return NULL;
}
