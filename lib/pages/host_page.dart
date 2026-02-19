import 'package:flutter/material.dart';
import '../services/pairing.dart';
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
  String _session = Pairing.makeSessionCode();
  String _status = "กำลังเริ่มระบบ...";
  List<Map<String, dynamic>> _logs = [];

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

    for (var i in interfaces) {
      for (var addr in i.addresses) {
        if (addr.address.startsWith("192.168.")) {
          _ip = addr.address;
        }
      }
    }

    await _server.start(_port);

    _server.messageStream.listen((msg) {
      setState(() {
        _logs.insert(0, msg);
        _status = "มีข้อมูลเข้าแล้ว!";
      });
    });

    setState(() {
      _status = "พร้อมใช้งาน";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HOST")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("IP: $_ip"),
            Text("PORT: $_port"),
            const SizedBox(height: 20),
            Text(
              "ROOM CODE",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              _session,
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text("STATUS: $_status"),
            const SizedBox(height: 20),
            const Text("LOGS"),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (_, i) {
                  return ListTile(
                    title: Text(_logs[i].toString()),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
