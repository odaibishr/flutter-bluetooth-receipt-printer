import 'package:flutter/material.dart';

class CancelOperationButton extends StatelessWidget {
  final VoidCallback onCancelOperationPressed;

  const CancelOperationButton({
    super.key,
    required this.onCancelOperationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onCancelOperationPressed,
      child: const Text(
        'إلغاء العملية',
        style: TextStyle(color: Colors.red),
      ),
    );
  }
}
