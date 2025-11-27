#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>
#include <Wire.h>

#include "MAX30102_PulseOximeter.h"

// ==========================
// Configuration
// ==========================
#define ADC_PIN1        36         // ADC input pin (use GPIO34, GPIO35, etc.)
#define ADC_PIN2        39
#define ADC_PIN3        34
#define ADC_PIN4        35
#define SAMPLE_RATE    4000       // Sampling frequency (Hz)
#define DOWNSAMPLE     2          // Downsampling factor
#define LPF_ALPHA      0.05       // Low-pass IIR filter coefficient
#define DEVICE_NAME    "FGM_ESP32" // BLE device name
#define REPORTING_PERIOD_MS 1000
// ==========================
// BLE Globals
// ==========================
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic;
bool deviceConnected = false;

#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

// ==========================
// Signal Processing Variables
// ==========================
float lpfState1 = 0.0;
float lpfState2 = 0.0;

float envelopeRB = 0.0;
float envelopeLB = 0.0;

unsigned long lastMicros = 0;
unsigned long sampleInterval = 1000000 / SAMPLE_RATE;
PulseOximeter pox;
// ==========================
// BLE Callbacks
// ==========================
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
  }
};

// ==========================
// Simple IIR Low-pass Filter
// ==========================
float lowpassFilter1(float input) {
  lpfState1 = (1 - LPF_ALPHA) * lpfState1 + LPF_ALPHA * input;
  return lpfState1;
}
float lowpassFilter2(float input) {
  lpfState2 = (1 - LPF_ALPHA) * lpfState2 + LPF_ALPHA * input;
  return lpfState2;
}

// ==========================
// Setup BLE
// ==========================
void setupBLE() {
  BLEDevice::init(DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  BLEDevice::startAdvertising();
  Serial.println("BLE started. Waiting for connection...");
}

// ==========================
// Setup
// ==========================
void setup() {
  Serial.begin(115200);
  analogReadResolution(8);  // ESP32 ADC is 256
  setupBLE();
  Serial.println("Envelope detection with BLE started");
  if (!pox.begin()) {
    Serial.println("Oximeter FAILED");
    for (;;)
      ;
  } else {
    Serial.println("Oximeter SUCCESS");
  }
  pox.setIRLedCurrent(MAX30102_LED_CURR_11MA);
}

// ==========================
// Main Loop
// ==========================
void loop() {
  if (micros() - lastMicros >= sampleInterval) {
    lastMicros += sampleInterval;
    //update oximeter
    pox.update();

    // Step 1: Read analog input
    int rawRB = analogRead(ADC_PIN1);
    int rawLB = analogRead(ADC_PIN2);

    // Step 2: Square the signal
    float squaredRB = rawRB * rawRB ;
    float squaredLB = rawLB * rawLB ;

    // Step 3: Low-pass filter
    float filteredRB = lowpassFilter1(squaredRB);
    float filteredLB = lowpassFilter2(squaredLB);

    // Step 4: Downsample
    static int decimCount = 0;
    decimCount++;
    if (decimCount >= DOWNSAMPLE) {
      decimCount = 0;

      // Step 5: Square root
    float  rootRB = sqrtf(fmax(filteredRB, 0.0));
    float  rootLB = sqrtf(fmax(filteredLB, 0.0));

      // Step 6: normailze
      envelopeRB = (rootRB/255)*3.3 ;
      envelopeLB = (rootLB/255)*3.3 ;

      // Step 7: Transmit over BLE
      if (deviceConnected) {
        char buffer[64];
        snprintf(buffer, sizeof(buffer), "E,%.2f,%.2f,%0.2f,%d", envelopeRB, envelopeLB, pox.getHeartRate(), pox.getSpO2());
        pCharacteristic->setValue(buffer);
        pCharacteristic->notify();
        //Serial.println(buffer); //used for debugging
      }
    }
  }
}
