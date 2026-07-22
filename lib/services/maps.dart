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

/// Пытается вытащить название места из ПОЛНОЙ ссылки карт
/// (`…/maps/place/<Название>/…` или `?q=<Название>`). Из коротких ссылок
/// (`maps.app.goo.gl`) название офлайн не достать — вернёт null.
/// Никогда не бросает и ничего не меняет, кроме возврата имени.
String? placeNameFromUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  String clean(String s) {
    var v = s.replaceAll('+', ' ').trim();
    try {
      v = Uri.decodeComponent(v);
    } catch (_) {/* оставляем как есть */}
    // Отбрасываем координатные «названия» вида "59.9,30.3".
    if (RegExp(r'^[\d.,\s-]+$').hasMatch(v)) return '';
    return v.trim();
  }

  // .../maps/place/<name>/...
  final seg = uri.pathSegments;
  final i = seg.indexOf('place');
  if (i >= 0 && i + 1 < seg.length) {
    final name = clean(seg[i + 1]);
    if (name.isNotEmpty) return name;
  }
  // ?q=<name> или ?query=<name>
  final q = uri.queryParameters['q'] ?? uri.queryParameters['query'];
  if (q != null) {
    final name = clean(q);
    if (name.isNotEmpty) return name;
  }
  return null;
}

/// Открывает маршрут через все точки (по названиям) в Google Maps:
/// https://www.google.com/maps/dir/A/B/C. Одна точка — обычный поиск.
Future<bool> openRouteInMaps(List<String> names) async {
  final pts = names.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
  if (pts.isEmpty) return false;
  if (pts.length == 1) return openInMaps(query: pts.first);
  final path = pts.map(Uri.encodeComponent).join('/');
  return launchUrl(
    Uri.parse('https://www.google.com/maps/dir/$path'),
    mode: LaunchMode.externalApplication,
  );
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
