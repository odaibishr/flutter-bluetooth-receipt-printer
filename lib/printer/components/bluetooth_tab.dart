import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:printer_demo/printer/components/devices_list.dart';
import 'package:printer_demo/printer/components/bluetooth_status.dart';
import 'package:printer_demo/printer/components/scan_button.dart';
import 'package:printer_demo/printer/components/disconnect_button.dart';
import 'package:printer_demo/printer/components/cancel_operation_button.dart';

class BluetoothTab extends StatelessWidget {
  final BluetoothState bluetoothState;
  final BluetoothDevice? selectedDevice;
  final List<BluetoothDevice> devices;
  final bool isScanning;
  final bool isConnecting;
  final bool isDisconnecting;
  final bool isPrinting;
  final BluetoothDevice? connectingDevice;
  final bool isConnected;

  final VoidCallback onScanPressed;
  final ValueChanged<BluetoothDevice> onDevicePressed;
  final VoidCallback onDisconnectPressed;
  final VoidCallback onCancelOperationPressed;
  final VoidCallback onRetry;

  const BluetoothTab({
    super.key,
    required this.bluetoothState,
    required this.selectedDevice,
    required this.devices,
    required this.isScanning,
    required this.isConnecting,
    required this.isDisconnecting,
    required this.isPrinting,
    required this.connectingDevice,
    required this.isConnected,
    required this.onScanPressed,
    required this.onDevicePressed,
    required this.onDisconnectPressed,
    required this.onCancelOperationPressed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BluetoothStatus(
              bluetoothState: bluetoothState,
              selectedDevice: selectedDevice,
            ),

            const SizedBox(height: 16),

            // زر البحث عن الأجهزة
            ScanButton(
              bluetoothState: bluetoothState,
              isScanning: isScanning,
              isConnecting: isConnecting,
              isDisconnecting: isDisconnecting,
              isPrinting: isPrinting,
              onScanPressed: onScanPressed,
            ),

            const SizedBox(height: 16),

            DevicesList(
              devices: devices,
              bluetoothState: bluetoothState,
              selectedDevice: selectedDevice,
              isConnecting: isConnecting,
              connectingDevice: connectingDevice,
              isDisconnecting: isDisconnecting,
              isPrinting: isPrinting,
              onDevicePressed: onDevicePressed,
            ),

            // This button is used to disconnect from the printer only when connected to the printer
            if (isConnected)
              DisconnectButton(
                isDisconnecting: isDisconnecting,
                isPrinting: isPrinting,
                isConnecting: isConnecting,
                onDisconnectPressed: onDisconnectPressed,
              ),

            // This button is used to cancel any pending operation
            if (isDisconnecting || isPrinting || isConnecting)
              CancelOperationButton(
                onCancelOperationPressed: onCancelOperationPressed,
              ),
          ],
        ),
      );
    } catch (e) {
      log("Error building bluetooth tab: $e");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ في عرض صفحة البلوتوث',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
  }
}
