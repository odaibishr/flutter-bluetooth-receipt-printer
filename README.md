# Flutter Bluetooth Receipt Printer Demo

This is a simple Flutter project that shows how to scan, connect, and print receipts to Bluetooth thermal printers. It perfectly supports custom styles and RTL Arabic text.

---

## 💡 How It Works (Simple Pipeline)

Thermal printers usually struggle to print Arabic letters correctly. This project solves this by printing the receipt as an **image**:

1. **Design the UI**: We design the invoice using normal Flutter widgets (which automatically support Arabic and custom styles).
2. **Take a Screenshot**: The app takes an off-screen screenshot of the invoice widget using the `screenshot` package.
3. **Convert to Printer Bytes**: The screenshot image is resized and converted into printer command bytes (ESC/POS) using the `esc_pos_utils_plus` package.
4. **Send to Printer**: The bytes are sent directly to the printer over Bluetooth using `flutter_bluetooth_serial`.

---

## 📂 Key Files

Here are the main files in this project:

- [main.dart](file:///E:/FlutterProjects/printer_demo/printer_demo/lib/main.dart) - Launches the application.
- [printer.dart](file:///E:/FlutterProjects/printer_demo/printer_demo/lib/printer/printer.dart) - Coordinates the entire printing screen, managing connection and print requests.
- [printer_service.dart](file:///E:/FlutterProjects/printer_demo/printer_demo/lib/printer/services/printer_service.dart) - The blueprint for printer functions (Scan, Connect, Disconnect, Print).
- [bluetooth_printer_serial_impl.dart](file:///E:/FlutterProjects/printer_demo/printer_demo/lib/printer/services/bluetooth_printer_serial_impl.dart) - The actual code that connects and sends data over Bluetooth.
- [receipt_encoder.dart](file:///E:/FlutterProjects/printer_demo/printer_demo/lib/printer/services/receipt_encoder.dart) - Resizes the screenshot image and converts it into ESC/POS bytes.
- [invoice_tab.dart](file:///E:/FlutterProjects/printer_demo/printer_demo/lib/printer/components/invoice_tab.dart) - The visual receipt layout preview with the print button.
- [bluetooth_tab.dart](file:///E:/FlutterProjects/printer_demo/printer_demo/lib/printer/components/bluetooth_tab.dart) - The screen to scan for and connect to Bluetooth printers.

---

## ⚙️ How to Setup and Run

1. **Setup Permissions**: Make sure the Bluetooth and Location permissions are declared in the Android Manifest ([AndroidManifest.xml](file:///E:/FlutterProjects/printer_demo/printer_demo/android/app/src/main/AndroidManifest.xml)).
2. **Download packages**: Run `flutter pub get`.
3. **Pair the printer**: Pair the printer in your phone's Bluetooth settings.
4. **Run the App**: Run `flutter run` on a physical device, open the app, connect to the printer in the Bluetooth tab, and print!
