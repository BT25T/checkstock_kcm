import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsClient {
  WebSocketChannel? _channel;
  bool _connected = false;

  bool get isConnected => _connected;

  Future<void> connect(Uri uri, {Function(dynamic)? onMessage}) async {
    _channel = WebSocketChannel.connect(uri);
    _connected = true;

    _channel!.stream.listen(
      (message) {
        if (onMessage != null) onMessage(message);
      },
      onDone: () {
        _connected = false;
      },
      onError: (_) {
        _connected = false;
      },
    );
  }

  void sendJson(Map<String, dynamic> data) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _channel?.sink.close();
    _connected = false;
  }
}
