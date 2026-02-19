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
              title: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'ผู้ให้เชื่อมต่อ (Host)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' ให้ Device อื่นเชื่อมต่อ เพื่อนำรหัสสินค้ามาเช็คสต๊อก',
                    ),
                  ],
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HostPage()),
              ),
            ),
            const SizedBox(height: 12),
            BigModeButton(
              title: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'ยิงเช็คสต๊อก (Scanner)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' เชื่อมต่อกับ Host เพื่อทำการเช็คสต๊อก',
                    ),
                  ],
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScannerPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
