import 'package:flutter/material.dart';
import '../services/ws_server.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _kSavedIpKey = 'saved_host_ip';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kSavedIpKey);
    if (!mounted) return;
    if (saved != null && saved.isNotEmpty) {
      setState(() => _ip = saved);
    }
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedIpKey, ip);
  }

  Future<String?> _findLocalIPv4() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (!addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return null;
  }

  Future<void> _init() async {
    // 1) โหลด IP ที่เคยบันทึกไว้ก่อน (โชว์ทันที)
    await _loadSavedIp();

    // 2) หา IP จริงจาก network แล้วเซฟทับ
    final realIp = await _findLocalIPv4();
    if (realIp != null) {
      if (!mounted) return;
      setState(() => _ip = realIp);
      await _saveIp(realIp);
    }

    // 3) start server
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
    setState(() => _status = "พร้อมใช้งาน");
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
                      (_latestBarcode == null || _latestBarcode!.isEmpty)
                          ? "----------"
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
            Text(
              "รอรับข้อมูลจาก Scanner (ครบ 10 ตัวจะขึ้นทันที)",
              style: TextStyle(color: Colors.black.withOpacity(0.55)),
            ),

            const SizedBox(height: 12),

            // ปุ่มรีเฟรช IP เผื่อเปลี่ยนวง / เปลี่ยนสาย
            OutlinedButton.icon(
              onPressed: () async {
                final ip = await _findLocalIPv4();
                if (ip != null) {
                  if (!mounted) return;
                  setState(() => _ip = ip);
                  await _saveIp(ip);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text("รีเฟรช IP"),
            ),
          ],
        ),
      ),
    );
  }
}
