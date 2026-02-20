import 'package:flutter/material.dart';
import 'pages/scanner_page.dart'; // หน้าสแกน/ส่งค่าไป host (ของ Android)

void main() {
  runApp(const MyAppAndroid());
}

class MyAppAndroid extends StatelessWidget {
  const MyAppAndroid({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScannerPage(),
    );
  }
}