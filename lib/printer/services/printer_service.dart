import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Abstract definition of the printer service to allow swap and testing mock implementations.
abstract class PrinterService {
  /// Stream of Bluetooth state changes.
  Stream<BluetoothState> get stateStream;

  /// Get current Bluetooth state.
  Future<BluetoothState> get currentState;

  /// List of scanned/bonded devices.
  Future<List<BluetoothDevice>> getBondedDevices();

  /// Check and request necessary permissions.
  Future<bool> checkAndRequestPermissions();

  /// Connect to a device.
  Future<void> connect(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 15),
  });

  /// Disconnect from the current device.
  Future<void> disconnect({Duration timeout = const Duration(seconds: 5)});

  /// Send commands/bytes to the printer.
  Future<void> sendBytes(
    List<int> bytes, {
    Duration timeout = const Duration(seconds: 10),
  });

  /// Connection state check.
  bool get isConnected;

  /// Stream of connection status changes (true if connected, false otherwise).
  Stream<bool> get isConnectedStream;

  /// Currently connected device.
  BluetoothDevice? get connectedDevice;

  /// Dispose resource subscriptions.
  void dispose();
}
