import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';
import '../widgets/bluetooth_indicator.dart';
import '../theme.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    setState(() => scanning = true);

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.isScanning.listen((state) {
      setState(() => scanning = state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ble = Provider.of<BLEProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text(
          "Available Devices",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.secondary),
                onPressed: _startScan,
              ),
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: BluetoothIndicator(),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ScanResult>>(
        stream: FlutterBluePlus.scanResults,
        initialData: const [],
        builder: (context, snapshot) {
          final results = snapshot.data ?? [];
          if (scanning && results.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            );
          }

          if (results.isEmpty) {
            return const Center(
              child: Text(
                "No devices found.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final r = results[index];
              final device = r.device;

              return Card(
                color: AppColors.card,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : "Unknown Device",
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    device.remoteId.str,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(
                    Icons.bluetooth,
                    color: AppColors.secondary,
                  ),
                  onTap: () async {
                    await ble.connectToDevice(device);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Connecting to ${device.platformName}...',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
