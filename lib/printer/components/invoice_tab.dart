import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:printer_demo/printer/components/receipt_header.dart';
import 'package:printer_demo/printer/components/receipt_item_row.dart';
import 'package:printer_demo/printer/components/total_summary.dart';
import 'package:printer_demo/printer/components/receipt_metadata.dart';
import 'package:printer_demo/printer/models/receipt_data.dart';
import 'package:screenshot/screenshot.dart';

class InvoiceTab extends StatelessWidget {
  final ReceiptData receiptData;
  final ScreenshotController screenshotController;
  final bool isPrinting;
  final bool isConnected;
  final VoidCallback onPrintPressed;
  final VoidCallback onRetry;

  const InvoiceTab({
    super.key,
    required this.receiptData,
    required this.screenshotController,
    required this.isPrinting,
    required this.isConnected,
    required this.onPrintPressed,
    required this.onRetry,
  });

  double get _total =>
      receiptData.items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    try {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // The receipt with screenshot controller
            Screenshot(
              controller: screenshotController,
              child: Container(
                color: Colors.white,
                width: 384, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The pink container for the details of the order
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF1F0), 
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The receipt header
                          ReceiptHeader(
                            orderNumber: receiptData.orderNumber,
                            storeName: receiptData.storeName,
                            storeAddress: receiptData.storeAddress,
                          ),
                          const SizedBox(height: 8),
                          const Divider(
                            color: Color(0xFFE05F52),
                            thickness: 1.5,
                          ),
                          const SizedBox(height: 8),

                          // The list of items in receipt
                          ...receiptData.items.map((item) => ReceiptItemRow(item: item)),

                          const SizedBox(height: 8),
                          const Divider(
                            color: Color(0xFFE05F52),
                            thickness: 1.5,
                          ),
                          const SizedBox(height: 8),

                          TotalSummary(
                            orderTotal: _total,
                            delivery: receiptData.deliveryFee,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // The section of the additional data (white background below the pink box)
                    ReceiptMetadata(receiptData: receiptData),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // The printer button and in printing will be loading
            ElevatedButton.icon(
              onPressed: (isConnected && !isPrinting) ? onPrintPressed : null,
              icon: isPrinting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print),
              label: Text(isPrinting ? 'جاري الطباعة...' : 'طباعة الفاتورة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      log("خطأ في بناء علامة تبويب الفاتورة: $e");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ في عرض الفاتورة',
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
}
