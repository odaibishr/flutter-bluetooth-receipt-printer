import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ScanButton extends StatelessWidget {
  final BluetoothState bluetoothState;
  final bool isScanning;
  final bool isConnecting;
  final bool isDisconnecting;
  final bool isPrinting;
  final VoidCallback onScanPressed;

  const ScanButton({
    super.key,
    required this.bluetoothState,
    required this.isScanning,
    required this.isConnecting,
    required this.isDisconnecting,
    required this.isPrinting,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: bluetoothState == BluetoothState.STATE_ON &&
              !isScanning &&
              !isConnecting &&
              !isDisconnecting &&
              !isPrinting
          ? onScanPressed
          : null,
      icon: isScanning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.search),
      label: Text(isScanning ? 'جاري البحث...' : 'بحث عن الأجهزة'),
    );
  }
}
