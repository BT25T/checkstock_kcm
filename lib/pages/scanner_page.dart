import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final TextEditingController _ipCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();

  IOWebSocketChannel? _channel;
  bool _connected = false;
  String _status = "ยังไม่เชื่อมต่อ";

  bool _sending = false; // กันส่งซ้ำตอนครบ 10 แล้ว event ยิงรัว

  void _connect() {
    final ip = _ipCtrl.text.trim();

    if (ip.isEmpty) {
      setState(() => _status = "กรอก IP ก่อน");
      return;
    }

    final uri = Uri.parse("ws://$ip:8090");

    try {
      _channel = IOWebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (event) {
          // ถ้า server ส่งอะไรกลับมา จะเห็นตรงนี้
          debugPrint("Server: $event");
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _connected = false;
            _status = "การเชื่อมต่อถูกปิด";
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _connected = false;
            _status = "เชื่อมต่อไม่สำเร็จ: $e";
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

  void _tryAutoSend(String value) {
    if (!_connected || _channel == null) return;

    final v = value.trim();

    // ต้องเป็นเลข 10 ตัวพอดี
    final isTenDigits = RegExp(r'^\d{10}$').hasMatch(v);
    if (!isTenDigits) return;

    // กันซ้ำ
    if (_sending) return;
    _sending = true;

    _channel!.sink.add(jsonEncode({
      "barcode": v,
      "ts": DateTime.now().toIso8601String(),
      "sender": "mobile"
    }));

    if (!mounted) return;
    setState(() => _status = "ส่งแล้ว: $v");

    // เคลียร์เพื่อยิงต่อ
    _barcodeCtrl.clear();

    // ปลดล็อกหลัง microtask
    Future.microtask(() => _sending = false);
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _ipCtrl.dispose();
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
            TextField(
              controller: _ipCtrl,
              decoration: const InputDecoration(
                labelText: "IP (เช่น 192.168.0.106)",
                border: OutlineInputBorder(),
              ),
              enabled: !_connected,
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _connected ? null : _connect,
              child: const Text("เชื่อมต่อ"),
            ),

            const SizedBox(height: 18),

            Text(
              _status,
              style: TextStyle(
                fontSize: 18,
                fontWeight: _connected ? FontWeight.bold : FontWeight.normal,
                color: statusColor,
              ),
            ),

            const SizedBox(height: 20),

            // ช่องกรอก/ยิงบาร์โค้ด: บังคับเลข 10 ตัว
            TextField(
              controller: _barcodeCtrl,
              enabled: _connected,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: "กรอก/ยิง S/N (10 ตัวเลข) — ครบแล้วส่งทันที",
                border: OutlineInputBorder(),
              ),
              onChanged: _tryAutoSend, // ✅ ครบ 10 ส่งทันที
            ),
          ],
        ),
      ),
    );
  }
}
