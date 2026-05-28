#include "lenslife_ds18b20.h"

#include "lenslife_pins.h"

#include "driver/gpio.h"
#include "esp_log.h"
#include "esp_rom_sys.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "lenslife_ds18b20";

#define OW_CMD_SKIP_ROM     0xCC
#define OW_CMD_CONVERT_T    0x44
#define OW_CMD_READ_SCRATCH 0xBE

static gpio_num_t s_pin = LENSELIFE_PIN_ONEWIRE;

static void ow_drive_low(void)
{
    gpio_set_direction(s_pin, GPIO_MODE_OUTPUT);
    gpio_set_level(s_pin, 0);
}

static void ow_release(void)
{
    gpio_set_direction(s_pin, GPIO_MODE_INPUT);
    gpio_set_pull_mode(s_pin, GPIO_PULLUP_ONLY);
}

static bool ow_reset(void)
{
    ow_drive_low();
    esp_rom_delay_us(480);
    ow_release();
    esp_rom_delay_us(70);
    bool presence = gpio_get_level(s_pin) == 0;
    esp_rom_delay_us(410);
    return presence;
}

static void ow_write_bit(int bit)
{
    ow_drive_low();
    if (bit) {
        esp_rom_delay_us(6);
        ow_release();
        esp_rom_delay_us(64);
    } else {
        esp_rom_delay_us(60);
        ow_release();
        esp_rom_delay_us(10);
    }
}

static int ow_read_bit(void)
{
    int bit = 0;
    ow_drive_low();
    esp_rom_delay_us(3);
    ow_release();
    esp_rom_delay_us(10);
    bit = gpio_get_level(s_pin);
    esp_rom_delay_us(55);
    return bit;
}

static void ow_write_byte(uint8_t byte)
{
    for (int i = 0; i < 8; i++) {
        ow_write_bit(byte & 0x01);
        byte >>= 1;
    }
}

static uint8_t ow_read_byte(void)
{
    uint8_t value = 0;
    for (int i = 0; i < 8; i++) {
        value >>= 1;
        if (ow_read_bit()) {
            value |= 0x80;
        }
    }
    return value;
}

bool lenslife_ds18b20_init(void)
{
    gpio_config_t cfg = {
        .pin_bit_mask = 1ULL << s_pin,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    esp_err_t err = gpio_config(&cfg);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "gpio config failed");
        return false;
    }
    return true;
}

bool lenslife_ds18b20_read_celsius(float *temp_out)
{
    if (!ow_reset()) {
        ESP_LOGW(TAG, "no DS18B20 presence");
        return false;
    }

    ow_write_byte(OW_CMD_SKIP_ROM);
    ow_write_byte(OW_CMD_CONVERT_T);
    vTaskDelay(pdMS_TO_TICKS(750));

    if (!ow_reset()) {
        return false;
    }

    ow_write_byte(OW_CMD_SKIP_ROM);
    ow_write_byte(OW_CMD_READ_SCRATCH);

    uint8_t scratch[9];
    for (int i = 0; i < 9; i++) {
        scratch[i] = ow_read_byte();
    }

    int16_t raw = (int16_t)(scratch[1] << 8 | scratch[0]);
    *temp_out = (float)raw / 16.0f;
    return true;
}
