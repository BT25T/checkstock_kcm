import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

WebSocketChannel connectWs(Uri uri) {
  if (kIsWeb) return WebSocketChannel.connect(uri);
  return IOWebSocketChannel.connect(uri);
}