// pH Wiring:
// pH Po ---- 20kΩ ----+---- XIAO A0
//                     |
//                    10kΩ
//                     |
// XIAO GND -----------+---- pH G
//
// Button Wiring:
// XIAO A1 ---- button ---- GND
//
// Pressing the button restarts the 60-second clean baseline calibration.

#include <math.h>

const int PH_PIN = A0;
const int RESET_BUTTON_PIN = D6;

// ---------------- Timing ----------------
const unsigned long BASELINE_TIME_MS = 60000;   // 60 sec clean baseline
const unsigned long SAMPLE_DELAY_MS  = 100;     // 10 samples/sec
const unsigned long CHECK_TIME_MS    = 5000;    // average every 5 sec

// ---------------- Button debounce ----------------
const unsigned long DEBOUNCE_MS = 50;

// ---------------- Thresholds ----------------
// Deviation around 135 = clearly abnormal.
const float PH_CAUTION_THRESHOLD = 50.0;
const float PH_SWAP_THRESHOLD    = 80.0;

// Require repeated abnormal readings before final swap decision
const int REQUIRED_CONSECUTIVE_WINDOWS = 2;

const float PH4_RAW = 1679.0;
const float PH7_RAW = 1510.0; //1510-1540

float cleanPHRaw = 0.0;

int abnormalConsecutiveCount = 0;
int normalConsecutiveCount = 0;

bool lastButtonReading = HIGH;
bool stableButtonState = HIGH;
unsigned long lastDebounceTime = 0;

float collectAverageRaw(unsigned long durationMs) {
  unsigned long startTime = millis();
  unsigned long sampleCount = 0;
  double sum = 0.0;

  while (millis() - startTime < durationMs) {
    int raw = analogRead(PH_PIN);
    sum += raw;
    sampleCount++;

    delay(SAMPLE_DELAY_MS);
  }

  if (sampleCount == 0) {
    return 0.0;
  }

  return sum / sampleCount;
}

float estimatePHFromRaw(float rawADC) {
  // pH 4 -> higher ADC
  // pH 7 -> lower ADC
  if (PH4_RAW == PH7_RAW) {
    return -1.0;
  }

  float estimatedPH = 7.0 - 3.0 * (rawADC - PH7_RAW) / (PH4_RAW - PH7_RAW);
  return estimatedPH;
}

bool resetButtonPressed() {
  bool currentReading = digitalRead(RESET_BUTTON_PIN);

  if (currentReading != lastButtonReading) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > DEBOUNCE_MS) {
    if (currentReading != stableButtonState) {
      stableButtonState = currentReading;

      // Button is active LOW because it connects A1 to GND
      if (stableButtonState == LOW) {
        lastButtonReading = currentReading;
        return true;
      }
    }
  }

  lastButtonReading = currentReading;
  return false;
}

void waitForButtonRelease() {
  while (digitalRead(RESET_BUTTON_PIN) == LOW) {
    delay(10);
  }

  delay(200); // small release debounce
}

void runCalibration() {
  abnormalConsecutiveCount = 0;
  normalConsecutiveCount = 0;

  Serial.println();
  Serial.println("========================================");
  Serial.println("pH baseline calibration starting.");
  Serial.println("Put the pH probe in CLEAN saline/contact lens solution.");
  Serial.println("Collecting 60-second clean baseline...");
  Serial.println("========================================");
  Serial.println();

  cleanPHRaw = collectAverageRaw(BASELINE_TIME_MS);

  Serial.println();
  Serial.println("Baseline complete.");
  Serial.print("Clean pH Raw Baseline = ");
  Serial.println(cleanPHRaw, 2);
  Serial.println();

  Serial.println("Now monitoring sample solution...");
  Serial.println();
}

void printPHDecision(float avgPHRaw) {
  float phDeviation = fabs(avgPHRaw - cleanPHRaw);
  float estimatedPH = estimatePHFromRaw(avgPHRaw);

  bool phCaution = phDeviation > PH_CAUTION_THRESHOLD && phDeviation <= PH_SWAP_THRESHOLD;
  bool phAbnormal = phDeviation > PH_SWAP_THRESHOLD;

  if (phAbnormal) {
    abnormalConsecutiveCount++;
    normalConsecutiveCount = 0;
  } else {
    normalConsecutiveCount++;
    abnormalConsecutiveCount = 0;
  }

  String status;
  String action;

  if (abnormalConsecutiveCount >= REQUIRED_CONSECUTIVE_WINDOWS) {
    status = "BAD";
    action = "SWAP LENS LINER";
  } 
  else if (phAbnormal) {
    status = "BAD?";
    action = "WAIT";
  } 
  else if (phCaution) {
    status = "WARN";
    action = "RETEST";
  } 
  else {
    status = "OK";
    action = "KEEP";
  }

  Serial.print("Raw=");
  Serial.print(avgPHRaw, 1);

  Serial.print(" Base=");
  Serial.print(cleanPHRaw, 1);

  Serial.print(" Dev=");
  Serial.print(phDeviation, 1);

  Serial.print(" pH=");
  Serial.print(estimatedPH, 2);

  Serial.print(" Cnt=");
  Serial.print(abnormalConsecutiveCount);

  Serial.print(" Status=");
  Serial.print(status);

  Serial.print(" Action=");
  Serial.println(action);
}

void setup() {
  Serial.begin(115200);
  delay(2000);

  analogReadResolution(12);

  // Safe for ESP32 ADC range
  analogSetPinAttenuation(PH_PIN, ADC_11db);

  // Button uses internal pullup.
  // Pressed = LOW, released = HIGH.
  pinMode(RESET_BUTTON_PIN, INPUT_PULLUP);

  Serial.println("LensLife pH Chemical Safety Check");
  Serial.println("Press the A1 button anytime to restart clean baseline calibration.");
  Serial.println();

  runCalibration();
}

void loop() {
  if (resetButtonPressed()) {
    waitForButtonRelease();
    runCalibration();
    return;
  }

  float avgPHRaw = collectAverageRaw(CHECK_TIME_MS);
  printPHDecision(avgPHRaw);

  if (resetButtonPressed()) {
    waitForButtonRelease();
    runCalibration();
    return;
  }
}