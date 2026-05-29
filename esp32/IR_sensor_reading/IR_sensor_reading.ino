#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <math.h>
#include <Adafruit_NeoPixel.h>
#include <LittleFS.h>

Adafruit_ADS1115 ads;

bool discardCurrentWindow = false;

// ---------------- CSV Calibration Logging ----------------
const char* CALIBRATION_CSV_PATH = "/calibration_clean.csv";
bool csvLoggingReady = false;

// ---------------- ESP32-S3-WROOM-1 N16R8 Pin Mapping ----------------

// ADS1115 I2C
const int I2C_SDA_PIN = 8;
const int I2C_SCL_PIN = 9;

// IR LED control
const int IR_LED_PIN = 10;

// Push button
const int BUTTON_PIN = 11;

// RGB LED pins
// Common cathode RGB LED:
// HIGH = ON, LOW = OFF
const int RGB_GREEN_PIN = 12;
const int RGB_BLUE_PIN  = 13;
const int RGB_RED_PIN   = 14;

// ---------------- Onboard RGB LED ----------------
// ESP32-S3 board onboard RGB LED is connected to GPIO48
const int ONBOARD_RGB_PIN = 48;

Adafruit_NeoPixel onboardRGB(
  1,
  ONBOARD_RGB_PIN,
  NEO_GRB + NEO_KHZ800
);

// ---------------- ADS1115 Settings ----------------
// GAIN_ONE = ±4.096 V
// 1 bit = 0.125 mV
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

LedStatus ledStatus = LED_CALIBRATING;

unsigned long lastLedBlinkTime = 0;
bool ledBlinkState = false;

// ---------------- Classification Stability ----------------
int dirtyConsecutiveCount = 0;
int cleanConsecutiveCount = 0;

const int REQUIRED_CONSECUTIVE_WINDOWS = 3;

// ---------------- Signal Statistics ----------------
struct SignalStats {
  float mean;
  float stdDev;
  float cv;
  int16_t minVal;
  int16_t maxVal;
  int peakToPeak;
};

void setupCsvLogging();
void resetCalibrationCsv();
void appendCalibrationCsv(SignalStats stats);
void printCalibrationCsvToSerial();

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

// ---------------- Function Prototypes ----------------
void handleButton();
void updateRGBLed();

// Mean tracks overall IR transmission
// Std Dev tracks absolute fluctuation in the IR signal
// CV tracks normalized fluctuation and is useful for comparing clean vs dirty
// Peak-to-Peak tracks the total range during that sample window

int16_t readAmbientCorrectedIR() {
  // LED ON reading
  digitalWrite(IR_LED_PIN, HIGH);
  delay(2);
  int16_t ledOnReading = ads.readADC_SingleEnded(0);

  // LED OFF reading
  digitalWrite(IR_LED_PIN, LOW);
  delay(2);
  int16_t ledOffReading = ads.readADC_SingleEnded(0);

  // Ambient-corrected IR signal
  int32_t corrected = (int32_t)ledOnReading - (int32_t)ledOffReading;

  // Keep inside int16_t range
  if (corrected > 32767) corrected = 32767;
  if (corrected < -32768) corrected = -32768;

  return (int16_t)corrected;
}

// ---------------- Raw-Sample Statistics ----------------
SignalStats measureSignalStats(int samples = 500) {
  SignalStats stats;

  double mean = 0.0;
  double M2 = 0.0;

  int16_t minReading = 32767;
  int16_t maxReading = -32768;

  for (int i = 1; i <= samples; i++) {
    int16_t reading = readAmbientCorrectedIR();

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

void setRGB(bool red, bool green, bool blue) {
  // ---------- External common-cathode RGB LED ----------
  digitalWrite(RGB_RED_PIN, red ? HIGH : LOW);
  digitalWrite(RGB_GREEN_PIN, green ? HIGH : LOW);
  digitalWrite(RGB_BLUE_PIN, blue ? HIGH : LOW);

  // ---------- Onboard addressable RGB LED ----------
  uint8_t r = red ? 40 : 0;
  uint8_t g = green ? 40 : 0;
  uint8_t b = blue ? 40 : 0;

  onboardRGB.setPixelColor(0, onboardRGB.Color(r, g, b));
  onboardRGB.show();
}

void updateRGBLed() {
  unsigned long currentTime = millis();
  unsigned long blinkInterval = 1000;

  if (ledStatus == LED_CALIBRATING) {
    blinkInterval = 1000;  // Slow blue blink
  }
  else if (ledStatus == LED_CLEAN) {
    blinkInterval = 500;   // Green blink
  }
  else if (ledStatus == LED_DIRTY) {
    blinkInterval = 250;   // Faster red blink
  }

  if (currentTime - lastLedBlinkTime >= blinkInterval) {
    lastLedBlinkTime = currentTime;
    ledBlinkState = !ledBlinkState;
  }

  if (!ledBlinkState) {
    setRGB(false, false, false);
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

// ---------------- Calibration Logic ----------------
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

  dirtyConsecutiveCount = 0;
  cleanConsecutiveCount = 0;

  Serial.println("\nCalibration model locked.");
  Serial.print("Calibrated Clean Mean: ");
  Serial.println(calibratedCleanMean, 3);

  Serial.print("Clean Mean Calibration Spread: ");
  Serial.println(calibratedCleanMeanSpread, 4);

  Serial.print("Calibrated Clean CV: ");
  Serial.println(calibratedCleanCv, 6);

  Serial.print("Clean CV Calibration Spread: ");
  Serial.println(calibratedCleanCvSpread, 6);
  printCalibrationCsvToSerial();
}

void updateCleanCalibrationModel(SignalStats stats) {
  calibrationCount++;

  // Track clean mean behavior
  double meanDelta = stats.mean - cleanMeanRunningAvg;
  cleanMeanRunningAvg += meanDelta / calibrationCount;
  double meanDelta2 = stats.mean - cleanMeanRunningAvg;
  cleanMeanM2 += meanDelta * meanDelta2;

  // Track clean CV behavior
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

  dirtyConsecutiveCount = 0;
  cleanConsecutiveCount = 0;

  ledStatus = LED_CALIBRATING;

  Serial.println("\nLONG PRESS DETECTED");
  Serial.println("Returned to CALIBRATION mode.");
  Serial.println("Calibration windows reset to 0.");
  Serial.println("Place CLEAN solution in the chamber.");
  resetCalibrationCsv();
}

void enterMeasurementMode() {
  if (mode != MODE_CALIBRATION) {
    return;
  }

  if (calibrationCount == 0) {
    Serial.println("\nNo calibration readings collected yet.");
    Serial.println("Wait for at least one clean calibration window.");
    return;
  }

  discardCurrentWindow = true;

  if (calibrationCount < MIN_CALIBRATION_WINDOWS) {
    Serial.println("\nWarning: entering measurement mode with fewer than the recommended calibration windows.");
  }

  finalizeCalibrationModel();
  mode = MODE_MEASUREMENT;

  Serial.println("\nSHORT PRESS DETECTED");
  Serial.println("Switched to MEASUREMENT mode.");
  Serial.println("Place sample solution in the chamber.");
}

// ---------------- Button Handling ----------------
void handleButton() {
  bool buttonReading = digitalRead(BUTTON_PIN);

  if (buttonReading != lastButtonReading) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {

    if (buttonReading != stableButtonState) {
      stableButtonState = buttonReading;

      // Button just pressed
      if (stableButtonState == LOW) {
        buttonIsBeingHeld = true;
        longPressTriggered = false;
        buttonPressStartTime = millis();
      }

      // Button just released
      else {
        if (buttonIsBeingHeld && !longPressTriggered) {
          if (mode == MODE_CALIBRATION) {
            enterMeasurementMode();
          }
        }

        buttonIsBeingHeld = false;
        longPressTriggered = false;
      }
    }
  }

  // Long press detection
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

// ---------------- CSV Calibration Logging Functions ----------------

void setupCsvLogging() {
  if (!LittleFS.begin(true)) {
    Serial.println("LittleFS mount failed. CSV logging disabled.");
    csvLoggingReady = false;
    return;
  }

  csvLoggingReady = true;
  Serial.println("LittleFS mounted. CSV logging enabled.");
}

void resetCalibrationCsv() {
  if (!csvLoggingReady) {
    return;
  }

  File file = LittleFS.open(CALIBRATION_CSV_PATH, "w");

  if (!file) {
    Serial.println("Failed to create calibration CSV file.");
    return;
  }

  file.println(
    "time_ms,"
    "calibration_window,"
    "mean_raw,"
    "mean_mV,"
    "std_dev,"
    "cv,"
    "min_raw,"
    "max_raw,"
    "peak_to_peak,"
    "running_clean_mean,"
    "running_clean_mean_spread,"
    "running_clean_cv,"
    "running_clean_cv_spread"
  );

  file.close();

  Serial.println("Calibration CSV reset.");
}

void appendCalibrationCsv(SignalStats stats) {
  if (!csvLoggingReady) {
    return;
  }

  File file = LittleFS.open(CALIBRATION_CSV_PATH, "a");

  if (!file) {
    Serial.println("Failed to open calibration CSV file for appending.");
    return;
  }

  float meanMillivolts = stats.mean * ADS_LSB_MV;

  float currentMeanSpread = 0.0;
  float currentCvSpread = 0.0;

  if (calibrationCount > 1) {
    currentMeanSpread = sqrt(cleanMeanM2 / (calibrationCount - 1));
    currentCvSpread = sqrt(cleanCvM2 / (calibrationCount - 1));
  }

  file.print(millis());
  file.print(",");

  file.print(calibrationCount);
  file.print(",");

  file.print(stats.mean, 4);
  file.print(",");

  file.print(meanMillivolts, 4);
  file.print(",");

  file.print(stats.stdDev, 6);
  file.print(",");

  file.print(stats.cv, 8);
  file.print(",");

  file.print(stats.minVal);
  file.print(",");

  file.print(stats.maxVal);
  file.print(",");

  file.print(stats.peakToPeak);
  file.print(",");

  file.print(cleanMeanRunningAvg, 6);
  file.print(",");

  file.print(currentMeanSpread, 6);
  file.print(",");

  file.print(cleanCvRunningAvg, 8);
  file.print(",");

  file.println(currentCvSpread, 8);

  file.close();
}

void printCalibrationCsvToSerial() {
  if (!csvLoggingReady) {
    Serial.println("CSV logging is not available.");
    return;
  }

  File file = LittleFS.open(CALIBRATION_CSV_PATH, "r");

  if (!file) {
    Serial.println("Failed to open calibration CSV file for reading.");
    return;
  }

  Serial.println();
  Serial.println("===== BEGIN CALIBRATION CSV =====");

  while (file.available()) {
    Serial.write(file.read());
  }

  Serial.println("===== END CALIBRATION CSV =====");
  Serial.println();

  file.close();
}

// ---------------- Setup ----------------
void setup() {
  Serial.begin(115200);
  delay(1000);

  setupCsvLogging();
  resetCalibrationCsv();

  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);

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

  onboardRGB.begin();
  onboardRGB.clear();
  onboardRGB.show();

  setRGB(false, false, false);
  ledStatus = LED_CALIBRATING;

  digitalWrite(IR_LED_PIN, LOW);

  Serial.println("LensLife Optical Noise Analysis");
  Serial.println("Board: ESP32-S3");
  Serial.println("Mode: CALIBRATION");
  Serial.println("Place CLEAN solution in the chamber.");
  Serial.println("Let it stabilize, then short-press the button to enter MEASUREMENT.");
  Serial.println("Hold button for 1.5 s to reset calibration.");
}

// ---------------- Main Loop ----------------
void loop() {

  handleButton();

  // Keep IR LED ON
  //digitalWrite(IR_LED_PIN, HIGH);

  // Collect raw-sample statistics
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
    appendCalibrationCsv(cleanStats);

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
      waitWithLedUpdate(1000);
      return;
    }

    sampleStats = currentStats;

    float transmission = computeTransmission(sampleStats.mean, calibratedCleanMean);
    float turbidity = computeTurbidity(transmission);

    float meanChangePercent =
     ((sampleStats.mean - calibratedCleanMean) / calibratedCleanMean) * 100.0;

    float stdDevRatio = 0.0;
    if (cleanStats.stdDev != 0) {
      stdDevRatio = sampleStats.stdDev / cleanStats.stdDev;
    }

    float cvRatio = 0.0;
    if (calibratedCleanCv != 0) {
      cvRatio = sampleStats.cv / calibratedCleanCv;
    }

    // ---------- Dynamic Clean-vs-Sample Difference Scoring ----------

    // Minimum tolerance based on clean signal size.
    // 0.02 = 2% tolerance floor.
    // With threshold 3.0, this means roughly 6% signal change is needed.
    float meanSpreadUsed = calibratedCleanMeanSpread;
    float meanSpreadFloor = fabs(calibratedCleanMean) * 0.02;

    if (meanSpreadUsed < meanSpreadFloor) {
      meanSpreadUsed = meanSpreadFloor;
    }

    // CV spread floor
    float cvSpreadUsed = calibratedCleanCvSpread;
    if (cvSpreadUsed < 0.000001) {
      cvSpreadUsed = 0.000001;
    }

    // Detect either direction of mean change.
    // This handles both lower transmission and increased scattered light.
    float meanDifferenceScore =
      fabs(sampleStats.mean - calibratedCleanMean) / meanSpreadUsed;

    // Only count CV increase as dirty.
    // Lower noise should not trigger dirty.
    float cvDifferenceScore =
      (sampleStats.cv - calibratedCleanCv) / cvSpreadUsed;

    if (cvDifferenceScore < 0) {
      cvDifferenceScore = 0;
    }

    // Use 3.0 instead of 5.0 for better sensitivity.
    const float DIRTY_DIFFERENCE_SCORE_THRESHOLD = 3.0;

    bool solutionIsDirty =
      (meanDifferenceScore > DIRTY_DIFFERENCE_SCORE_THRESHOLD) ||
      (cvDifferenceScore > DIRTY_DIFFERENCE_SCORE_THRESHOLD);

    // ---------- Stable Classification Decision ----------
    if (solutionIsDirty) {
      dirtyConsecutiveCount++;
      cleanConsecutiveCount = 0;
    }
    else {
      cleanConsecutiveCount++;
      dirtyConsecutiveCount = 0;
    }

    if (dirtyConsecutiveCount >= REQUIRED_CONSECUTIVE_WINDOWS) {
      ledStatus = LED_DIRTY;
    }

    if (cleanConsecutiveCount >= REQUIRED_CONSECUTIVE_WINDOWS) {
      ledStatus = LED_CLEAN;
    }

    Serial.println("\n[MEASUREMENT - SAMPLE SOLUTION]");

    Serial.println("----- Mean Signal -----");
    Serial.print("Calibrated Clean Mean: ");
    Serial.print(calibratedCleanMean, 2);

    Serial.print(" | Sample Mean: ");
    Serial.print(sampleStats.mean, 2);

    Serial.print(" | Mean Change: ");
    Serial.print(meanChangePercent, 3);
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

    Serial.println("----- Relative Optical Signal -----");
    Serial.print("Sample/Clean Signal Ratio: ");
    Serial.println(transmission, 4);

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