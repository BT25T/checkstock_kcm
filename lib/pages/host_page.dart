import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ws_server.dart';

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  final WsServer _server = WsServer();
  final int _port = 8090;

  String? _ip;
  String _status = "พร้อมใช้งาน";
  String? _latestBarcode;

  // ====== UI status (stock) ======
  String _stockMsg = "-";
  Color _stockColor = Colors.black;

  // ====== Google Sheets links (buttons) ======
  static const String _SheetUrl =
      "https://docs.google.com/spreadsheets/d/1KSAHKkwuY02QOlmQdbXfNRJ7jGT4vS2DNaEZ3VCe368/edit?gid=0#gid=0";

  // ====== Apps Script Web App URL ======
  static const String kStockApiUrl =
      "https://script.google.com/macros/s/AKfycbzMA5b1SJ8RxWzaCHG-20LC858fOfHzGRJUei4OWfjRyy0DKKh099MFvvnTiGfXtVMi/exec";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เปิดลิงก์ไม่สำเร็จ")),
      );
    }
  }

  Future<void> _init() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (!addr.isLoopback) {
          _ip = addr.address;
          break;
        }
      }
      if (_ip != null) break;
    }

    await _server.start(_port);

    _server.messageStream.listen((msg) async {
      final bc = (msg["barcode"] ?? "").toString().trim();
      if (bc.isEmpty) return;
      if (!mounted) return;

      setState(() {
        _latestBarcode = bc;
        _status = "เชื่อมต่อแล้ว";
      });

      await _checkAndMoveStock(bc);
    });

    if (!mounted) return;
    setState(() {
      _status = "พร้อมใช้งาน";
    });
  }

  // ====== color alternation stored in SharedPreferences ======
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
        a: Colors.blue,
        b: Colors.green,
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
        a: Colors.orange,
        b: Colors.yellow,
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

  Widget _tinyLinkButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 26,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool connected = _latestBarcode != null;
    final Color statusColor = connected ? Colors.green : Colors.black;
    const headerStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(title: const Text("HOST")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    "IP: ${_ip ?? '- ปิดโปรแกรมแล้วเปิดใหม่'}",
                    style: headerStyle,
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Align(
                    alignment: Alignment.center,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text("PORT: $_port", style: headerStyle),
                        _tinyLinkButton(
                          label: "แก้ไขข้อมูลเช็คสต๊อก",
                          onPressed: () => _openLink(_SheetUrl),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "STATUS: $_status",
                    style: headerStyle.copyWith(color: statusColor),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "S/N number",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26, width: 1.2),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black.withOpacity(0.03),
                    ),
                    child: Text(
                      (_latestBarcode == null || _latestBarcode!.isEmpty) ? "----------" : _latestBarcode!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

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

            const SizedBox(height: 12),

            Text(
              "รอรับข้อมูลจาก Scanner (ครบ 10 ตัวจะขึ้นทันที)",
              style: TextStyle(color: Colors.black.withOpacity(0.55)),
            ),
          ],
        ),
      ),
    );
  }
}