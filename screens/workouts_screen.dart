import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'workout_details_screen.dart';
import '../widgets/bluetooth_indicator.dart';
import '../providers/ble_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String? selectedWorkout;

  final List<String> workouts = ["Biceps", "Chest"];
  Future<void> exportEMGCSV(BuildContext context) async {
    final ble = Provider.of<BLEProvider>(context, listen: false);

    // Request storage permission (Android)
    final status = await Permission.storage.request();
    if (!context.mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
      return;
    }

    // Build CSV header
    final buffer = StringBuffer();
    buffer.writeln("Sample,CH1,CH2,HeartRate,SpO2");

    // Determine number of samples
    int maxSamples = 500;

    for (int i = 0; i < maxSamples; i++) {
      final ch1 = ble.emgData[0].length > i ? ble.emgData[0][i] : 0.0;
      final ch2 = ble.emgData[1].length > i ? ble.emgData[1][i] : 0.0;


      buffer.writeln("$i,$ch1,$ch2,${ble.heartRate},${ble.spo2}");
    }

    final downloadPath = "/storage/emulated/0/Download/FGM_Logs";
    final now = DateTime.now();
    final formattedName =
        "${now.year}"
        "-${now.month.toString().padLeft(2, '0')}"
        "-${now.day.toString().padLeft(2, '0')}_"
        "${now.hour.toString().padLeft(2, '0')}"
        "-${now.minute.toString().padLeft(2, '0')}"
        "-${now.second.toString().padLeft(2, '0')}";

    final file = File("$downloadPath/FGM_Log_$formattedName.csv");

    await file.writeAsString(buffer.toString(), encoding: utf8);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("CSV Exported: ${file.path}")));
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Workouts"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: BluetoothIndicator(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedWorkout,
              decoration: const InputDecoration(
                labelText: "Select Workout",
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF1A1F3A),
              items: workouts.map((workout) {
                return DropdownMenuItem(
                  value: workout,
                  child: Text(
                    workout,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedWorkout = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedWorkout == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutDetailsScreen(
                            workoutName: selectedWorkout!,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Select Workout Details"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ble.recalibrateBaseline();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                ble.isCalibrating
                    ? "Calibrating... Stay still"
                    : "Recalibrate Baseline",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await exportEMGCSV(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Export Last 500 Samples",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
