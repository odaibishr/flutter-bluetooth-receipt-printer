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
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton.icon(
        onPressed: isDisconnecting || isPrinting || isConnecting
            ? null
            : onDisconnectPressed,
        icon: isDisconnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.bluetooth_disabled),
        label: Text(isDisconnecting ? 'جاري قطع الاتصال...' : 'قطع الاتصال'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      ),
    );
  }
}
