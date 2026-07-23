import 'dart:async';
import 'dart:io';

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

/// Короткая ли это ссылка карт (maps.app.goo.gl / goo.gl) — в них нет
/// ни названия, ни координат, всё содержится в полной ссылке после редиректа.
bool isShortMapsLink(String url) {
  final h = Uri.tryParse(url.trim())?.host.toLowerCase() ?? '';
  return h == 'maps.app.goo.gl' || h == 'goo.gl' || h.endsWith('.goo.gl');
}

/// Разворачивает короткую ссылку карт в полную, следуя редиректам
/// (максимум 5, таймаут ~5 с). Возвращает первую ссылку вида google…/maps/…
/// или null (нет сети/не разложилось). Единственное сетевое место приложения.
Future<String?> resolveMapsShortLink(String url) async {
  final start = Uri.tryParse(url.trim());
  if (start == null || !isShortMapsLink(url)) return null;
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 4);
  try {
    var current = start;
    for (var i = 0; i < 5; i++) {
      final req = await client.getUrl(current);
      req.followRedirects = false;
      final res = await req.close().timeout(const Duration(seconds: 5));
      unawaited(res.drain<void>().catchError((_) {}));
      if (res.statusCode < 300 || res.statusCode >= 400) break;
      final loc = res.headers.value(HttpHeaders.locationHeader);
      if (loc == null) break;
      final next = Uri.parse(loc);
      current = next.isAbsolute ? next : current.resolve(loc);
      // Первая же полная ссылка карт — то, что нужно (дальше может быть
      // consent-страница и пр.).
      if (current.host.contains('google') &&
          current.path.contains('/maps')) {
        return current.toString();
      }
    }
    final s = current.toString();
    return s == url.trim() ? null : s;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// Пытается достать координаты точки из ПОЛНОЙ ссылки карт:
/// `!3d<lat>!4d<lng>` (точный пин), `@<lat>,<lng>` (центр карты) или
/// `?q=<lat>,<lng>`. Возвращает "lat,lng" или null.
String? coordsFromUrl(String url) {
  final u = url.trim();
  final pin = RegExp(r'!3d(-?\d{1,3}\.\d+)!4d(-?\d{1,3}\.\d+)').firstMatch(u);
  if (pin != null) return '${pin.group(1)},${pin.group(2)}';
  final at = RegExp(r'@(-?\d{1,3}\.\d+),(-?\d{1,3}\.\d+)').firstMatch(u);
  if (at != null) return '${at.group(1)},${at.group(2)}';
  // /maps/search/<lat>,+<lng> — так разворачиваются короткие ссылки шаринга
  // (плюс/пробел между координатами). Требуем ≥3 знаков после точки,
  // чтобы не зацепить случайные числа.
  final search = RegExp(
          r'(-?\d{1,3}\.\d{3,})(?:%2C|,)(?:\+|%2B|\s|%20)?(-?\d{1,3}\.\d{3,})')
      .firstMatch(u);
  if (search != null) return '${search.group(1)},${search.group(2)}';
  final q = Uri.tryParse(u)?.queryParameters['q'];
  if (q != null &&
      RegExp(r'^-?\d{1,3}\.\d+,\s*-?\d{1,3}\.\d+$').hasMatch(q)) {
    return q.replaceAll(' ', '');
  }
  return null;
}

/// Открывает маршрут через точки (координаты или названия) в Google Maps —
/// формат пути `/maps/dir/P1/P2/P3`. Официальный `?api=1&waypoints=…`
/// нативное приложение карт манглит: destination теряется, промежуточная
/// точка становится конечной (проверено на устройстве) — не использовать.
Future<bool> openRouteInMaps(List<String> points) async {
  final pts = points.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
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
