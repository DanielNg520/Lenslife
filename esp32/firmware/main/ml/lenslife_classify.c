#include "lenslife_classify.h"

int lenslife_classify(float dT, float pH, float temp_c, int wear_days)
{
    (void)temp_c;
    // TODO: replace with sklearn tree export
    // Offline training command:
    //   clf = DecisionTreeClassifier(max_depth=4, min_samples_leaf=2)
    //   clf.fit(X, y)  # X: [dT, pH, temp, wear_days], y: [0,1,2]
    //   print(export_text(clf))  → translate output to C if/else
    if (dT > 0.05f) {
        return 2;
    }
    if (pH < 6.5f || pH > 7.6f) {
        return 1;
    }
    if (wear_days > 25) {
        return 1;
    }
    return 0;
}
