import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/printer_exceptions.dart';
import 'printer_service.dart';

/// Production implementation of [PrinterService] using [FlutterBluetoothSerial].
class BluetoothPrinterSerialImpl implements PrinterService {
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothState>? _stateSubscription;
  StreamSubscription<Uint8List>? _connectionInputSubscription;

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  BluetoothPrinterSerialImpl() {
    _init();
  }

  void _init() {
    _stateSubscription = FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen(
          (state) {
            log('Bluetooth state changed to: $state');
            if (state == BluetoothState.STATE_OFF && isConnected) {
              _handleDisconnect();
            }
          },
          onError: (e) {
            log('Error in Bluetooth state stream: $e');
          },
        );
  }

  @override
  Stream<BluetoothState> get stateStream =>
      FlutterBluetoothSerial.instance.onStateChanged();

  @override
  Future<BluetoothState> get currentState async {
    try {
      return await FlutterBluetoothSerial.instance.state;
    } catch (e) {
      log('Error getting current Bluetooth state: $e');
      return BluetoothState.UNKNOWN;
    }
  }

  @override
  bool get isConnected => _connection != null && _connection!.isConnected;

  @override
  Stream<bool> get isConnectedStream => _connectionStatusController.stream;

  @override
  BluetoothDevice? get connectedDevice => _connectedDevice;

  @override
  Future<bool> checkAndRequestPermissions() async {
    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
          log('Permission denied: $permission');
        }
      });

      return allGranted;
    } catch (e) {
      log('Error checking permissions: $e');
      return false;
    }
  }

  @override
  Future<List<BluetoothDevice>> getBondedDevices() async {
    final hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      throw const PrinterPermissionException(
        'يرجى منح جميع الأذونات المطلوبة لاستخدام البلوتوث',
      );
    }

    final btState = await currentState;
    if (btState != BluetoothState.STATE_ON) {
      throw const BluetoothDisabledException('يرجى تفعيل البلوتوث أولاً');
    }

    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      log('Error fetching bonded devices: $e');
      throw PrintFailedException('فشل الحصول على الأجهزة المقترنة', e);
    }
  }

  @override
  Future<void> connect(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      throw const PrinterPermissionException(
        'يرجى منح جميع الأذونات المطلوبة لاستخدام البلوتوث',
      );
    }

    final btState = await currentState;
    if (btState != BluetoothState.STATE_ON) {
      throw const BluetoothDisabledException('يرجى تفعيل البلوتوث أولاً');
    }

    // Disconnect existing if any
    if (isConnected) {
      await disconnect();
    }

    try {
      log('Connecting to device: ${device.name} (${device.address})');
      _connection = await BluetoothConnection.toAddress(device.address).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'انتهت مهلة الاتصال. تأكد من أن الجهاز قريب ومشغل.',
          );
        },
      );

      _connectedDevice = device;
      _connectionStatusController.add(true);
      log('Connected to ${device.name}');

      // Listen to input stream to detect disconnection by remote
      _connectionInputSubscription = _connection!.input?.listen(
        (data) {
          log('Data incoming from printer: ${String.fromCharCodes(data)}');
        },
        onDone: () {
          log('Connection closed by remote printer');
          _handleDisconnect();
        },
        onError: (error) {
          log('Connection stream error: $error');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } on TimeoutException catch (e) {
      _connection = null;
      _connectedDevice = null;
      _connectionStatusController.add(false);
      throw ConnectionTimeoutException(
        e.message ?? 'انتهت مهلة الاتصال بالبلوتوث',
      );
    } catch (e) {
      _connection = null;
      _connectedDevice = null;
      _connectionStatusController.add(false);
      log('Failed to connect: $e');
      throw ConnectionTimeoutException('فشل الاتصال بالطابعة: $e', e);
    }
  }

  @override
  Future<void> disconnect({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_connection == null) return;

    try {
      log('Disconnecting from ${_connectedDevice?.name}');
      await _connection!.close().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('انتهت مهلة قطع الاتصال');
        },
      );
    } on TimeoutException catch (e) {
      log('Disconnection timeout: $e');
      // Force status reset anyway
    } catch (e) {
      log('Error during disconnection: $e');
    } finally {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _connectionInputSubscription?.cancel();
    _connectionInputSubscription = null;
    _connection = null;
    _connectedDevice = null;
    _connectionStatusController.add(false);
    log('Connection status reset (disconnected)');
  }

  @override
  Future<void> sendBytes(
    List<int> bytes, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!isConnected) {
      throw const PrintFailedException('لا يوجد اتصال نشط بالطابعة');
    }

    try {
      log('Sending ${bytes.length} bytes to printer');
      _connection!.output.add(Uint8List.fromList(bytes));
      await _connection!.output.allSent.timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('انتهت مهلة إرسال البيانات إلى الطابعة');
        },
      );
      log('Bytes sent successfully');
    } on TimeoutException catch (e) {
      log('Timeout sending bytes: $e');
      throw PrintFailedException('انتهت مهلة الطباعة أثناء إرسال البيانات', e);
    } catch (e) {
      log('Error sending bytes: $e');
      throw PrintFailedException('فشل إرسال البيانات إلى الطابعة: $e', e);
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _connectionInputSubscription?.cancel();
    _connection?.close();
    _connectionStatusController.close();
  }
}
