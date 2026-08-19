import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'sync_transport.dart';

/// Настройки синхронизации: репозиторий и токен. Токен хранится в защищённом
/// хранилище ОС (Windows Credential Manager / Android keystore), не в открытом
/// виде и не в общей БД.
class SyncConfig {
  const SyncConfig({
    this.owner = '',
    this.repo = '',
    this.branch = 'main',
    this.token = '',
  });

  final String owner;
  final String repo;
  final String branch;
  final String token;

  /// Введённый пользователем «owner/repo» из одного поля.
  String get repoPath => (owner.isEmpty && repo.isEmpty) ? '' : '$owner/$repo';

  bool get isComplete =>
      owner.isNotEmpty && repo.isNotEmpty && token.isNotEmpty;

  /// Готовый транспорт, если настроек достаточно.
  GitHubStore? store() => isComplete
      ? GitHubStore(owner: owner, repo: repo, token: token, branch: branch)
      : null;

  SyncConfig copyWith({
    String? owner,
    String? repo,
    String? branch,
    String? token,
  }) =>
      SyncConfig(
        owner: owner ?? this.owner,
        repo: repo ?? this.repo,
        branch: branch ?? this.branch,
        token: token ?? this.token,
      );

  /// Разбирает «owner/repo» (или полный URL) в owner+repo.
  static (String, String) parseRepoPath(String input) {
    var s = input.trim();
    s = s.replaceFirst(RegExp(r'^https?://github\.com/'), '');
    s = s.replaceFirst(RegExp(r'\.git$'), '');
    final parts = s.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return (parts[0], parts[1]);
    return ('', '');
  }
}

/// Чтение/запись настроек синхронизации в защищённое хранилище.
class SyncConfigStore {
  const SyncConfigStore();

  static const _s = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kOwner = 'sync_owner';
  static const _kRepo = 'sync_repo';
  static const _kBranch = 'sync_branch';
  static const _kToken = 'sync_token';

  Future<SyncConfig> load() async {
    final all = await _s.readAll();
    return SyncConfig(
      owner: all[_kOwner] ?? '',
      repo: all[_kRepo] ?? '',
      branch: (all[_kBranch] ?? '').isEmpty ? 'main' : all[_kBranch]!,
      token: all[_kToken] ?? '',
    );
  }

  Future<void> save(SyncConfig c) async {
    await _s.write(key: _kOwner, value: c.owner);
    await _s.write(key: _kRepo, value: c.repo);
    await _s.write(key: _kBranch, value: c.branch);
    await _s.write(key: _kToken, value: c.token);
  }

  Future<void> clear() async {
    for (final k in [_kOwner, _kRepo, _kBranch, _kToken]) {
      await _s.delete(key: k);
    }
  }
}
