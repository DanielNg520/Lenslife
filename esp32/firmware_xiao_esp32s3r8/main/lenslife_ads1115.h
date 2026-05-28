#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    LENSELIFE_ADS_CH_A0 = 0,
    LENSELIFE_ADS_CH_A1 = 1,
} lenslife_ads_channel_t;

bool lenslife_ads1115_init(void);
bool lenslife_ads1115_read_volts(lenslife_ads_channel_t channel, float *volts_out);

#ifdef __cplusplus
}
#endif
