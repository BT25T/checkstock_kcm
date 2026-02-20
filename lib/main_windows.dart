import 'package:flutter/material.dart';
import 'pages/host_page.dart'; // ใช้ HostPage ได้เต็มที่

void main() {
  runApp(const MyAppWindows());
}

class MyAppWindows extends StatelessWidget {
  const MyAppWindows({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HostPage(),
    );
  }
}