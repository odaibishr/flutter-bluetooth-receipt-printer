import 'package:flutter/material.dart';

class ReceiptHeader extends StatelessWidget {
  const ReceiptHeader({
    super.key,
    required this.orderNumber,
    required this.storeName,
    required this.storeAddress,
    this.logo,
    required this.hasPrintedOnce,
  });

  final String orderNumber;
  final String storeName;
  final String storeAddress;
  final String? logo;
  final bool hasPrintedOnce;

  /// The brand color used across the receipt.
  static const Color _brandColor = Color(0xFF4A2A1B);

  /// Accent color matching the dividers in the invoice.
  static const Color _accentColor = Color(0xFFE05F52);

  /// Derives the first character of the store name for the fallback avatar.
  String get _storeInitial =>
      storeName.isNotEmpty ? storeName.characters.first : '?';

  @override
  Widget build(BuildContext context) {
    const double outerSize = 78;
    const double innerSize = 64;

    // Fallback avatar widget if image fails to load
    Widget fallbackAvatar = Container(
      width: innerSize,
      height: innerSize,
      color: _brandColor.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Text(
        _storeInitial,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: _brandColor,
        ),
      ),
    );

    return Column(
      children: [
        // ── Centered logo with decorative ring ──
        Container(
          width: outerSize,
          height: outerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: _accentColor.withValues(alpha: 0.35), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.08),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: ClipOval(
              child: (logo != null && logo!.contains('http'))
                  ? Image.network(
                      logo!,
                      width: innerSize,
                      height: innerSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallbackAvatar,
                    )
                  : Image.asset(
                      'assets/images/logo.jpeg',
                      width: innerSize,
                      height: innerSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallbackAvatar,
                    ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (hasPrintedOnce) ...[
          Text(
            'الفاتورة مكررة',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ] else ...[
          const SizedBox(height: 24),
        ],

        // ── Store name ──
        Text(
          storeName,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: _brandColor,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // ── Store address ──
        if (storeAddress.isNotEmpty)
          Text(
            storeAddress,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

        const SizedBox(height: 10),

        // ── Order number badge ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            'رقم الطلب #$orderNumber',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _accentColor,
            ),
          ),
        ),
      ],
    );
  }
}
