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
    return Column(
      children: [
        
      ],
    );
  }
}
