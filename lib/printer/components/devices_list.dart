import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class DevicesList extends StatelessWidget {
  final List<BluetoothDevice> devices;
  final BluetoothState bluetoothState;
  final BluetoothDevice? selectedDevice;
  final bool isConnecting;
  final BluetoothDevice? connectingDevice;
  final bool isDisconnecting;
  final bool isPrinting;
  final ValueChanged<BluetoothDevice> onDevicePressed;

  const DevicesList({
    super.key,
    required this.devices,
    required this.bluetoothState,
    required this.selectedDevice,
    required this.isConnecting,
    required this.connectingDevice,
    required this.isDisconnecting,
    required this.isPrinting,
    required this.onDevicePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bluetooth_searching,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد أجهزة مقترنة\nاضغط على زر البحث للعثور على الأجهزة',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (bluetoothState != BluetoothState.STATE_ON)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        'يرجى تفعيل البلوتوث أولاً',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                final bool isSelected =
                    selectedDevice?.address == device.address;
                final bool isConnectingDevice =
                    isConnecting &&
                    connectingDevice?.address == device.address;

                return Card(
                  color: isSelected ? Colors.blue.shade50 : null,
                  elevation: isSelected ? 3 : 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: isConnectingDevice
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.print,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                    title: Text(
                      device.name ?? 'جهاز غير معروف',
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(device.address),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: (isConnecting || isDisconnecting || isPrinting)
                        ? null
                        : () => onDevicePressed(device),
                  ),
                );
              },
            ),
    );
  }
}