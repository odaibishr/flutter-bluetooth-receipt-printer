import 'package:flutter/material.dart';

class ReceiptHeader extends StatelessWidget {
  const ReceiptHeader({
    super.key,
    required this.orderNumber,
    required this.storeName,
    required this.storeAddress,
    this.logo,
  });
  final String orderNumber;
  final String storeName;
  final String storeAddress;
  final String? logo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'رقم الطلب $orderNumber',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                storeName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2A1B),
                ),
                textAlign: TextAlign.end,
              ),

              const SizedBox(height: 2),
              Text(
                storeAddress,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D000000),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: logo != null && logo!.contains('http')
                ? Image.network(logo!, width: 40, height: 40)
                : const Text(
                    'U',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4A2A1B),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
