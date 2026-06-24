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
            fontSize: isGrandTotal ? 21 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isGrandTotal ? 21 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
