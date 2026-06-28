import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' show PaperSize;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:screenshot/screenshot.dart';

import 'components/invoice_tab.dart';
import 'components/bluetooth_tab.dart';
import 'models/receipt_data.dart';
import 'models/printer_exceptions.dart';
import 'services/printer_service.dart';
import 'services/bluetooth_printer_serial_impl.dart';
import 'services/receipt_encoder.dart';

class Printer extends StatefulWidget {
  final ReceiptData receiptData;
  final PaperSize paperSize;
  final PrinterService? printerService;
  final ReceiptEncoder? receiptEncoder;

  const Printer({
    super.key,
    required this.receiptData,
    this.paperSize = PaperSize.mm80,
    this.printerService,
    this.receiptEncoder,
  });

  @override
  State<Printer> createState() => _PrinterState();
}

class _PrinterState extends State<Printer> with TickerProviderStateMixin {
  // Controller for screenshot
  final ScreenshotController _screenshotController = ScreenshotController();

  // Decoupled services
  late final PrinterService _printerService;
  late final ReceiptEncoder _receiptEncoder;

  // Subscriptions
  StreamSubscription<BluetoothState>? _btStateSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  // UI State
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  BluetoothDevice? _connectingDevice;

  bool _isConnecting = false;
  bool _isDisconnecting = false;
  bool _isScanning = false;
  bool _isPrinting = false;
  bool _hasPrintedOnce = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    try {
      _tabController = TabController(length: 2, vsync: this);

      // Initialize services (default to serial impl if not provided)
      _printerService = widget.printerService ?? BluetoothPrinterSerialImpl();
      _receiptEncoder = widget.receiptEncoder ?? ReceiptEncoder();

      _initBluetooth();
    } catch (e) {
      log("Error initializing page: $e");
      _showErrorToast("خطأ في تهيئة الصفحة: $e");
    }
  }

  Future<void> _initBluetooth() async {
    try {
      // Check and request permissions through the service
      final hasPermissions = await _printerService.checkAndRequestPermissions();
      if (!hasPermissions) {
        _showErrorToast("يرجى منح جميع الأذونات المطلوبة لاستخدام البلوتوث");
        return;
      }

      // Read initial state
      _bluetoothState = await _printerService.currentState;
      if (mounted) setState(() {});

      // Listen to Bluetooth hardware state changes
      _btStateSubscription = _printerService.stateStream.listen(
        (state) {
          if (mounted) {
            setState(() {
              _bluetoothState = state;
            });

            if (state == BluetoothState.STATE_OFF) {
              _showInfoToast("تم إيقاف تشغيل البلوتوث");
            } else if (state == BluetoothState.STATE_ON) {
              _showInfoToast("تم تشغيل البلوتوث");
            }
          }
        },
        onError: (e) {
          log("Error listening to Bluetooth changes: $e");
        },
      );

      // Listen to connection status changes
      _connectionSubscription = _printerService.isConnectedStream.listen(
        (isConnected) {
          if (mounted) {
            setState(() {
              _selectedDevice = isConnected ? _printerService.connectedDevice : null;
            });
          }
        },
        onError: (e) {
          log("Error listening to connection state: $e");
        },
      );
    } catch (e) {
      log("Error initializing Bluetooth: $e");
      _showErrorToast("خطأ في تهيئة البلوتوث: $e");
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showInfoToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _cancelOperation() {
    setState(() {
      _isConnecting = false;
      _isDisconnecting = false;
      _isPrinting = false;
      _connectingDevice = null;
    });
    _showInfoToast("تم إلغاء العملية");
  }

  Future<void> _scanDevices() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      _devices = await _printerService.getBondedDevices();

      if (_devices.isEmpty) {
        _showInfoToast("لم يتم العثور على أجهزة مقترنة. يرجى اقتران الطابعة من إعدادات البلوتوث أولاً.");
      } else {
        _showSuccessToast("تم العثور على أجهزة مقترنة: ${_devices.length}");
      }
    } on PrinterException catch (e) {
      _showErrorToast(e.message);
    } catch (e) {
      log("Error scanning devices: $e");
      _showErrorToast('لم يتم العثور على أجهزة مقترنة: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _connectingDevice = device;
      _selectedDevice = device;
    });

    try {
      await _printerService.connect(device);
      _showSuccessToast("تم الاتصال بنجاح: ${device.name}");
    } on PrinterException catch (e) {
      _showErrorToast(e.message);
      if (mounted) {
        setState(() {
          _selectedDevice = null;
        });
      }
    } catch (e) {
      log('Cannot connect: $e');
      _showErrorToast('فشل الاتصال: $e');
      if (mounted) {
        setState(() {
          _selectedDevice = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingDevice = null;
        });
      }
    }
  }

  Future<void> _disconnectFromDevice() async {
    if (_isDisconnecting) return;

    final deviceName = _selectedDevice?.name ?? 'الطابعة';

    setState(() {
      _isDisconnecting = true;
    });

    try {
      await _printerService.disconnect();
      _showInfoToast("تم قطع الاتصال بـ $deviceName");
    } on PrinterException catch (e) {
      _showErrorToast(e.message);
    } catch (e) {
      log('Error disconnecting: $e');
      _showErrorToast('خطأ أثناء قطع الاتصال: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDisconnecting = false;
        });
      }
    }
  }

  Future<void> _captureAndPrint() async {
    if (_isPrinting) return;

    if (_hasPrintedOnce) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('تأكيد الطباعة', textAlign: TextAlign.right),
            content: const Text(
              'لقد قمت بطباعة هذه الفاتورة مسبقاً. هل تريد طباعتها مرة أخرى؟',
              textAlign: TextAlign.right,
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('نعم، طباعة', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (confirm != true) {
        return;
      }
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      // Define print width based on paper size
      final PaperSize paperSize = widget.paperSize;
      final int printWidth = paperSize == PaperSize.mm80 ? 576 : 384;

      // Calculate pixelRatio to match printer width
      final double targetPixelRatio = printWidth / InvoiceTab.receiptWidth;

      // Capture receipt widget screenshot
      final Uint8List? imageBytes = await _screenshotController
          .capture(pixelRatio: targetPixelRatio)
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException("انتهت مهلة التقاط صورة الفاتورة");
        },
      );

      if (imageBytes == null) {
        throw const PrintFailedException("فشل التقاط صورة الفاتورة");
      }

      // Convert image bytes to ESC/POS bytes
      final List<int> escPosBytes = await _receiptEncoder.encodeImageToEscPos(
        imageBytes,
        paperSize: paperSize,
      );

      // Send to printer
      await _printerService.sendBytes(escPosBytes);
      _hasPrintedOnce = true;
      _showSuccessToast("تمت الطباعة بنجاح");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الانتهاء من الطباعة بنجاح', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on PrinterException catch (e) {
      _showErrorToast(e.message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الطباعة: ${e.message}', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      log('Error printing: $e');
      _showErrorToast('فشل الطباعة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الطباعة: $e', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      _btStateSubscription?.cancel();
      _connectionSubscription?.cancel();
      
      // If we initialized the default instance, dispose it.
      if (widget.printerService == null) {
        _printerService.dispose();
      }

      _tabController.dispose();
    } catch (e) {
      log("Error in dispose: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnected = _printerService.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام الفواتير والطباعة'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الفاتورة', icon: Icon(Icons.receipt)),
            Tab(text: 'البلوتوث', icon: Icon(Icons.bluetooth)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          InvoiceTab(
            receiptData: widget.receiptData,
            screenshotController: _screenshotController,
            isPrinting: _isPrinting,
            isConnected: isConnected,
            onPrintPressed: _captureAndPrint,
            onRetry: () => setState(() {}),
            hasPrintedOnce: _hasPrintedOnce,
          ),
          BluetoothTab(
            bluetoothState: _bluetoothState,
            selectedDevice: _selectedDevice,
            devices: _devices,
            isScanning: _isScanning,
            isConnecting: _isConnecting,
            isDisconnecting: _isDisconnecting,
            isPrinting: _isPrinting,
            connectingDevice: _connectingDevice,
            isConnected: isConnected,
            onScanPressed: _scanDevices,
            onDevicePressed: _connectToDevice,
            onDisconnectPressed: _disconnectFromDevice,
            onCancelOperationPressed: _cancelOperation,
            onRetry: () => setState(() {}),
          ),
        ],
      ),
    );
  }
}
