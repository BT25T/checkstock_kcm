import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WsServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  final StreamController<Map<String, dynamic>> _messageCtrl =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageCtrl.stream;

  Future<void> start(int port) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    _server!.listen((req) async {
      if (!WebSocketTransformer.isUpgradeRequest(req)) {
        req.response
          ..statusCode = 403
          ..write("WebSocket only")
          ..close();
        return;
      }

      final ws = await WebSocketTransformer.upgrade(req);
      _clients.add(ws);

      ws.listen((data) {
        try {
          final decoded = jsonDecode(data);
          _messageCtrl.add(decoded);
        } catch (_) {}
      }, onDone: () {
        _clients.remove(ws);
      });
    });
  }

  Future<void> dispose() async {
    for (var c in _clients) {
      await c.close();
    }
    await _server?.close();
  }
}
