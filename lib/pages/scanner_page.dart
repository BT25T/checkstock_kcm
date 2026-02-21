import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ws_channel_factory.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final TextEditingController _ipCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();

  WebSocketChannel? _channel;
  bool _connected = false;
  String _status = "ยังไม่เชื่อมต่อ";

  bool _sending = false; // กันส่งซ้ำตอนครบ 10 แล้ว event ยิงรัว

  // ====== สถานะสต๊อกบนหน้า Scanner ======
  String _stockMsg = "-";
  Color _stockColor = Colors.black;

  // ====== Apps Script Web App URL (ต้องเป็นตัวเดียวกับ Host) ======
  static const String kStockApiUrl =
      "https://script.google.com/macros/s/AKfycbzMA5b1SJ8RxWzaCHG-20LC858fOfHzGRJUei4OWfjRyy0DKKh099MFvvnTiGfXtVMi/exec";

  void _connect() {
    final ip = _ipCtrl.text.trim();

    if (ip.isEmpty) {
      setState(() => _status = "กรอก IP ก่อน");
      return;
    }

    final uri = Uri.parse("ws://$ip:8090");

    try {
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (event) {
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

  // ====== สีสลับแบบจำรอบ ======
  Future<Color> _nextAltColor({
    required String counterKey,
    required Color a,
    required Color b,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getInt(counterKey) ?? 0;
    await prefs.setInt(counterKey, n + 1);
    return (n % 2 == 0) ? a : b;
  }

  Future<void> _applyStockResult(String status, String message) async {
    if (!mounted) return;

    if (status == "moved") {
      final c = await _nextAltColor(
        counterKey: "alt_moved",
        a: Colors.green,
        b: Colors.blue,
      );
      if (!mounted) return;
      setState(() {
        _stockMsg = message; // ยิงสต๊อกสำเร็จ
        _stockColor = c;
      });
      return;
    }

    if (status == "already") {
      final c = await _nextAltColor(
        counterKey: "alt_already",
        a: Colors.yellow,
        b: Colors.orange,
      );
      if (!mounted) return;
      setState(() {
        _stockMsg = message; // เช็คสต๊อกแล้ว
        _stockColor = c;
      });
      return;
    }

    if (status == "error") {
      setState(() {
        _stockMsg = message;
        _stockColor = Colors.black;
      });
      return;
    }

    setState(() {
      _stockMsg = message; // ขายสินค้าหมด
      _stockColor = Colors.red;
    });
  }

  Future<void> _checkAndMoveStock(String sn) async {
    try {
      final uri = Uri.parse(kStockApiUrl).replace(
        queryParameters: {"sn": sn, "move": "1"},
      );

      http.Response res = await http.get(uri);

      int redirectCount = 0;
      while (res.statusCode >= 300 &&
          res.statusCode < 400 &&
          res.headers["location"] != null &&
          redirectCount < 5) {
        final loc = res.headers["location"]!;
        debugPrint("Redirect ${res.statusCode} -> $loc");
        res = await http.get(Uri.parse(loc));
        redirectCount++;
      }

      debugPrint("FINAL HTTP ${res.statusCode}");
      debugPrint("FINAL BODY ${res.body}");

      final body = res.body.trim();
      if (!body.startsWith("{")) {
        // ถ้าไม่ใช่ JSON จริงๆ ก็ไม่ต้องเปลี่ยน UI
        return;
      }

      final Map<String, dynamic> data = jsonDecode(body);

      final ok = (data["ok"] == true);
      String status = (data["status"] ?? "").toString().trim();
      String message = (data["message"] ?? "").toString().trim();

      // ====== LOCK STATUS ให้เหลือ 3 ค่าเท่านั้น ======
      if (!ok) {
        status = "error";
        message = message.isNotEmpty ? message : "เกิดข้อผิดพลาด";
      } else {
        // map status ที่ API อาจส่งมาแบบ debug
        if (status == "not_found") status = "out";
        if (status == "found") {
          // ถ้า API ส่ง found + where มา ให้ map เป็น already/unchecked
          final where = (data["where"] ?? "").toString();
          if (where == "checked") {
            status = "already";
            if (message.isEmpty) message = "เช็คสต๊อกแล้ว";
          } else {
            // found ใน unchecked แต่ยังไม่ได้ย้าย (กรณี debug)
            status = "moved"; // หรือจะทำเป็น out ก็ได้ แต่ให้มันไม่มั่ว
            if (message.isEmpty) message = "ยิงสต๊อกสำเร็จ";
          }
        }

        // ถ้า status ไม่ใช่ 3 ค่านี้ ให้ถือว่า error ไปเลย (กันเพี้ยน)
        const allowed = {"moved", "already", "out"};
        if (!allowed.contains(status)) {
          debugPrint("Unexpected status from API: $status");
          status = "error";
          message = "สถานะไม่ถูกต้องจาก API";
        }

        // เติม message ถ้าว่าง
        if (status == "moved" && message.isEmpty) message = "ยิงสต๊อกสำเร็จ";
        if (status == "already" && message.isEmpty) message = "เช็คสต๊อกแล้ว";
        if (status == "out" && message.isEmpty) message = "ขายสินค้าหมด";
      }

      await _applyStockResult(status, message);
    } catch (e) {
      debugPrint("API error: $e");
      // ไม่บังคับเปลี่ยน UI ถ้าไม่อยากให้มั่วตอนเน็ตสะดุด
      // await _applyStockResult("error", "เชื่อมต่อไม่ได้");
    }
  }

  void _tryAutoSend(String value) async {
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

    // เช็ค/ย้ายในชีต แล้วอัปเดตสถานะบนหน้า
    await _checkAndMoveStock(v);

    _barcodeCtrl.clear();
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

            const SizedBox(height: 14),

            Row(
              children: [
                const Text(
                  "สถานะสต๊อก: ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Text(
                    _stockMsg,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _stockColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

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
              onChanged: _tryAutoSend,
            ),
          ],
        ),
      ),
    );
  }
}