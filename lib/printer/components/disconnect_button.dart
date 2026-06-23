import 'package:flutter/material.dart';

class DisconnectButton extends StatelessWidget {
  final bool isDisconnecting;
  final bool isPrinting;
  final bool isConnecting;
  final VoidCallback onDisconnectPressed;

  const DisconnectButton({
    super.key,
    required this.isDisconnecting,
    required this.isPrinting,
    required this.isConnecting,
    required this.onDisconnectPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: (!isDisconnecting && !isPrinting && !isConnecting)
          ? onDisconnectPressed
          : null,
      icon: isDisconnecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.link_off),
      label: Text(
        isDisconnecting ? 'جاري قطع الاتصال...' : 'قطع الاتصال',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
