import 'package:flutter/material.dart';

class CancelOperationButton extends StatelessWidget {
  final VoidCallback onCancelOperationPressed;

  const CancelOperationButton({
    super.key,
    required this.onCancelOperationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton.icon(
        onPressed: onCancelOperationPressed,
        icon: const Icon(Icons.cancel),
        label: const Text('إلغاء العملية الحالية'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      ),
    );
  }
}
