import 'dart:async'; // إضافة مكتبة async للتعامل مع المهلات الزمنية
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
  const Printer({super.key, required this.receiptData});

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

      // _showLoadingToast('جاري البحث عن الأجهزة...');

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

      // _showLoadingToast('جاري الاتصال بجهاز ${device.name}...');

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

      // إظهار رسالة خطأ
      _showErrorToast('فشل الاتصال: $e');
    }
  }

  // قطع الاتصال بالجهاز الحالي
  Future<void> _disconnectFromDevice() async {
    // التحقق من وجود اتصال
    if (_connection == null) {
      _showInfoToast('لا يوجد اتصال حالي');
      return;
    }

    // منع محاولات قطع الاتصال المتعددة
    if (_isDisconnecting) return;

    // حفظ اسم الجهاز قبل قطع الاتصال لاستخدامه في الرسائل
    final deviceName = _selectedDevice?.name ?? 'الجهاز';

    // تحديث حالة قطع الاتصال
    if (mounted) {
      setState(() {
        _isDisconnecting = true;
      });
    }

    // إلغاء أي مؤقت سابق
    _disconnectionTimer?.cancel();

    try {
      // إنشاء مؤقت لإنهاء عملية قطع الاتصال إذا استغرقت وقتاً طويلاً
      _disconnectionTimer = Timer(const Duration(seconds: 5), () {
        log('Disconnection timeout - forcing disconnect');

        // إعادة تعيين حالة الاتصال بالقوة
        if (mounted) {
          setState(() {
            _connection = null;
            _selectedDevice = null;
            _isDisconnecting = false;
          });
        }

        // إظهار رسالة
        _showInfoToast('تم قطع الاتصال بـ $deviceName (بعد انتهاء المهلة)');
      });

      // إظهار رسالة قطع الاتصال
      // _showLoadingToast('جاري قطع الاتصال بـ $deviceName...');

      // محاولة قطع الاتصال بشكل طبيعي مع مهلة زمنية
      await _connection?.close().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('انتهت مهلة قطع الاتصال');
        },
      );

      // إلغاء المؤقت لأن العملية نجحت
      _disconnectionTimer?.cancel();

      // تحديث الحالة بعد قطع الاتصال
      if (mounted) {
        setState(() {
          _connection = null;
          _selectedDevice = null;
          _isDisconnecting = false;
        });
      }

      // إظهار رسالة نجاح قطع الاتصال
      _showInfoToast('تم قطع الاتصال بـ $deviceName');
    } catch (e) {
      log('Error disconnecting: $e');

      // إلغاء المؤقت لأن العملية انتهت (بنجاح أو فشل)
      _disconnectionTimer?.cancel();

      // إعادة تعيين حالة الاتصال بالقوة في حالة الخطأ
      if (mounted) {
        setState(() {
          _connection = null;
          _selectedDevice = null;
          _isDisconnecting = false;
        });
      }

      // إظهار رسالة خطأ
      _showErrorToast('تم قطع الاتصال بـ $deviceName (مع حدوث خطأ: $e)');
    }
  }

  // التقاط صورة الفاتورة وطباعتها
  Future<void> _captureAndPrint() async {
    // التحقق من حالة البلوتوث
    if (_bluetoothState != BluetoothState.STATE_ON) {
      _showErrorToast("يرجى تفعيل البلوتوث أولاً");
      return;
    }

    // منع محاولات الطباعة المتعددة
    if (_isPrinting) return;

    // التحقق من وجود اتصال بالطابعة
    if (_connection == null || _selectedDevice == null) {
      _showErrorToast('يرجى الاتصال بطابعة أولاً');
      return;
    }

    // تحديث حالة الطباعة
    setState(() {
      _isPrinting = true;
    });

    // إلغاء أي مؤقت سابق
    _printingTimer?.cancel();

    try {
      // إنشاء مؤقت لإنهاء عملية الطباعة إذا استغرقت وقتاً طويلاً
      _printingTimer = Timer(const Duration(seconds: 30), () {
        log('Printing timeout - forcing completion');

        // إعادة تعيين حالة الطباعة
        if (mounted) {
          setState(() {
            _isPrinting = false;
          });
        }

        // إظهار رسالة
        _showInfoToast(
          'تم إلغاء عملية الطباعة بسبب انتهاء المهلة. يرجى المحاولة مرة أخرى.',
        );
      });

      // إظهار رسالة تجهيز الفاتورة
      // _showLoadingToast('جاري تجهيز الفاتورة للطباعة...');

      // تحديد عرض الطباعة بناءً على حجم الورق
      const PaperSize paperSize = PaperSize.mm80;
      final int printWidth = paperSize == PaperSize.mm80 ? 576 : 384;

      // حساب معامل تكبير الصورة (pixelRatio) ليكون حجم الصورة الملتقطة مطابقاً لعرض الطابعة تماماً
      // عرض الحاوية في الكود هو 384.0 نقطة منطقية
      final double targetPixelRatio = printWidth / 384.0;

      // التقاط صورة الفاتورة مع مهلة زمنية ودقة ملائمة للطباعة
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

      // إظهار رسالة إرسال البيانات
      // _showLoadingToast('جاري إرسال الفاتورة إلى الطابعة...');

      // تحويل الصورة إلى تنسيق مناسب
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('فشل تحويل الصورة');
      }

      // وبما أننا التقطنا الصورة بالدقة المطلوبة مباشرة، فلا داعي لعملية تغيير الحجم المكلفة
      final img.Image resizedImage = image.width == printWidth
          ? image
          : img.copyResize(image, width: printWidth);

      // إنشاء أوامر ESC/POS للطابعة
      final profile = await _getCapabilityProfile();
      final generator = Generator(
        paperSize,
        profile,
      );
      final List<int> bytes = [];

      // إضافة الصورة
      bytes.addAll(generator.image(resizedImage));

      // قص الورقة
      bytes.addAll(generator.cut());

      // التحقق من حالة الاتصال قبل إرسال البيانات
      if (_connection == null || !mounted) {
        throw Exception('تم فقدان الاتصال بالطابعة');
      }

      // إرسال البيانات إلى الطابعة مع مهلة زمنية
      _connection!.output.add(Uint8List.fromList(bytes));

      // استخدام مهلة زمنية لانتظار إرسال البيانات
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

      // إظهار رسالة نجاح
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

      // إظهار رسالة خطأ
      _showErrorToast('فشل الطباعة: $e');
    }
  }


  @override
  void dispose() {
    try {
      // إلغاء جميع المؤقتات
      _cancelAllTimers();

      // إلغاء اشتراكات البلوتوث لمنع تسرب الذاكرة
      _bluetoothStateSubscription?.cancel();

      // قطع الاتصال بالجهاز مباشرة دون تحديث واجهة المستخدم
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
