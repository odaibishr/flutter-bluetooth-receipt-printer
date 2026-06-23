import 'package:flutter/material.dart';

class TotalRow extends StatelessWidget {
  const TotalRow({
    super.key,
    required this.label,
    required this.value,
    this.isGrandTotal = false,
  });

  final String label;
  final String value;
  final bool isGrandTotal;

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isGrandTotal ? 17 : 15,
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
