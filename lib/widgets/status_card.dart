import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String status;
  final String? payload;

  const StatusCard({super.key, required this.status, this.payload});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สถานะ: $status'),
            if (payload != null) ...[
              const SizedBox(height: 6),
              Text('QR payload: $payload', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
