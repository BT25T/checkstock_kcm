import 'dart:io';

class NetworkUtils {
  static Future<String?> getLocalIPv4() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    // 1) Prefer Ethernet
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      if (!name.contains('ethernet') && !name.contains('eth') && !name.contains('lan')) {
        continue;
      }

      for (final addr in interface.addresses) {
        final ip = addr.address;
        if (_isPrivateIPv4(ip)) return ip;
      }
    }

    // 2) Fallback any private IPv4
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        final ip = addr.address;
        if (_isPrivateIPv4(ip)) return ip;
      }
    }

    return null;
  }

  static bool _isPrivateIPv4(String ip) {
    if (ip.startsWith('192.168.')) return true;
    if (ip.startsWith('10.')) return true;

    if (ip.startsWith('172.')) {
      final parts = ip.split('.');
      if (parts.length > 1) {
        final second = int.tryParse(parts[1]) ?? 0;
        if (second >= 16 && second <= 31) return true;
      }
    }
    return false;
  }
}
