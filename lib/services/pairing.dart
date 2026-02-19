import 'dart:math';

class Pairing {
  static String makeSessionCode() {
    final r = Random();
    return "KCM-${1000 + r.nextInt(9000)}";
  }

  static Uri makeWsUri({
    required String ip,
    required int port,
    required String session,
  }) {
    return Uri.parse("ws://$ip:$port?session=$session");
  }
}
