import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';
import '../widgets/emg_chart.dart';
import '../theme.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final String workoutName;
  const WorkoutDetailsScreen({super.key, required this.workoutName});

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  bool isRunning = false;

  List<int> getActiveChannels() {
    if (widget.workoutName.toLowerCase().contains("biceps")) {
      return [0, 1];
    } else {
      return [0, 1];
    }
  }

  void _startWorkout(BLEProvider ble) {
    ble.setActiveChannels(getActiveChannels());
    ble.resetReps();
    ble.feedback = "Starting...";
    setState(() => isRunning = true);
  }

  void _stopWorkout() {
    setState(() => isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BLEProvider>(
      builder: (context, ble, child) {
        final activeCh = getActiveChannels();
        double contraction =
            (ble.rms(activeCh[0]) + ble.rms(activeCh[1])) /
            2 /
            ble.emgMax *
            100;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.card,
            title: Text(
              widget.workoutName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top info (Heart Rate, SpO2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoBox(
                      "Heart Rate",
                      "${ble.heartRate.toStringAsFixed(1)} bpm",
                    ),
                    _infoBox("SpO₂", "${ble.spo2.toStringAsFixed(1)}%"),
                  ],
                ),
                const SizedBox(height: 16),

                // Charts
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: activeCh.length,
                      itemBuilder: (context, i) {
                        int ch = activeCh[i];
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
                                  child: EMGChart(
                                    data: ble.emgData[ch].length > 500
                                        ? ble.emgData[ch].sublist(
                                            ble.emgData[ch].length - 500,
                                          )
                                        : ble.emgData[ch],
                                    channel: ch,
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
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Feedback: ${ble.feedback}",
                        style: TextStyle(
                          fontSize: 25,
                          color: ble.feedback.contains("Increase")
                              ? Colors.greenAccent
                              : ble.feedback.contains("rest")
                              ? Colors.orangeAccent
                              : ble.feedback.contains("Stop")
                              ? Colors.redAccent
                              : Colors.white,
                        ),
                      ),
                      Text(isRunning ? "Reps: ${ble.reps}" : "Workout Stopped",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            )
                          ),
                      const SizedBox(height: 6),
                      Text(
                        "Voluntary Contraction: ${contraction.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Workout Load Index: ${ble.lastWLI.toStringAsFixed(1)}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: isRunning ? null : () => _startWorkout(ble),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text("Start"),
                    ),
                    ElevatedButton(
                      onPressed: isRunning ? _stopWorkout : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text("Stop"),
                    ),
                    ElevatedButton(
                      onPressed: () => ble.resetReps(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                      ),
                      child: const Text("Reset"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
