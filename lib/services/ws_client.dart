import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'ws_channel_factory.dart';

class WsClient {
  WebSocketChannel? _channel;
  bool _connected = false;

  bool get isConnected => _connected;

  /// connect ด้วย uri ที่ส่งเข้ามา (เช่น ws://192.168.0.106:8090)
  Future<void> connect(
    Uri uri, {
    void Function(dynamic message)? onMessage,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) async {
    // ปิดของเก่าก่อน กันค้าง
    await disconnect();

    _channel = connectWs(uri);
    _connected = true;

    _channel!.stream.listen(
      (message) {
        if (onMessage != null) onMessage(message);
      },
      onDone: () {
        _connected = false;
        if (onDone != null) onDone();
      },
      onError: (e) {
        _connected = false;
        if (onError != null) onError(e);
      },
      cancelOnError: true,
    );
  }

  void sendJson(Map<String, dynamic> data) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jsonEncode(data));
  }

  void sendRaw(String text) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(text);
  }

  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connected = false;
  }
}