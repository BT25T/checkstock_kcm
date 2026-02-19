class PairingInfo {
  final Uri uri;
  final String session;
  final String? name;

  PairingInfo({
    required this.uri,
    required this.session,
    this.name,
  });

  static PairingInfo? tryParse(String raw) {
    Uri? uri;
    try {
      uri = Uri.parse(raw.trim());
    } catch (_) {
      return null;
    }

    if (uri.scheme != 'ws' && uri.scheme != 'wss') return null;

    final session = uri.queryParameters['session'];
    if (session == null || session.isEmpty) return null;

    return PairingInfo(
      uri: uri,
      session: session,
      name: uri.queryParameters['name'],
    );
  }
}
