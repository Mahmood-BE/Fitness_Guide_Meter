import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/ble_provider.dart';
import '../theme.dart';

class BluetoothIndicator extends StatelessWidget {
  const BluetoothIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BLEProvider>(
      builder: (context, ble, _) {
        final isConnected = ble.deviceState == BluetoothConnectionState.connected;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: isConnected ? AppColors.secondary : Colors.redAccent,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isConnected ? "Connected" : "Disconnected",
              style: TextStyle(
                color: isConnected ? AppColors.secondary : Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
