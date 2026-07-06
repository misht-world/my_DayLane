import 'package:url_launcher/url_launcher.dart';

/// Открытие мест во внешнем приложении карт (Google Maps и т.п.).
/// Само приложение остаётся офлайновым: мы только передаём intent наружу.

/// Похоже ли содержимое буфера на ссылку карт (share-link Google Maps,
/// универсальные ссылки или geo:).
bool looksLikeMapsLink(String s) {
  final t = s.trim();
  if (t.startsWith('geo:')) return true;
  final uri = Uri.tryParse(t);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
    return false;
  }
  final h = uri.host.toLowerCase();
  return h.contains('maps.app.goo.gl') ||
      h.contains('goo.gl') ||
      (h.contains('google.') && uri.path.contains('/maps')) ||
      h.contains('maps.google') ||
      h.contains('yandex.') && uri.path.contains('maps') ||
      h.contains('2gis.') ||
      h.contains('openstreetmap.org') ||
      h.contains('osm.org');
}

/// Открывает место во внешних картах: по сохранённой ссылке, иначе —
/// поиском по названию (geo:, при неудаче — веб-ссылка Google Maps).
Future<bool> openInMaps({String url = '', String query = ''}) async {
  if (url.trim().isNotEmpty) {
    final uri = Uri.tryParse(url.trim());
    if (uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
  }
  final q = query.trim();
  if (q.isEmpty) {
    // Просто открыть карты (пустой поиск) — чтобы выбрать место.
    return launchUrl(Uri.parse('geo:0,0?q='),
        mode: LaunchMode.externalApplication);
  }
  final encoded = Uri.encodeComponent(q);
  final geo = Uri.parse('geo:0,0?q=$encoded');
  if (await launchUrl(geo, mode: LaunchMode.externalApplication)) return true;
  return launchUrl(
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded'),
    mode: LaunchMode.externalApplication,
  );
}
