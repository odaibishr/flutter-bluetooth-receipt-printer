import 'package:flutter/material.dart';
import 'package:printer_demo/printer/models/invoice_item.dart';

class ReceiptItemRow extends StatelessWidget {
  const ReceiptItemRow({
    super.key,
    required this.item,
    this.currency = 'ر.ي',
  });
  final InvoiceItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                '${item.price.toStringAsFixed(1)} $currency',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DBDB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          if (item.option != null && item.contains == null)
            Padding(
              padding: const EdgeInsets.only(right: 28.0, top: 2.0),
              child: Text(
                '{ ${item.option} }',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Other additions like (+ Coke)
          if (item.additions != null)
            ...item.additions!.map(
              (addition) => Padding(
                padding: const EdgeInsets.only(right: 28.0, top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      addition,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.add_circle,
                      color: Color(0xFFE05F52),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

          if (item.contains != null) ...[
            const Padding(
              padding: EdgeInsets.only(right: 28.0, top: 8.0, bottom: 4.0),
              child: Text(
                'يحتوي على:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ...item.contains!.map(
              (subItem) => Padding(
                padding: const EdgeInsets.only(
                  right: 36.0,
                  top: 2.0,
                  bottom: 2.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      subItem.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // الحبة الوردية للكمية السالبة مثل (- 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFCE4D6,
                        ), // لون خلفية وردي/برتقالي فاتح
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '- ${subItem.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC0392B), // لون أحمر داكن
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (item.option != null)
              Padding(
                padding: const EdgeInsets.only(right: 28.0, top: 4.0),
                child: Text(
                  '{ ${item.option} }',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
