#include "lenslife_ads1115.h"

#include <stdint.h>

#include "lenslife_i2c.h"
#include "lenslife_pins.h"

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "lenslife_ads1115";

#define ADS1115_REG_CONVERSION 0x00
#define ADS1115_REG_CONFIG     0x01

#define ADS1115_OS_SINGLE      0x8000
#define ADS1115_MUX_AIN0_GND   0x4000
#define ADS1115_MUX_AIN1_GND   0x5000
#define ADS1115_PGA_4_096V     0x0200
#define ADS1115_MODE_SINGLE    0x0100
#define ADS1115_DR_128SPS      0x0080
#define ADS1115_COMP_DISABLE   0x0003

static i2c_master_dev_handle_t s_dev;

static bool write_reg16(uint8_t reg, uint16_t value)
{
    uint8_t buf[3] = {reg, (uint8_t)(value >> 8), (uint8_t)(value & 0xFF)};
    return i2c_master_transmit(s_dev, buf, sizeof(buf), 50) == ESP_OK;
}

static bool read_reg16(uint8_t reg, int16_t *out)
{
    uint8_t reg_addr = reg;
    uint8_t data[2];
    if (i2c_master_transmit_receive(s_dev, &reg_addr, 1, data, 2, 100) != ESP_OK) {
        return false;
    }
    *out = (int16_t)((data[0] << 8) | data[1]);
    return true;
}

bool lenslife_ads1115_init(void)
{
    if (!lenslife_i2c_init()) {
        return false;
    }
    s_dev = lenslife_i2c_dev(LENSELIFE_ADS1115_ADDR);
    return s_dev != NULL;
}

bool lenslife_ads1115_read_volts(lenslife_ads_channel_t channel, float *volts_out)
{
    uint16_t mux = (channel == LENSELIFE_ADS_CH_A0) ? ADS1115_MUX_AIN0_GND : ADS1115_MUX_AIN1_GND;
    uint16_t cfg = ADS1115_OS_SINGLE | mux | ADS1115_PGA_4_096V | ADS1115_MODE_SINGLE |
                   ADS1115_DR_128SPS | ADS1115_COMP_DISABLE;

    if (!write_reg16(ADS1115_REG_CONFIG, cfg)) {
        ESP_LOGE(TAG, "config write failed ch=%d", channel);
        return false;
    }

    vTaskDelay(pdMS_TO_TICKS(10));

    int16_t raw = 0;
    if (!read_reg16(ADS1115_REG_CONVERSION, &raw)) {
        ESP_LOGE(TAG, "conversion read failed ch=%d", channel);
        return false;
    }

    *volts_out = (float)raw * (4.096f / 32768.0f);
    return true;
}
