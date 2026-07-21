import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ссылки и файлы дела. Хранятся списком строк: веб-URL (http/https) или
/// путь к локальному файлу. Открываются наружу: URL — в браузере/приложении,
/// файл — системным «Открыть с помощью».

bool isWebLink(String entry) {
  final e = entry.trim();
  return e.startsWith('http://') || e.startsWith('https://');
}

/// Разбирает поле `links` (записи через перевод строки) в список.
List<String> parseLinks(String raw) =>
    raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

String joinLinks(List<String> links) => links.join('\n');

/// Короткая подпись записи: для URL — хост, для файла — имя файла.
String linkLabel(String entry) {
  final e = entry.trim();
  if (isWebLink(e)) {
    final host = Uri.tryParse(e)?.host ?? '';
    return host.isNotEmpty ? host : e;
  }
  return p.basename(e);
}

/// Открывает запись во внешнем приложении. Возвращает false при неудаче.
Future<bool> openLink(String entry) async {
  final e = entry.trim();
  if (isWebLink(e)) {
    final uri = Uri.tryParse(e);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  final res = await OpenFilex.open(e);
  return res.type == ResultType.done;
}

/// Копирует выбранный файл в постоянную папку приложения (чтобы ссылка не
/// протухла, когда кэш выбора файлов очистится) и возвращает новый путь.
Future<String> importFileToAppStorage(String sourcePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final attachDir = Directory(p.join(dir.path, 'attachments'));
  if (!await attachDir.exists()) await attachDir.create(recursive: true);
  final name = p.basename(sourcePath);
  var dest = p.join(attachDir.path, name);
  // Не затираем одноимённый файл.
  var i = 1;
  while (await File(dest).exists()) {
    final base = p.basenameWithoutExtension(name);
    final ext = p.extension(name);
    dest = p.join(attachDir.path, '$base ($i)$ext');
    i++;
  }
  await File(sourcePath).copy(dest);
  return dest;
}
