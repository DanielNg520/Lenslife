#include "lenslife_classify.h"

int lenslife_classify(float dT, float pH, float temp_c, int wear_days, bool ph_valid)
{
    (void)temp_c;
    // TODO: replace with sklearn tree export
    if (dT > 0.05f) {
        return 2;
    }
    if (ph_valid && (pH < 6.5f || pH > 7.6f)) {
        return 1;
    }
    if (wear_days > 25) {
        return 1;
    }
    return 0;
}
