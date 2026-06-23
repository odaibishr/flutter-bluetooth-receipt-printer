import 'dart:async'; // Add async library for handling timeouts
import 'dart:developer';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:printer_demo/printer/components/invoice_tab.dart';
import 'package:printer_demo/printer/components/bluetooth_tab.dart';
import 'package:printer_demo/printer/models/receipt_data.dart';
import 'package:screenshot/screenshot.dart';

class Printer extends StatefulWidget {
  final ReceiptData receiptData;
  final PaperSize paperSize;

  const Printer({
    super.key,
    required this.receiptData,
    this.paperSize = PaperSize.mm80,
  });

  @override
  State<Printer> createState() => _PrinterState();
}

class _PrinterState extends State<Printer> with TickerProviderStateMixin {
  // Controller for screenshot
  final ScreenshotController _screenshotController = ScreenshotController();

  // Bluetooth connection state
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? _connection;
  CapabilityProfile? _capabilityProfile;
  StreamSubscription<BluetoothState>? _bluetoothStateSubscription;

  Future<CapabilityProfile> _getCapabilityProfile() async {
    _capabilityProfile ??= await CapabilityProfile.load();
    return _capabilityProfile!;
  }

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;

  bool _isConnecting = false;
  bool _isDisconnecting = false;
  bool _isScanning = false;
  bool _isPrinting = false;

  BluetoothDevice? _connectingDevice;

  Timer? _disconnectionTimer;
  Timer? _printingTimer;
  Timer? _connectionTimer;
  Timer? _scanningTimer;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    try {
      _tabController = TabController(length: 2, vsync: this);

      _initBluetooth();
    } catch (e) {
      log("خطأ في تهيئة الصفحة: $e");
      _showErrorToast("خطأ في تهيئة الصفحة: $e");
    }
  }

  Future<void> _initBluetooth() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
          log("لم يتم منح إذن: $permission");
        }
      });

      if (!allGranted) {
        _showErrorToast("يرجى منح جميع الأذونات المطلوبة لاستخدام البلوتوث");
        return;
      }

      FlutterBluetoothSerial.instance.state
          .then((state) {
            if (mounted) {
              setState(() {
                _bluetoothState = state;
              });
            }
          })
          .catchError((e) {
            log("خطأ في الحصول على حالة البلوتوث: $e");
            _showErrorToast("خطأ في الحصول على حالة البلوتوث");
          });

      _bluetoothStateSubscription = FlutterBluetoothSerial.instance
          .onStateChanged()
          .listen(
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
              log("خطأ في الاستماع لتغييرات البلوتوث: $e");
            },
          );
    } catch (e) {
      log("خطأ في تهيئة البلوتوث: $e");
      _showErrorToast("خطأ في تهيئة البلوتوث: $e");
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
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
      timeInSecForIosWeb: 1,
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
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _cancelAllTimers() {
    try {
      _disconnectionTimer?.cancel();
      _printingTimer?.cancel();
      _connectionTimer?.cancel();
      _scanningTimer?.cancel();
    } catch (e) {
      log("خطأ في إلغاء المؤقتات: $e");
    }
  }

  void _cancelOperation() {
    _cancelAllTimers();

    if (_isDisconnecting) {
      setState(() {
        _connection = null;
        _selectedDevice = null;
        _isDisconnecting = false;
      });
      _showInfoToast('تم إلغاء عملية قطع الاتصال');
    }

    if (_isPrinting) {
      setState(() {
        _isPrinting = false;
      });
      _showInfoToast('تم إلغاء عملية الطباعة');
    }

    if (_isConnecting) {
      setState(() {
        _isConnecting = false;
        _connectingDevice = null;
      });
      _showInfoToast('تم إلغاء عملية الاتصال');
    }
  }

  Future<void> _scanDevices() async {
    if (_bluetoothState != BluetoothState.STATE_ON) {
      _showErrorToast("يرجى تفعيل البلوتوث أولاً");
      return;
    }

    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _devices = [];
    });

    _scanningTimer?.cancel();

    try {
      _scanningTimer = Timer(const Duration(seconds: 15), () {
        log('Scanning timeout - forcing completion');
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
          _showInfoToast('تم إلغاء عملية البحث بسبب انتهاء المهلة');
        }
      });

      // _showLoadingToast('Searching for devices...');

      _devices = await FlutterBluetoothSerial.instance
          .getBondedDevices()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('انتهت مهلة البحث عن الأجهزة');
            },
          );

      _scanningTimer?.cancel();

      if (_devices.isEmpty) {
        _showInfoToast(
          'لم يتم العثور على أجهزة مقترنة. يرجى اقتران الطابعة من إعدادات البلوتوث أولاً.',
        );
      } else {
        _showSuccessToast('تم العثور على ${_devices.length} جهاز');
      }
    } catch (e) {
      log("Error scanning devices: $e");
      _showErrorToast('فشل البحث عن الأجهزة: $e');
    } finally {
      _scanningTimer?.cancel();

      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_bluetoothState != BluetoothState.STATE_ON) {
      _showErrorToast("يرجى تفعيل البلوتوث أولاً");
      return;
    }

    if (_isConnecting) return;

    if (_connection != null) {
      try {
        await _disconnectFromDevice();
      } catch (e) {
        log("خطأ في قطع الاتصال السابق: $e");
      }
    }

    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
      _connectingDevice = device;
    });

    _connectionTimer?.cancel();

    try {
      _connectionTimer = Timer(const Duration(seconds: 15), () {
        log('Connection timeout - forcing completion');
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _connectingDevice = null;
            if (_connection == null) {
              _selectedDevice = null;
            }
          });
          _showInfoToast('تم إلغاء عملية الاتصال بسبب انتهاء المهلة');
        }
      });

      // _showLoadingToast('Connecting to device ${device.name}...');

      _connection = await BluetoothConnection.toAddress(device.address).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'انتهت مهلة الاتصال. تأكد من أن الجهاز قريب ومشغل.',
          );
        },
      );

      _connectionTimer?.cancel();

      log('Connected to the device');

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingDevice = null;
        });
      }

      _showSuccessToast('تم الاتصال بجهاز ${device.name}');

      _connection?.input?.listen(
        (Uint8List data) {
          log('Data incoming: ${String.fromCharCodes(data)}');
        },
        onError: (error) {
          log('Connection input error: $error');
          if (mounted) {
            setState(() {
              _connection = null;
              _selectedDevice = null;
            });
            _showErrorToast('انقطع الاتصال بسبب خطأ: $error');
          }
        },
        onDone: () {
          log('Connection closed by remote');
          if (mounted) {
            setState(() {
              _connection = null;
              _selectedDevice = null;
            });
            _showInfoToast('تم قطع الاتصال من قبل الجهاز');
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      log('Cannot connect, exception occurred: $e');

      _connectionTimer?.cancel();

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingDevice = null;
          if (_connection == null) {
            _selectedDevice = null;
          }
        });
      }

      // Show error message
      _showErrorToast('فشل الاتصال: $e');
    }
  }

  // Disconnect from the current device
  Future<void> _disconnectFromDevice() async {
    // Check if a connection exists
    if (_connection == null) {
      _showInfoToast('لا يوجد اتصال حالي');
      return;
    }

    // Prevent multiple disconnection attempts
    if (_isDisconnecting) return;

    // Save the device name before disconnect to use in messages
    final deviceName = _selectedDevice?.name ?? 'الجهاز';

    // Update disconnection status
    if (mounted) {
      setState(() {
        _isDisconnecting = true;
      });
    }

    // Cancel any previous timer
    _disconnectionTimer?.cancel();

    try {
      // Create a timer to force disconnection if it takes too long
      _disconnectionTimer = Timer(const Duration(seconds: 5), () {
        log('Disconnection timeout - forcing disconnect');

        // Forcefully reset connection state
        if (mounted) {
          setState(() {
            _connection = null;
            _selectedDevice = null;
            _isDisconnecting = false;
          });
        }

        // Show message
        _showInfoToast('تم قطع الاتصال بـ $deviceName (بعد انتهاء المهلة)');
      });

      // Show disconnection message
      // _showLoadingToast('Disconnecting from $deviceName...');

      // Try to disconnect normally with a timeout
      await _connection?.close().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('انتهت مهلة قطع الاتصال');
        },
      );

      // Cancel the timer since the operation succeeded
      _disconnectionTimer?.cancel();

      // Update status after disconnection
      if (mounted) {
        setState(() {
          _connection = null;
          _selectedDevice = null;
          _isDisconnecting = false;
        });
      }

      // Show success disconnection toast
      _showInfoToast('تم قطع الاتصال بـ $deviceName');
    } catch (e) {
      log('Error disconnecting: $e');

      // Cancel the timer since the operation ended (success or failure)
      _disconnectionTimer?.cancel();

      // Forcefully reset connection state on error
      if (mounted) {
        setState(() {
          _connection = null;
          _selectedDevice = null;
          _isDisconnecting = false;
        });
      }

      // Show error message
      _showErrorToast('تم قطع الاتصال بـ $deviceName (مع حدوث خطأ: $e)');
    }
  }

  // Capture receipt screenshot and print it
  Future<void> _captureAndPrint() async {
    // Check Bluetooth power state
    if (_bluetoothState != BluetoothState.STATE_ON) {
      _showErrorToast("يرجى تفعيل البلوتوث أولاً");
      return;
    }

    // Prevent multiple printing attempts
    if (_isPrinting) return;

    // Check if connected to a printer
    if (_connection == null || _selectedDevice == null) {
      _showErrorToast('يرجى الاتصال بطابعة أولاً');
      return;
    }

    // Update printing state
    setState(() {
      _isPrinting = true;
    });

    // Cancel any previous timer
    _printingTimer?.cancel();

    try {
      // Create a timer to force print completion if it takes too long
      _printingTimer = Timer(const Duration(seconds: 30), () {
        log('Printing timeout - forcing completion');

        // Reset printing state
        if (mounted) {
          setState(() {
            _isPrinting = false;
          });
        }

        // Show info message
        _showInfoToast(
          'تم إلغاء عملية الطباعة بسبب انتهاء المهلة. يرجى المحاولة مرة أخرى.',
        );
      });

      // Show receipt preparation message
      // _showLoadingToast('Preparing invoice for printing...');

      // Define print width based on paper size
      final PaperSize paperSize = widget.paperSize;
      final int printWidth = paperSize == PaperSize.mm80 ? 576 : 384;

      // Calculate pixelRatio to match printer width
      // The container width in code is InvoiceTab.receiptWidth logical points
      final double targetPixelRatio = printWidth / InvoiceTab.receiptWidth;

      // Capture invoice image with timeout and printing quality
      final Uint8List? imageBytes = await _screenshotController
          .capture(pixelRatio: targetPixelRatio)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('انتهت مهلة التقاط صورة الفاتورة');
            },
          );

      if (imageBytes == null) {
        throw Exception('فشل التقاط صورة الفاتورة');
      }

      // Show data transmission message
      // _showLoadingToast('Sending invoice to printer...');

      // Convert image to suitable format
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('فشل تحويل الصورة');
      }

      // Since image is captured at target resolution, no resize is needed
      final img.Image resizedImage = image.width == printWidth
          ? image
          : img.copyResize(image, width: printWidth);

      // Generate ESC/POS commands for the printer
      final profile = await _getCapabilityProfile();
      final generator = Generator(
        paperSize,
        profile,
      );
      final List<int> bytes = [];

      // Add image
      bytes.addAll(generator.image(resizedImage));

      // Cut paper
      bytes.addAll(generator.cut());

      // Check connection status before sending data
      if (_connection == null || !mounted) {
        throw Exception('تم فقدان الاتصال بالطابعة');
      }

      // Send data to printer with timeout
      _connection!.output.add(Uint8List.fromList(bytes));

      // Wait for data to be completely sent
      bool dataSent = false;
      try {
        await _connection!.output.allSent.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('انتهت مهلة إرسال البيانات إلى الطابعة');
          },
        );
        dataSent = true;
      } catch (e) {
        log('Error waiting for data to be sent: $e');
        throw Exception('فشل إرسال البيانات إلى الطابعة: $e');
      }

      // Cancel the timer because the operation has finished (success or failure)
      _printingTimer?.cancel();

      // Update the print state
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }

      // Show success message
      if (dataSent) {
        _showSuccessToast('تمت الطباعة بنجاح');
      }
    } catch (e) {
      log('Error printing: $e');

      // Cancel the timer because the operation has finished (success or failure)
      _printingTimer?.cancel();

      // Update the print state
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }

      // Show error message
      _showErrorToast('فشل الطباعة: $e');
    }
  }


  @override
  void dispose() {
    try {
      // Cancel all timers
      _cancelAllTimers();

      // Cancel Bluetooth subscriptions to prevent memory leak
      _bluetoothStateSubscription?.cancel();

      // Disconnect from the device without updating the UI
      if (_connection != null) {
        _connection?.close();
        _connection = null;
      }
      _tabController.dispose();
    } catch (e) {
      log("خطأ في dispose: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // The invoice tab
          InvoiceTab(
            receiptData: widget.receiptData,
            screenshotController: _screenshotController,
            isPrinting: _isPrinting,
            isConnected: _connection != null,
            onPrintPressed: _captureAndPrint,
            onRetry: () => setState(() {}),
          ),

          // The bluetooth tab
          BluetoothTab(
            bluetoothState: _bluetoothState,
            selectedDevice: _selectedDevice,
            devices: _devices,
            isScanning: _isScanning,
            isConnecting: _isConnecting,
            isDisconnecting: _isDisconnecting,
            isPrinting: _isPrinting,
            connectingDevice: _connectingDevice,
            isConnected: _connection != null,
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
