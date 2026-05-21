/*
 * DEPRECATED bench sketch — not used in production.
 * Production firmware: esp32/firmware/ (ESP-IDF + NimBLE).
 * Case RGB status uses the ESP32-S3 onboard WS2812 (see esp32/firmware/), not these pins.
 */
#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <math.h>

Adafruit_ADS1115 ads;
bool discardCurrentWindow = false;

// ---------------- Pins ----------------
const int IR_LED_PIN = 21;
const int BUTTON_PIN = 14;

// ---------------- RGB LED Pins ----------------
// Common cathode RGB LED:
// HIGH = color ON, LOW = color OFF
const int RGB_GREEN_PIN = 16;
const int RGB_BLUE_PIN  = 17;
const int RGB_RED_PIN   = 15;

// ---------------- ADS1115 Settings ----------------
// GAIN_EIGHT = ±0.512 V range
// GAIN_EIGHT 1 bit = 0.015625 mV
// GAIN_FOUR 1bit = 0.03125mV
// GAIN_ONE 1bit = 0.125mV
const float ADS_LSB_MV = 0.125;

// ---------------- System Modes ----------------
enum SystemMode {
  MODE_CALIBRATION,
  MODE_MEASUREMENT
};

SystemMode mode = MODE_CALIBRATION;

// ---------------- RGB LED Status ----------------
enum LedStatus {
  LED_CALIBRATING,
  LED_CLEAN,
  LED_DIRTY
};

// ---------------- Classification Stability ----------------
int dirtyConsecutiveCount = 0;
int cleanConsecutiveCount = 0;

const int REQUIRED_CONSECUTIVE_WINDOWS = 3;

LedStatus ledStatus = LED_CALIBRATING;

unsigned long lastLedBlinkTime = 0;
bool ledBlinkState = false;

// ---------------- Signal Statistics ----------------
struct SignalStats {
  float mean;
  float stdDev;
  float cv;
  int16_t minVal;
  int16_t maxVal;
  int peakToPeak;
};

SignalStats cleanStats;
SignalStats sampleStats;

bool cleanStatsValid = false;

// ---------------- Dynamic Calibration Model ----------------
const int MIN_CALIBRATION_WINDOWS = 10;

int calibrationCount = 0;

// Running calibration statistics for clean mean
double cleanMeanRunningAvg = 0.0;
double cleanMeanM2 = 0.0;

// Running calibration statistics for clean CV
double cleanCvRunningAvg = 0.0;
double cleanCvM2 = 0.0;

// Frozen calibration model used during measurement
float calibratedCleanMean = 0.0;
float calibratedCleanMeanSpread = 0.0;

float calibratedCleanCv = 0.0;
float calibratedCleanCvSpread = 0.0;

// ---------------- Button Debounce ----------------
bool lastButtonReading = HIGH;
bool stableButtonState = HIGH;
unsigned long lastDebounceTime = 0;
const unsigned long debounceDelay = 50;
const unsigned long LONG_PRESS_MS = 1500;

bool buttonIsBeingHeld = false;
bool longPressTriggered = false;
unsigned long buttonPressStartTime = 0;

void handleButton();

//Mean tracks overall IR transmission
//Std Dev tracks absolute fluctuation in the IR signal
//CV tracks normalized fluctuation and is the best for comparing clean vs dirty
//Peak-to-Peak tracks the total range of signal variation during that sample window

// ---------------- Raw-Sample Statistics ----------------
//sample = 50 ~1s per calculation
SignalStats measureSignalStats(int samples = 50) {
  SignalStats stats; 

  double mean = 0.0;
  double M2 = 0.0;

  int16_t minReading = 32767;
  int16_t maxReading = -32768;

  for (int i = 1; i <= samples; i++) {
    int16_t reading = ads.readADC_SingleEnded(0);

    // Welford's algorithm for mean and variance
    double delta = reading - mean;
    mean += delta / i;
    double delta2 = reading - mean;
    M2 += delta * delta2;

    if (reading < minReading) {
      minReading = reading;
    }

    if (reading > maxReading) {
      maxReading = reading;
    }
    updateRGBLed();
    handleButton();
  }

  double variance = 0.0;

  if (samples > 1) {
    variance = M2 / (samples - 1);
  }

  stats.mean = mean;
  stats.stdDev = sqrt(variance);

  if (stats.mean != 0) {
    stats.cv = stats.stdDev / stats.mean;
  } else {
    stats.cv = 0.0;
  }

  stats.minVal = minReading;
  stats.maxVal = maxReading;
  stats.peakToPeak = maxReading - minReading;

  return stats;
}

// ---------------- Measurement Functions ----------------
float computeTransmission(float sampleMean, float cleanMean) {
  if (cleanMean == 0) return 0.0;
  return sampleMean / cleanMean;
}

float computeTurbidity(float transmission) {
  return 1.0 - transmission;
}

// ---------------- RGB LED Control ----------------
void setRGB(bool red, bool green, bool blue) {
  digitalWrite(RGB_RED_PIN, red ? HIGH : LOW);
  digitalWrite(RGB_GREEN_PIN, green ? HIGH : LOW);
  digitalWrite(RGB_BLUE_PIN, blue ? HIGH : LOW);
}

void updateRGBLed() {
  unsigned long currentTime = millis();
  unsigned long blinkInterval = 1000;

  // Pick blink speed based on state
  if (ledStatus == LED_CALIBRATING) {
    blinkInterval = 1000;  // slow blue blink
  }
  else if (ledStatus == LED_CLEAN) {
    blinkInterval = 500;   // green blink
  }
  else if (ledStatus == LED_DIRTY) {
    blinkInterval = 250;   // faster red blink
  }

  // Toggle LED state when interval passes
  if (currentTime - lastLedBlinkTime >= blinkInterval) {
    lastLedBlinkTime = currentTime;
    ledBlinkState = !ledBlinkState;
  }

  // Display correct color
  if (!ledBlinkState) {
    setRGB(false, false, false); // LED off during blink gap
  }
  else {
    if (ledStatus == LED_CALIBRATING) {
      setRGB(false, false, true);   // Blue
    }
    else if (ledStatus == LED_CLEAN) {
      setRGB(false, true, false);   // Green
    }
    else if (ledStatus == LED_DIRTY) {
      setRGB(true, false, false);   // Red
    }
  }
}

// Keeps blinking active during waiting periods
void waitWithLedUpdate(unsigned long waitTimeMs) {
  unsigned long startTime = millis();

  while (millis() - startTime < waitTimeMs) {
    updateRGBLed();
    handleButton();
    delay(5);
  }
}

void finalizeCalibrationModel() {
  calibratedCleanMean = cleanMeanRunningAvg;
  calibratedCleanCv = cleanCvRunningAvg;

  if (calibrationCount > 1) {
    calibratedCleanMeanSpread = sqrt(cleanMeanM2 / (calibrationCount - 1));
    calibratedCleanCvSpread = sqrt(cleanCvM2 / (calibrationCount - 1));
  } else {
    calibratedCleanMeanSpread = 0.0;
    calibratedCleanCvSpread = 0.0;
  }

  cleanStatsValid = true;

  Serial.println("\nCalibration model locked.");
  Serial.print("Calibrated Clean Mean: ");
  Serial.println(calibratedCleanMean, 3);

  Serial.print("Clean Mean Calibration Spread: ");
  Serial.println(calibratedCleanMeanSpread, 4);

  Serial.print("Calibrated Clean CV: ");
  Serial.println(calibratedCleanCv, 6);

  Serial.print("Clean CV Calibration Spread: ");
  Serial.println(calibratedCleanCvSpread, 6);
}

void updateCleanCalibrationModel(SignalStats stats) {
  calibrationCount++;

  // ----- Track clean mean behavior -----
  double meanDelta = stats.mean - cleanMeanRunningAvg;
  cleanMeanRunningAvg += meanDelta / calibrationCount;
  double meanDelta2 = stats.mean - cleanMeanRunningAvg;
  cleanMeanM2 += meanDelta * meanDelta2;

  // ----- Track clean CV behavior -----
  double cvDelta = stats.cv - cleanCvRunningAvg;
  cleanCvRunningAvg += cvDelta / calibrationCount;
  double cvDelta2 = stats.cv - cleanCvRunningAvg;
  cleanCvM2 += cvDelta * cvDelta2;
}

void resetCalibrationModel() {
  discardCurrentWindow = true;
  mode = MODE_CALIBRATION;
  cleanStatsValid = false;

  calibrationCount = 0;

  cleanMeanRunningAvg = 0.0;
  cleanMeanM2 = 0.0;

  cleanCvRunningAvg = 0.0;
  cleanCvM2 = 0.0;

  calibratedCleanMean = 0.0;
  calibratedCleanMeanSpread = 0.0;

  calibratedCleanCv = 0.0;
  calibratedCleanCvSpread = 0.0;

  ledStatus = LED_CALIBRATING;

  Serial.println("\nLONG PRESS DETECTED");
  Serial.println("Returned to CALIBRATION mode.");
  Serial.println("Calibration windows reset to 0.");
  Serial.println("Place CLEAN solution in the chamber.");
}

void enterMeasurementMode() {
  discardCurrentWindow = true;
  if (mode != MODE_CALIBRATION) {
    return;
  }

  if (calibrationCount == 0) {
    Serial.println("\nNo calibration readings collected yet.");
    Serial.println("Wait for at least one clean calibration window.");
    return;
  }

  if (calibrationCount < MIN_CALIBRATION_WINDOWS) {
    Serial.println("\nWarning: entering measurement mode with fewer than the recommended calibration windows.");
  }

  finalizeCalibrationModel();
  mode = MODE_MEASUREMENT;

  Serial.println("\nSHORT PRESS DETECTED");
  Serial.println("Switched to MEASUREMENT mode.");
  Serial.println("Place sample solution in the chamber.");
}

void handleButton() {
  bool buttonReading = digitalRead(BUTTON_PIN);

  // ---------- Debounce ----------
  if (buttonReading != lastButtonReading) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {

    if (buttonReading != stableButtonState) {
      stableButtonState = buttonReading;

      // ---------- Button just pressed ----------
      if (stableButtonState == LOW) {
        buttonIsBeingHeld = true;
        longPressTriggered = false;
        buttonPressStartTime = millis();
      }

      // ---------- Button just released ----------
      else {
        if (buttonIsBeingHeld && !longPressTriggered) {
          // Short press only does something while calibrating
          if (mode == MODE_CALIBRATION) {
            enterMeasurementMode();
          }
        }

        buttonIsBeingHeld = false;
        longPressTriggered = false;
      }
    }
  }

  // ---------- Long press detection ----------
  if (
    buttonIsBeingHeld &&
    !longPressTriggered &&
    stableButtonState == LOW &&
    (millis() - buttonPressStartTime >= LONG_PRESS_MS)
  ) {
    longPressTriggered = true;
    resetCalibrationModel();
  }

  lastButtonReading = buttonReading;
}

// ---------------- Setup ----------------
void setup() {
  Serial.begin(115200);
  delay(1000);

  Wire.begin(SDA, SCL);

  if (!ads.begin(0x48)) {
    Serial.println("ADS1115 not found!");
    while (1);
  }

  ads.setGain(GAIN_ONE);

  pinMode(IR_LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(RGB_RED_PIN, OUTPUT);
  pinMode(RGB_GREEN_PIN, OUTPUT);
  pinMode(RGB_BLUE_PIN, OUTPUT);

  setRGB(false, false, false);
  ledStatus = LED_CALIBRATING;

  digitalWrite(IR_LED_PIN, HIGH);

  Serial.println("LensLife Optical Noise Analysis:");
  Serial.println("Mode: CALIBRATION");
  Serial.println("Place CLEAN solution in the chamber.");
  Serial.println("Let it stabilize, then press button to switch to MEASUREMENT.");
}

// ---------------- Main Loop ----------------
void loop() {

  // ---------- Button Handling ----------
  handleButton();

  // ---------- Keep IR LED ON ----------
  digitalWrite(IR_LED_PIN, HIGH);

  // ---------- Collect Raw-Sample Statistics ----------
  SignalStats currentStats = measureSignalStats(500);
  
  if (discardCurrentWindow) {
  discardCurrentWindow = false;
  waitWithLedUpdate(500);
  return;
  }

  float meanMillivolts = currentStats.mean * ADS_LSB_MV;

  // ---------- Calibration Mode ----------
  if (mode == MODE_CALIBRATION) {

    ledStatus = LED_CALIBRATING;

    cleanStats = currentStats;
    updateCleanCalibrationModel(cleanStats);

    Serial.println("\n[CALIBRATION - CLEAN SOLUTION]");

    Serial.print("Mean Raw: ");
    Serial.print(cleanStats.mean, 2);

    Serial.print(" | Mean Voltage: ");
    Serial.print(meanMillivolts, 3);
    Serial.println(" mV");

    Serial.print("Std Dev: ");
    Serial.print(cleanStats.stdDev, 4);

    Serial.print(" | CV: ");
    Serial.print(cleanStats.cv, 6);

    Serial.print(" | Peak-to-Peak: ");
    Serial.println(cleanStats.peakToPeak);

    Serial.print("Calibration Windows Collected: ");
    Serial.print(calibrationCount);
    Serial.print("/");
    Serial.println(MIN_CALIBRATION_WINDOWS);
  }

  // ---------- Measurement Mode ----------
  else {

    if (!cleanStatsValid) {
      Serial.println("No clean baseline stored. Return to CALIBRATION mode first.");
      delay(1000);
      return;
    }

    sampleStats = currentStats;

    float transmission = computeTransmission(sampleStats.mean, calibratedCleanMean);
    float turbidity = computeTurbidity(transmission);

    float meanDropPercent =
      ((calibratedCleanMean - sampleStats.mean) / calibratedCleanMean) * 100.0;

    float stdDevRatio = 0.0;
    if (cleanStats.stdDev != 0) {
      stdDevRatio = sampleStats.stdDev / cleanStats.stdDev;
    }

    float cvRatio = 0.0;
    if (calibratedCleanCv != 0) { 
      cvRatio = sampleStats.cv / calibratedCleanCv;
    }

      // ---------------- Dynamic Clean-vs-Sample Difference Scoring ----------------

    // Prevent divide-by-zero if calibration spread is extremely tiny
    float meanSpreadUsed = calibratedCleanMeanSpread;
    if (meanSpreadUsed < 1.0) {
      meanSpreadUsed = 1.0;
    }

    float cvSpreadUsed = calibratedCleanCvSpread;
    if (cvSpreadUsed < 0.000001) {
      cvSpreadUsed = 0.000001;
    }

    // How far below clean the sample mean is
    float meanDifferenceScore =
      (calibratedCleanMean - sampleStats.mean) / meanSpreadUsed;

    // How far above clean the sample CV is
    float cvDifferenceScore =
      (sampleStats.cv - calibratedCleanCv) / cvSpreadUsed;

    // 3.0 means roughly "3 calibration standard deviations away from clean"
    const float DIRTY_DIFFERENCE_SCORE_THRESHOLD = 3.0;

    bool solutionIsDirty =
      (meanDifferenceScore > DIRTY_DIFFERENCE_SCORE_THRESHOLD) ||
      (cvDifferenceScore > DIRTY_DIFFERENCE_SCORE_THRESHOLD);

    // ---------------- Stable Classification Decision ----------------
    if (solutionIsDirty) {
      dirtyConsecutiveCount++;
      cleanConsecutiveCount = 0;
    } 
    else {
      cleanConsecutiveCount++;
      dirtyConsecutiveCount = 0;
    }

    // Only switch to DIRTY after several dirty windows in a row
    if (dirtyConsecutiveCount >= REQUIRED_CONSECUTIVE_WINDOWS) {
      ledStatus = LED_DIRTY;
    }

    // Only switch to CLEAN after several clean windows in a row
    if (cleanConsecutiveCount >= REQUIRED_CONSECUTIVE_WINDOWS) {
      ledStatus = LED_CLEAN;
    }

    Serial.println("\n[MEASUREMENT - SAMPLE SOLUTION]");

    Serial.println("----- Mean Signal -----");
    Serial.print("Calibrated Clean Mean: ");
    Serial.print(calibratedCleanMean, 2);

    Serial.print(" | Sample Mean: ");
    Serial.print(sampleStats.mean, 2);

    Serial.print(" | Mean Drop: ");
    Serial.print(meanDropPercent, 3);
    Serial.println(" %");

    Serial.println("----- Signal Noise -----");
    Serial.print("Last Calibration Std Dev: ");
    Serial.print(cleanStats.stdDev, 4);

    Serial.print(" | Sample Std Dev: ");
    Serial.print(sampleStats.stdDev, 4);

    Serial.print(" | Std Dev Ratio: ");
    Serial.println(stdDevRatio, 3);

    Serial.println("----- Normalized Noise -----");
    Serial.print("Calibrated Clean CV: ");
    Serial.print(calibratedCleanCv, 6);

    Serial.print(" | Sample CV: ");
    Serial.print(sampleStats.cv, 6);

    Serial.print(" | CV Ratio: ");
    Serial.println(cvRatio, 3);

    Serial.println("----- Optical Transmission Estimate -----");
    Serial.print("Transmission: ");
    Serial.print(transmission, 4);

    Serial.print(" | Turbidity Proxy: ");
    Serial.println(turbidity, 4);

    Serial.println("----- Extra Variation Info -----");
    Serial.print("Last Calibration Peak-to-Peak: ");
    Serial.print(cleanStats.peakToPeak);

    Serial.print(" | Sample Peak-to-Peak: ");
    Serial.println(sampleStats.peakToPeak);

    Serial.println("----- Dynamic Difference Scores -----");

    Serial.print("Mean Difference Score: ");
    Serial.println(meanDifferenceScore, 3);

    Serial.print("CV Difference Score: ");
    Serial.println(cvDifferenceScore, 3);

    Serial.print("Decision: ");
    Serial.println(solutionIsDirty ? "DIRTY" : "CLEAN");

    Serial.print("Dirty Consecutive Count: ");
    Serial.println(dirtyConsecutiveCount);

    Serial.print("Clean Consecutive Count: ");
    Serial.println(cleanConsecutiveCount);

    Serial.print("Stable LED Status: ");
    if (ledStatus == LED_DIRTY) {
      Serial.println("DIRTY - RED");
    }
    else if (ledStatus == LED_CLEAN) {
      Serial.println("CLEAN - GREEN");
    }
    else {
      Serial.println("CALIBRATING - BLUE");
    }
  }

  waitWithLedUpdate(500);
}