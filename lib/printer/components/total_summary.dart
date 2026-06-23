import 'package:flutter/material.dart';

class TotalSummary extends StatelessWidget {
  const TotalSummary({
    super.key,
    required this.orderTotal,
    this.delivery = 600.0,
  });

  final double orderTotal;
  final double delivery;

  @override
  Widget build(BuildContext context) {
    final double grandTotal = orderTotal + delivery;

    return Column(
      children: [
        _buildTotalRow('إجمالي الطلب', '${orderTotal.toStringAsFixed(1)} ر.ي'),
        const SizedBox(height: 4),
        _buildTotalRow(
          'الإجمالي على المحل',
          '${orderTotal.toStringAsFixed(1)} ر.ي',
        ),
        const SizedBox(height: 4),
        _buildTotalRow('التوصيل', '${delivery.toStringAsFixed(1)} ر.ي'),
        const SizedBox(height: 8),
        _buildTotalRow(
          'الإجمالي الكلي',
          '${grandTotal.toStringAsFixed(1)} ر.ي',
          isGrandTotal: true,
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isGrandTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isGrandTotal ? 17 : 15,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 17 : 15,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
