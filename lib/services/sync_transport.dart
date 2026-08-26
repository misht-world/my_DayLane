import 'dart:convert';
import 'dart:io';

/// Тип ошибки синхронизации — для локализации сообщения в UI.
enum SyncErrorKind { network, auth, read, write, conflict, other }

/// Ошибки транспорта синхронизации. `message` — для логов; в интерфейсе текст
/// выбирается по `kind` (локализуемо).
class SyncException implements Exception {
  SyncException(this.message, [this.kind = SyncErrorKind.other]);
  final String message;
  final SyncErrorKind kind;
  @override
  String toString() => 'SyncException($kind): $message';
}

/// Неверный/просроченный токен или нет прав на репозиторий (401/403).
class SyncAuthException extends SyncException {
  SyncAuthException(String message) : super(message, SyncErrorKind.auth);
}

/// Файл изменился на сервере между чтением и записью (устаревший sha) —
/// нужно перечитать и повторить слияние.
class SyncConflictException extends SyncException {
  SyncConflictException() : super('remote changed, retry', SyncErrorKind.conflict);
}

/// Результат чтения удалённого файла состояния.
class RemoteFile {
  const RemoteFile(this.json, this.sha);

  /// Разобранный JSON состояния (null, если файла в репозитории ещё нет).
  final Map<String, dynamic>? json;

  /// `sha` файла в git (нужен для записи поверх). null, если файла нет.
  final String? sha;
}

/// Абстракция хранилища состояния синхронизации (чтобы движок не зависел от
/// конкретного транспорта и был тестируемым).
abstract class SyncStore {
  Future<RemoteFile> pull();
  Future<void> push(Map<String, dynamic> stateJson, String? sha);
}

/// Хранилище на приватном репозитории GitHub: единый файл `state.json` через
/// REST Contents API. Работает одинаково на десктопе и телефоне.
class GitHubStore implements SyncStore {
  GitHubStore({
    required this.owner,
    required this.repo,
    required this.token,
    this.branch = 'main',
    this.path = 'state.json',
  });

  final String owner;
  final String repo;
  final String token;
  final String branch;
  final String path;

  Uri get _contents =>
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');

  @override
  Future<RemoteFile> pull() async {
    final client = HttpClient();
    try {
      final req = await client
          .getUrl(_contents.replace(queryParameters: {'ref': branch}));
      _auth(req);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode == 404) return const RemoteFile(null, null);
      _checkAuth(resp.statusCode, body);
      if (resp.statusCode != 200) {
        throw SyncException('read ${resp.statusCode}', SyncErrorKind.read);
      }
      final m = jsonDecode(body) as Map<String, dynamic>;
      final b64 = (m['content'] as String? ?? '').replaceAll('\n', '');
      final sha = m['sha'] as String?;
      final decoded = b64.isEmpty ? '{}' : utf8.decode(base64.decode(b64));
      return RemoteFile(jsonDecode(decoded) as Map<String, dynamic>, sha);
    } on SocketException {
      throw SyncException('network', SyncErrorKind.network);
    } finally {
      client.close();
    }
  }

  @override
  Future<void> push(Map<String, dynamic> stateJson, String? sha) async {
    final client = HttpClient();
    try {
      final req = await client.putUrl(_contents);
      _auth(req);
      req.headers.contentType = ContentType.json;
      final content = base64.encode(
          utf8.encode(const JsonEncoder.withIndent('  ').convert(stateJson)));
      final payload = <String, dynamic>{
        'message': 'DayLane sync ${DateTime.now().toIso8601String()}',
        'content': content,
        'branch': branch,
        'sha': ?sha,
      };
      req.add(utf8.encode(jsonEncode(payload)));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      // 409 — устаревший sha; 422 — как правило тоже рассинхрон sha. Повторяем.
      if (resp.statusCode == 409 || resp.statusCode == 422) {
        throw SyncConflictException();
      }
      _checkAuth(resp.statusCode, body);
      if (resp.statusCode != 200 && resp.statusCode != 201) {
        throw SyncException('write ${resp.statusCode}', SyncErrorKind.write);
      }
    } on SocketException {
      throw SyncException('network', SyncErrorKind.network);
    } finally {
      client.close();
    }
  }

  void _auth(HttpClientRequest req) {
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    req.headers.set('X-GitHub-Api-Version', '2022-11-28');
    req.headers.set(HttpHeaders.userAgentHeader, 'DayLane');
  }

  void _checkAuth(int status, String body) {
    if (status == 401 || status == 403) {
      throw SyncAuthException('Нет доступа — проверьте токен и права (Contents)');
    }
  }
}
