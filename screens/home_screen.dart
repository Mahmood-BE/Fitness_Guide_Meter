import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';
import '../widgets/emg_chart.dart';
import '../widgets/bluetooth_indicator.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    final peaks = ble.currentPeaks;

    return Scaffold(
appBar: AppBar(
  backgroundColor: AppColors.card,
  title: const Text("Fitness Guide Meter", style: TextStyle(color: Colors.white)),
  actions: const [
    Padding(
      padding: EdgeInsets.only(right: 16),
      child: BluetoothIndicator(),
    ),
  ],
),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        "Heart Rate",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        "${ble.heartRate.toStringAsFixed(0)} bpm",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        "SpO₂",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        "${ble.spo2.toStringAsFixed(1)} %",
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SizedBox(
                height: 200,
                child:
              ListView.builder(
                itemCount: 2,
                itemBuilder: (ctx, i) {
                  return Card(
                    color: AppColors.card,
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            'Channel ${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: EMGChart(data: ble.emgData[i], channel: i),
                          ),
                          Text(
                            'RMS: ${ble.rms(i).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          Text(
                            'VMC: ${(ble.emgData[i].isNotEmpty && peaks[i] != 0) 
                            ? ((ble.emgData[i].last / peaks[i]) * 100).toStringAsFixed(2) : 0}%',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
