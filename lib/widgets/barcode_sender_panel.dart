import 'package:flutter/material.dart';

class BarcodeSenderPanel extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const BarcodeSenderPanel({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text('ส่งบาร์โค้ด (ปืนยิงส่วนใหญ่จะพิมพ์แล้วกด Enter)'),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Barcode',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSend(),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          icon: const Icon(Icons.send),
          label: const Text('ส่ง'),
          onPressed: onSend,
        ),
      ],
    );
  }
}
