import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEProvider with ChangeNotifier {
  final int emgChannels = 2; //2 EMG channels
  final int maxLength = 500; // Number of saved samples per channel
  //initial values
  List<double> baseline = [];
  bool baselineCaptured = false;
  bool isCalibrating = false;
  int baselineSampleCount = 200; // number of samples needed to detect baseline
  List<List<double>> baselineBuffer = [];

  List<List<double>> emgData = [];
  late List<double> currentPeaks;
  List<int> activeChannels = [0, 1];

  double heartRate = 0.0;
  double spo2 = 0.0;
  double _lastValidSpO2 = 0;
  double _lastValidHR = 0;

  static const double alphaHR = 0.2; // HR smoothing factor
  static const double alphaSpO2 = 0.15; // SpO2 smoothing factor

  bool isConnected = false;
  int reps = 0;
  bool _wasAboveThreshold = false;
  double _lastPeak = 0.0;

  double emgMax = 5.0; // Reference for normalization
  double hrRest = 70;
  double hrMax = 190;
  double lastWLI = 0.0;
  String feedback = "";

  BluetoothDevice? connectedDevice;
  BluetoothConnectionState deviceState = BluetoothConnectionState.disconnected;

  BLEProvider() {
    // Initialize channels with empty lists
    emgData = List.generate(emgChannels, (_) => []);
    currentPeaks = List.filled(emgChannels, emgMax * 2);
    baseline = List.filled(emgChannels, 0.0);
  }

  /// Returns RMS of the last samples for a channel
  double rms(int channel) {
    final list = emgData[channel];
    if (list.isEmpty) return 0.0;
    final sumSquares = list.fold(0.0, (prev, val) => prev + val * val);
    return sqrt(sumSquares / list.length);
  }

  /// Connect to BLE device and start listening for EMG data
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      connectedDevice = device;

      device.connectionState.listen((state) {
        deviceState = state;
        isConnected = state == BluetoothConnectionState.connected;
        notifyListeners();
      });

      await device.connect(autoConnect: false);
      final services = await device.discoverServices();

      // Example: find a characteristic that sends EMG CSV data starting with "E"
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.lastValueStream.listen((value) {
              final str = String.fromCharCodes(value);
              if (str.startsWith('E')) {
                _parseCSV(str.substring(2)); // Remove leading "E"
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('BLE connection error: $e');
    }
  }

  /// Parse CSV string from BLE and update EMG channels
  void _parseCSV(String csv) {
    try {
      final values = csv
          .split(',')
          .map((e) => double.tryParse(e.trim()) ?? 0.0)
          .toList();
      for (int i = 0; i < emgChannels && i < values.length; i++) {
        emgData[i].add(// adjust by baseline
          (values[i] - baseline[i]) * ((5 / (3.3 - baseline[i])).abs()),
        ); 
        if (emgData[i].length > maxLength) emgData[i].removeAt(0);
      }
      updateVitals(spo2, heartRate);
      heartRate = values[2];
      spo2 = values[3];
      updatePeaks(emgData);
      _detectReps();
      _computeWLI();
      Timer.periodic(const Duration(milliseconds: 40), (_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error parsing CSV: $e');
    }
  }

  double _smooth(double previous, double newValue, double alpha) {
    return (alpha * newValue) + ((1 - alpha) * previous);
  }

  void updateVitals(double newSpO2, double newHR) {
    //SpO2 Smooth and update
    if (newSpO2 != 0) {
      spo2 = _smooth(spo2, newSpO2, alphaSpO2);
      _lastValidSpO2 = spo2;
    } else {
      spo2 = _lastValidSpO2; // keep last value if BLE sends 0
    }

    //Heart Rate Smooth and update
    if (newHR != 0) {
      heartRate = _smooth(heartRate, newHR, alphaHR);
      _lastValidHR = heartRate;
    } else {
      heartRate = _lastValidHR;
    }
  }
  // detect and update peaks for each EMG channel
  void updatePeaks(List<List<double>> emgData) {
    for (int i = 0; i < emgData.length; i++) {
      if (emgData[i].isNotEmpty) {
        double peak = emgData[i].reduce((a, b) => a.abs() > b.abs() ? a : b);
        if (peak > emgMax * 0.5) {
          currentPeaks[i] = peak;
        }
      }
    }
  }

  void _detectReps({double threshold = 3.3}) {
    // Use the average of active EMG channels for rep detection
    if (activeChannels.isEmpty) return;
    double avgLatest =
        activeChannels
            .map((ch) => emgData[ch].isNotEmpty ? emgData[ch].last : 0.0)
            .fold(0.0, (a, b) => a + b) /
        activeChannels.length;

    if (avgLatest > threshold && !_wasAboveThreshold) {
      reps++;
      _lastPeak = avgLatest;
      _wasAboveThreshold = true;
    } else if (avgLatest < threshold * 0.7) {
      _wasAboveThreshold = false;
    }
  }

  void _computeWLI() {
    if (activeChannels.isEmpty) return;

    //Average RMS only across active channels
    double emgRms = 0.0;
    for (int ch in activeChannels) {
      emgRms += rms(ch);
    }
    emgRms /= activeChannels.length;

    //Normalization steps
    double emgNorm = (emgRms / emgMax) * 100;
    double hrNorm = ((heartRate - hrRest) / (hrMax - hrRest)) * 100;
    double spo2Norm = 100 - spo2;

    //Weighted WLI
    lastWLI = 0.5 * emgNorm + 0.3 * hrNorm + 0.2 * spo2Norm;

    //Feedback messages
    if (lastWLI < 40) {
      feedback = "Increase intensity.";
    } else if (lastWLI < 70) {
      feedback = "Maintain pace.";
    } else if (lastWLI > 70) {
      feedback = "Consider rest.";
    } else if (spo2Norm > 3) {
      feedback = "Stop & recover.";
    }
  }

  void resetReps() {
    reps = 0;
    notifyListeners();
  }

  void setActiveChannels(List<int> channels) {
    activeChannels = channels;
    notifyListeners();
  }

  void checkConnection() {
    if (connectedDevice != null) {
      deviceState = BluetoothConnectionState.connected;
    } else {
      deviceState = BluetoothConnectionState.disconnected;
    }
  }
  // Recalibrate baseline over a fixed duration
  void recalibrateBaseline() async {
    if (isCalibrating) return;
    isCalibrating = true;
    for (int i = 0; i < emgChannels; i++) {
      baseline[i] = 0.0;
    }
    notifyListeners();

    const calibrationDuration = Duration(seconds: 3);
    final endTime = DateTime.now().add(calibrationDuration);

    // Collect samples per channel
    List<List<double>> samplesPerChannel = List.generate(
      emgChannels,
      (_) => [],
    );

    while (DateTime.now().isBefore(endTime)) {
      for (int ch in activeChannels) {
        if (emgData[ch].isNotEmpty) {
          samplesPerChannel[ch].add(emgData[ch].last);
        }
      }
      await Future.delayed(const Duration(milliseconds: 20));
    }

    // Compute per-channel baseline averages for channels with samples
    for (int i = 0; i < emgChannels; i++) {
      if (samplesPerChannel[i].isNotEmpty) {
        double sum = samplesPerChannel[i].reduce((a, b) => a + b);
        baseline[i] = sum / samplesPerChannel[i].length;
      }
      // if no samples for a channel, keep existing baseline[i]
    }

    isCalibrating = false;
    notifyListeners();
  }
  // Check if device is connected
  bool get isDeviceConnected =>
      deviceState == BluetoothConnectionState.connected;
}
