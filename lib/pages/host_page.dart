import 'package:flutter/material.dart';
import '../services/ws_server.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    // เลือก IP ตัวแรกที่เป็น IPv4 และไม่ใช่ loopback
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

    _server.messageStream.listen((msg) {
      final bc = (msg["barcode"] ?? "").toString();
      if (!mounted) return;

      setState(() {
        _latestBarcode = bc;
        _status = "เชื่อมต่อแล้ว";
      });
    });

    if (!mounted) return;
    setState(() {
      _status = "พร้อมใช้งาน";
    });
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
            // ===== Top row: IP / PORT / STATUS (same size) =====
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    "IP: ${_ip ?? '-'}",
                    style: headerStyle,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "PORT: $_port",
                    style: headerStyle,
                    textAlign: TextAlign.center,
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

            // ===== S/N row =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "S/N number",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 14),

                // ช่องแสดงเลข (อ่านอย่างเดียว)
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
                      (_latestBarcode == null || _latestBarcode!.isEmpty)
                          ? "----------" // placeholder 10 ตัว
                          : _latestBarcode!,
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

            const SizedBox(height: 12),

            // hint เล็กน้อย (ถ้าอยากเอาออกก็ลบได้)
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
