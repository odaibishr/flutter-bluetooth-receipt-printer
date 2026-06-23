/// Base exception for all printer-related operations.
abstract class PrinterException implements Exception {
  final String message;
  final dynamic originalError;

  const PrinterException(this.message, [this.originalError]);

  @override
  String toString() {
    if (originalError != null) {
      return '$message: $originalError';
    }
    return message;
  }
}

/// Thrown when required Bluetooth permissions are denied.
class PrinterPermissionException extends PrinterException {
  const PrinterPermissionException(super.message, [super.originalError]);
}

/// Thrown when Bluetooth is turned off.
class BluetoothDisabledException extends PrinterException {
  const BluetoothDisabledException(super.message, [super.originalError]);
}

/// Thrown when connection to the printer times out or fails.
class ConnectionTimeoutException extends PrinterException {
  const ConnectionTimeoutException(super.message, [super.originalError]);
}

/// Thrown when disconnection fails or times out.
class DisconnectionException extends PrinterException {
  const DisconnectionException(super.message, [super.originalError]);
}

/// Thrown when printing fails (e.g., failed to render screenshot or transmit data).
class PrintFailedException extends PrinterException {
  const PrintFailedException(super.message, [super.originalError]);
}
