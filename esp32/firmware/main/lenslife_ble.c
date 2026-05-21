#include "lenslife_ble.h"

#include <string.h>

#include "lenslife_actuators.h"
#include "lenslife_measure.h"
#include "lenslife_pins.h"

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "freertos/task.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_gap.h"
#include "host/ble_gatt.h"
#include "host/ble_hs.h"
#include "host/ble_uuid.h"
#include "host/util/util.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"

static const char *TAG = "lenslife_ble";

static const ble_uuid16_t s_svc_uuid = BLE_UUID16_INIT(0xAB00);
static const ble_uuid16_t s_sensor_uuid = BLE_UUID16_INIT(0xAB01);
static const ble_uuid16_t s_status_uuid = BLE_UUID16_INIT(0xAB02);
static const ble_uuid16_t s_command_uuid = BLE_UUID16_INIT(0xAB03);

static uint16_t s_sensor_val_handle;
static uint16_t s_status_val_handle;
static uint16_t s_command_val_handle;

static uint8_t s_sensor_payload[20];
static uint8_t s_status_byte;
static lenslife_sensor_frame_t s_last_frame;

static SemaphoreHandle_t s_sync_sem;
static uint16_t s_conn_handle = BLE_HS_CONN_HANDLE_NONE;
static bool s_notify_enabled;

static int gatt_access_cb(uint16_t conn_handle, uint16_t attr_handle,
                          struct ble_gatt_access_ctxt *ctxt, void *arg);

static const struct ble_gatt_svc_def s_gatt_svcs[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &s_svc_uuid.u,
        .characteristics = (struct ble_gatt_chr_def[]){
            {
                .uuid = &s_sensor_uuid.u,
                .access_cb = gatt_access_cb,
                .val_handle = &s_sensor_val_handle,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_NOTIFY,
            },
            {
                .uuid = &s_status_uuid.u,
                .access_cb = gatt_access_cb,
                .val_handle = &s_status_val_handle,
                .flags = BLE_GATT_CHR_F_READ,
            },
            {
                .uuid = &s_command_uuid.u,
                .access_cb = gatt_access_cb,
                .val_handle = &s_command_val_handle,
                .flags = BLE_GATT_CHR_F_WRITE,
            },
            {0},
        },
    },
    {0},
};

static int gatt_access_cb(uint16_t conn_handle, uint16_t attr_handle,
                          struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    (void)conn_handle;
    (void)arg;

    if (attr_handle == s_sensor_val_handle) {
        if (ctxt->op == BLE_GATT_ACCESS_OP_READ_CHR) {
            return os_mbuf_append(ctxt->om, s_sensor_payload, sizeof(s_sensor_payload)) == 0
                       ? 0
                       : BLE_ATT_ERR_INSUFFICIENT_RES;
        }
    } else if (attr_handle == s_status_val_handle) {
        if (ctxt->op == BLE_GATT_ACCESS_OP_READ_CHR) {
            return os_mbuf_append(ctxt->om, &s_status_byte, 1) == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
        }
    } else if (attr_handle == s_command_val_handle) {
        if (ctxt->op == BLE_GATT_ACCESS_OP_WRITE_CHR) {
            uint16_t len = OS_MBUF_PKTLEN(ctxt->om);
            if (len < 1) {
                return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
            }
            uint8_t cmd = ctxt->om->om_data[0];
            switch (cmd) {
            case 0x01:
                lenslife_measure_acquire_blank();
                break;
            case 0x02:
                lenslife_vibration_run_ms(LENSELIFE_VIBRATION_MS);
                break;
            case 0x03: {
                lenslife_sensor_frame_t frame;
                if (lenslife_measure_run_cycle(&frame)) {
                    lenslife_ble_publish_frame(&frame);
                }
                break;
            }
            default:
                ESP_LOGW(TAG, "unknown command 0x%02X", cmd);
                break;
            }
            return 0;
        }
    }
    return BLE_ATT_ERR_UNLIKELY;
}

static void publish_status_from_frame(const lenslife_sensor_frame_t *frame)
{
    s_last_frame = *frame;
    lenslife_sensor_pack_payload(&frame->values, s_sensor_payload);
    s_status_byte = lenslife_sensor_build_status_byte(frame);
}

static int gap_event(struct ble_gap_event *event, void *arg)
{
    (void)arg;

    switch (event->type) {
    case BLE_GAP_EVENT_CONNECT:
        if (event->connect.status == 0) {
            s_conn_handle = event->connect.conn_handle;
            ESP_LOGI(TAG, "connected handle=%d", s_conn_handle);
        } else {
            ESP_LOGW(TAG, "connect failed status=%d", event->connect.status);
            lenslife_ble_start_advertising();
        }
        break;

    case BLE_GAP_EVENT_DISCONNECT:
        ESP_LOGI(TAG, "disconnected reason=%d", event->disconnect.reason);
        s_conn_handle = BLE_HS_CONN_HANDLE_NONE;
        s_notify_enabled = false;
        lenslife_ble_start_advertising();
        break;

    case BLE_GAP_EVENT_SUBSCRIBE:
        if (event->subscribe.attr_handle == s_sensor_val_handle) {
            s_notify_enabled = event->subscribe.cur_notify;
            if (s_notify_enabled && s_sync_sem) {
                xSemaphoreGive(s_sync_sem);
            }
        }
        break;

    case BLE_GAP_EVENT_ADV_COMPLETE:
        lenslife_ble_start_advertising();
        break;

    default:
        break;
    }
    return 0;
}

static void on_sync(void)
{
    uint8_t addr_type;
    if (ble_hs_id_infer_auto(0, &addr_type) == 0) {
        ble_hs_id_set_rnd_addr_type(addr_type);
    }
    lenslife_ble_start_advertising();
}

static void on_reset(int reason)
{
    ESP_LOGE(TAG, "NimBLE reset reason=%d", reason);
}

bool lenslife_ble_init(void)
{
    esp_err_t err = nimble_port_init();
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "nimble_port_init failed");
        return false;
    }

    ble_hs_cfg.sync_cb = on_sync;
    ble_hs_cfg.reset_cb = on_reset;

    ble_svc_gap_device_name_set(LENSELIFE_BLE_DEVICE_NAME);
    ble_svc_gap_init();
    ble_svc_gatt_init();

    int rc = ble_gatts_count_cfg(s_gatt_svcs);
    if (rc != 0) {
        return false;
    }
    rc = ble_gatts_add_svcs(s_gatt_svcs);
    if (rc != 0) {
        return false;
    }

    s_sync_sem = xSemaphoreCreateBinary();
    nimble_port_freertos_init(lenslife_ble_host_task);
    return true;
}

void lenslife_ble_host_task(void *param)
{
    (void)param;
    nimble_port_run();
    nimble_port_freertos_deinit();
}

bool lenslife_ble_start_advertising(void)
{
    struct ble_hs_adv_fields fields = {0};
    fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
    fields.name = (uint8_t *)LENSELIFE_BLE_DEVICE_NAME;
    fields.name_len = strlen(LENSELIFE_BLE_DEVICE_NAME);
    fields.name_is_complete = 1;

    const ble_uuid16_t adv_uuid16 = BLE_UUID16_INIT(0xAB00);
    fields.uuids16 = (ble_uuid16_t *)&adv_uuid16;
    fields.num_uuids16 = 1;
    fields.uuids16_is_complete = 1;

    int rc = ble_gap_adv_set_fields(&fields);
    if (rc != 0) {
        ESP_LOGE(TAG, "adv_set_fields rc=%d", rc);
        return false;
    }

    struct ble_gap_adv_params adv_params = {0};
    adv_params.conn_mode = BLE_GAP_CONN_MODE_UND;
    adv_params.disc_mode = BLE_GAP_DISC_MODE_GEN;

    rc = ble_gap_adv_start(BLE_OWN_ADDR_PUBLIC, NULL, BLE_HS_FOREVER, &adv_params, gap_event, NULL);
    if (rc != 0) {
        ESP_LOGE(TAG, "adv_start rc=%d", rc);
        return false;
    }
    ESP_LOGI(TAG, "advertising as %s", LENSELIFE_BLE_DEVICE_NAME);
    return true;
}

bool lenslife_ble_publish_frame(const lenslife_sensor_frame_t *frame)
{
    publish_status_from_frame(frame);

    if (s_conn_handle == BLE_HS_CONN_HANDLE_NONE || !s_notify_enabled) {
        return false;
    }

    struct os_mbuf *om = ble_hs_mbuf_from_flat(s_sensor_payload, sizeof(s_sensor_payload));
    if (!om) {
        return false;
    }

    int rc = ble_gatts_notify_custom(s_conn_handle, s_sensor_val_handle, om);
    if (rc != 0) {
        ESP_LOGW(TAG, "notify failed rc=%d", rc);
        return false;
    }

    ESP_LOGI(TAG, "NOTIFY SENSOR_DATA sent (status=0x%02X READ on 0xAB02)", s_status_byte);
    return true;
}

bool lenslife_ble_wait_and_notify(const lenslife_sensor_frame_t *frame, uint32_t timeout_ms)
{
    publish_status_from_frame(frame);

    if (!lenslife_ble_start_advertising()) {
        return false;
    }

    if (xSemaphoreTake(s_sync_sem, pdMS_TO_TICKS(timeout_ms)) != pdTRUE) {
        ESP_LOGW(TAG, "no BLE subscriber within %lu ms", (unsigned long)timeout_ms);
        return false;
    }

    vTaskDelay(pdMS_TO_TICKS(200));
    return lenslife_ble_publish_frame(frame);
}

void lenslife_ble_stop(void)
{
    if (s_conn_handle != BLE_HS_CONN_HANDLE_NONE) {
        ble_gap_terminate(s_conn_handle, BLE_ERR_REM_USER_CONN_TERM);
    }
    ble_gap_adv_stop();
}
