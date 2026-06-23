import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothStatus extends StatelessWidget {
  final BluetoothState bluetoothState;
  final BluetoothDevice? selectedDevice;

  const BluetoothStatus({
    super.key,
    required this.bluetoothState,
    required this.selectedDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  bluetoothState == BluetoothState.STATE_ON
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: bluetoothState == BluetoothState.STATE_ON
                      ? Colors.blue
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'حالة البلوتوث: ${bluetoothState == BluetoothState.STATE_ON ? 'مفعل' : 'غير مفعل'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (selectedDevice != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'متصل بـ: ${selectedDevice!.name}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
