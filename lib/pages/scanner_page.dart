import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import '../services/pairing.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final TextEditingController _roomCtrl = TextEditingController();
  final TextEditingController _ipTailCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();

  IOWebSocketChannel? _channel;
  bool _connected = false;
  String _status = "ยังไม่เชื่อมต่อ";

  void _connect() {
    final session = _roomCtrl.text.trim();
    final tail = _ipTailCtrl.text.trim();

    if (session.isEmpty || tail.isEmpty) {
      setState(() => _status = "กรอก Room Code และ IP ก่อน");
      return;
    }

    final ip = "192.168.1.$tail";
    final uri = Pairing.makeWsUri(ip: ip, port: 8090, session: session);

    try {
      _channel = IOWebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (event) {
          print("Server: $event");
        },
        onDone: () {
          setState(() {
            _connected = false;
            _status = "การเชื่อมต่อถูกปิด";
          });
        },
        onError: (_) {
          setState(() {
            _connected = false;
            _status = "เชื่อมต่อไม่สำเร็จ";
          });
        },
      );

      setState(() {
        _connected = true;
        _status = "เชื่อมต่อแล้ว";
      });

    } catch (e) {
      setState(() => _status = "เชื่อมต่อไม่สำเร็จ: $e");
    }
  }

  void _send() {
    if (!_connected) return;

    final text = _barcodeCtrl.text.trim();
    if (text.isEmpty) return;

    _channel?.sink.add(jsonEncode({
      "barcode": text,
      "ts": DateTime.now().toIso8601String(),
      "sender": "mobile"
    }));

    setState(() {
      _status = "ส่งแล้ว: $text";
    });

    _barcodeCtrl.clear();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _roomCtrl.dispose();
    _ipTailCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _connected ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text("CLIENT")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ===== Connection Form =====
            TextField(
              controller: _roomCtrl,
              decoration: const InputDecoration(
                labelText: "Room Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ipTailCtrl,
              decoration: const InputDecoration(
                labelText: "IP ตัวท้าย (เช่น 24)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _connect,
              child: const Text("เชื่อมต่อ"),
            ),

            const SizedBox(height: 20),

            // ===== Status =====
            Text(
              _status,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    _connected ? FontWeight.bold : FontWeight.normal,
                color: statusColor,
              ),
            ),

            const SizedBox(height: 30),

            // ===== Barcode Sender =====
            TextField(
              controller: _barcodeCtrl,
              decoration: const InputDecoration(
                labelText: "กรอกบาร์โค้ด",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _connected ? _send : null,
              child: const Text("ส่ง"),
            ),
          ],
        ),
      ),
    );
  }
}
