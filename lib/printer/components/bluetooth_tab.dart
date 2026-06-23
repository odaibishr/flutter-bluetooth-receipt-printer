import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:printer_demo/printer/components/devices_list.dart';
import 'package:printer_demo/printer/components/bluetooth_status.dart';
import 'package:printer_demo/printer/components/scan_button.dart';

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

            // قائمة الأجهزة
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

            // زر قطع الاتصال - يظهر فقط عند وجود اتصال
            if (isConnected) _buildDisconnectButton(),

            // زر إلغاء العمليات العالقة - يظهر فقط عند وجود عمليات جارية
            if (isDisconnecting || isPrinting || isConnecting)
              _buildCancelOperationButton(),
          ],
        ),
      );
    } catch (e) {
      log("خطأ في بناء علامة تبويب البلوتوث: $e");
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

  // بناء زر إلغاء العمليات العالقة
  Widget _buildCancelOperationButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton.icon(
        onPressed: onCancelOperationPressed,
        icon: const Icon(Icons.cancel),
        label: const Text('إلغاء العملية الحالية'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      ),
    );
  }




  // بناء زر قطع الاتصال
  Widget _buildDisconnectButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton.icon(
        onPressed: isDisconnecting || isPrinting || isConnecting
            ? null
            : onDisconnectPressed,
        icon: isDisconnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.bluetooth_disabled),
        label: Text(isDisconnecting ? 'جاري قطع الاتصال...' : 'قطع الاتصال'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      ),
    );
  }
}
