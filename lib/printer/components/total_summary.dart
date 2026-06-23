import 'package:flutter/material.dart';
import 'total_row.dart';

class TotalSummary extends StatelessWidget {
  const TotalSummary({
    super.key,
    required this.orderTotal,
    required this.delivery,
    this.currency = 'ر.ي',
  });

  final double orderTotal;
  final double delivery;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final double grandTotal = orderTotal + delivery;

    return Column(
      children: [
        TotalRow(
          label: 'إجمالي الطلب',
          value: '${orderTotal.toStringAsFixed(1)} $currency',
        ),
        const SizedBox(height: 4),
        TotalRow(
          label: 'الإجمالي على المحل',
          value: '${orderTotal.toStringAsFixed(1)} $currency',
        ),
        const SizedBox(height: 4),
        TotalRow(
          label: 'التوصيل',
          value: '${delivery.toStringAsFixed(1)} $currency',
        ),
        const SizedBox(height: 8),
        TotalRow(
          label: 'الإجمالي الكلي',
          value: '${grandTotal.toStringAsFixed(1)} $currency',
          isGrandTotal: true,
        ),
      ],
    );
  }
}
