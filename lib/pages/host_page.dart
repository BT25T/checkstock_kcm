import 'package:flutter/material.dart';
import '../services/ws_server.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

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

  static const String _checkedUrl =
      "https://docs.google.com/spreadsheets/d/1ImxpMJi-z9IWMeYoIRci94ddEhap9_iZwa9FKyNYyUo/edit?gid=0#gid=0";
  static const String _notCheckedUrl =
      "https://docs.google.com/spreadsheets/d/1KSAHKkwuY02QOlmQdbXfNRJ7jGT4vS2DNaEZ3VCe368/edit?gid=0#gid=0";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      if (!mounted) return;
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
            // ===== Top row: IP / PORT(+buttons) / STATUS =====
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    "IP: ${_ip ?? '- ปิดโปรแกรมแล้วเปิดใหม่'}",
                    style: headerStyle,
                  ),
                ),
                // PORT + 2 buttons (same line)
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

                        Text(
                          "แก้ไขข้อมูลเช็คสต๊อก",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.55),
                          ),
                        ),

                        _tinyLinkButton(
                          label: "เช็คสต๊อกแล้ว",
                          onPressed: () => _openLink(_checkedUrl),
                        ),

                        _tinyLinkButton(
                          label: "ยังไม่เช็คสต๊อก",
                          onPressed: () => _openLink(_notCheckedUrl),
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
          ],
        ),
      ),
    );
  }
}