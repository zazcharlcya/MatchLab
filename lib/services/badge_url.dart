/// OpenLigaDB отдаёт `teamIconUrl`: PNG/JPG или SVG с Wikimedia.
/// Flutter не рисует SVG без отдельного пакета, поэтому Wikimedia SVG
/// превращаем в PNG-превью стандартным URL `/thumb/…/128px-….svg.png`.
class BadgeUrl {
  static const headers = {
    'User-Agent': 'MatchLab/1.0 (Android; football analytics)',
    'Accept': 'image/png,image/jpeg,image/webp,image/*',
  };

  static String? displayUrl(String? raw, {int size = 250}) {
    if (raw == null) {
      return null;
    }
    final url = raw.trim();
    if (url.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return null;
    }
    final secure = uri.scheme == 'http' ? uri.replace(scheme: 'https') : uri;
    if (!secure.path.toLowerCase().endsWith('.svg')) {
      return secure.toString();
    }
    final host = secure.host;
    if (!host.contains('wikimedia.org') && !host.contains('wikipedia.org')) {
      return secure.toString();
    }
    return _wikimediaSvgPng(secure, size);
  }

  static String _wikimediaSvgPng(Uri uri, int size) {
    final segments = [...uri.pathSegments];
    if (segments.isEmpty) {
      return uri.toString();
    }
    final fileName = segments.last;
    if (segments.contains('thumb')) {
      if (fileName.toLowerCase().endsWith('.png')) {
        return uri.toString();
      }
      return uri.replace(
        pathSegments: [...segments, '${size}px-$fileName.png'],
      ).toString();
    }
    final wikiIndex = segments.indexOf('wikipedia');
    if (wikiIndex >= 0 && wikiIndex + 1 < segments.length) {
      final familyIndex = wikiIndex + 1;
      return uri.replace(
        pathSegments: [
          ...segments.sublist(0, familyIndex + 1),
          'thumb',
          ...segments.sublist(familyIndex + 1),
          '${size}px-$fileName.png',
        ],
      ).toString();
    }
    return uri.toString();
  }
}
