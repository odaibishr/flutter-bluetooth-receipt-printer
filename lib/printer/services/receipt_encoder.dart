import 'dart:developer';
import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import '../models/printer_exceptions.dart';

/// Service responsible for converting receipt images into ESC/POS printer byte commands.
class ReceiptEncoder {
  CapabilityProfile? _capabilityProfile;

  /// Loads and caches the CapabilityProfile.
  Future<CapabilityProfile> getCapabilityProfile() async {
    try {
      _capabilityProfile ??= await CapabilityProfile.load();
      return _capabilityProfile!;
    } catch (e) {
      log('Failed to load capability profile, falling back to default: $e');
      // Return a basic profile if loading fails
      return CapabilityProfile.load();
    }
  }

  /// Converts raw PNG/JPEG image bytes into ESC/POS printer bytes.
  Future<List<int>> encodeImageToEscPos(
    Uint8List imageBytes, {
    required PaperSize paperSize,
  }) async {
    try {
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw const PrintFailedException('فشل تحويل الصورة الملتقطة');
      }

      // Determine printer width in pixels
      final int printWidth = paperSize == PaperSize.mm80 ? 576 : 384;

      // Resize the image to fit the print width exactly
      final img.Image resizedImage = image.width == printWidth
          ? image
          : img.copyResize(image, width: printWidth);

      final profile = await getCapabilityProfile();
      final generator = Generator(paperSize, profile);
      final List<int> bytes = [];

      // Add image to command bytes
      bytes.addAll(generator.image(resizedImage));

      // Cut paper command
      bytes.addAll(generator.cut());

      return bytes;
    } catch (e) {
      log('Error during receipt encoding: $e');
      if (e is PrinterException) rethrow;
      throw PrintFailedException('حدث خطأ أثناء إعداد الفاتورة للطباعة: $e', e);
    }
  }
}
