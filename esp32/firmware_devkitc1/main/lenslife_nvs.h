#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define LENSELIFE_NVS_NAMESPACE "lenslife"

bool lenslife_nvs_init(void);

bool lenslife_nvs_read_float(const char *key, float *out, float default_val);
bool lenslife_nvs_write_float(const char *key, float value);

bool lenslife_nvs_read_u32(const char *key, uint32_t *out, uint32_t default_val);
bool lenslife_nvs_write_u32(const char *key, uint32_t value);

#ifdef __cplusplus
}
#endif
