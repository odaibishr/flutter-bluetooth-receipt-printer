import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_data.dart';

class ReceiptMetadata extends StatelessWidget {
  final ReceiptData receiptData;

  const ReceiptMetadata({
    super.key,
    required this.receiptData,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime invoiceDate = receiptData.invoiceDate;
    final String formattedDate = DateFormat('dd/MM/yyyy').format(invoiceDate);
    final String formattedTime = DateFormat('hh:mm').format(invoiceDate);
    final String amPm = invoiceDate.hour >= 12 ? 'م' : 'ص';
    final String fullDateTime = "$formattedDate $formattedTime $amPm";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          if (receiptData.customerAddress.isNotEmpty)
            _buildMetadataRow(receiptData.customerAddress, Icons.place_outlined),
          if (receiptData.branchAddress.isNotEmpty)
            _buildMetadataRow(receiptData.branchAddress, Icons.map_outlined),
          if (receiptData.paymentMethod.isNotEmpty)
            _buildMetadataRow(receiptData.paymentMethod, Icons.payment_outlined),
          _buildMetadataRow(
            receiptData.notes.isNotEmpty ? receiptData.notes : 'لا يوجد ملاحظات',
            Icons.note_alt_outlined,
            isNotes: receiptData.notes.isNotEmpty,
          ),
          if (receiptData.customerName.isNotEmpty)
            _buildMetadataRow(receiptData.customerName, Icons.person_outline),
          if (receiptData.carNumber.isNotEmpty)
            _buildMetadataRow(receiptData.carNumber, Icons.directions_car_filled_outlined),
          _buildMetadataRow(fullDateTime, Icons.watch_later_outlined),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String text, IconData icon, {bool isNotes = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isNotes ? FontWeight.bold : FontWeight.w500,
                color: isNotes ? const Color(0xFFC0392B) : Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}
