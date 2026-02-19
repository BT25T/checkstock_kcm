import 'package:flutter/material.dart';
import '../widgets/big_mode_button.dart';
import 'host_page.dart';
import 'scanner_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกโหมดใช้งาน')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            BigModeButton(
              icon: Icons.qr_code_2,
              title: 'เป็นผู้ให้เชื่อมต่อ (สร้าง QR)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HostPage()),
              ),
            ),
            const SizedBox(height: 12),
            BigModeButton(
              icon: Icons.qr_code_scanner,
              title: 'เป็นคนสแกนเชื่อมต่อ (สแกน/อัปโหลด QR)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScannerPage()),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Host สร้าง QR: ws://IP:PORT?session=...&name=...\n'
              'Client สแกน/อัปโหลด QR → เชื่อมต่อ → ส่งบาร์โค้ด',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
